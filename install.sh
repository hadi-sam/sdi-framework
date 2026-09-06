#!/usr/bin/env bash
#
# install.sh — install the five SDI skills from this repo into the agent's
# skills directory, using installed.sha256 as the record of what was installed
# last time.
#
#   ./install.sh          install what is missing, copy what changed, then
#                         rewrite the manifest
#   ./install.sh --check  compare only; exit 1 if the installed copy has
#                         drifted from the manifest, or if files are missing
#
# Three states are compared per file: the manifest (what was installed last
# time), the installed copy, and the repo. The manifest is what makes the
# difference between "the repo changed" and "somebody edited the installed
# copy" legible — without it the two are indistinguishable and an install
# silently destroys local edits.
#
#   absent from the installed copy        -> install (an empty skills
#                                           directory is the first install)
#   installed == manifest, repo differs   -> copy (normal update)
#   installed == manifest, absent in repo -> delete from the installed copy
#   installed != manifest                 -> LOCAL DRIFT: stop, list, copy nothing
#   installed, absent from the manifest   -> LOCAL DRIFT: same
#   no manifest                           -> stop, always
#
# Drift is only what an install would destroy: a file edited in the installed
# copy, or one added there. A file that is merely absent has no local edit to
# lose, so installing it overwrites nothing and the protection is unchanged.
#
# Requires bash 4+ and coreutils (sha256sum, find, sort, cp, rm, mkdir).

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${SKILLS_DIR:-$HOME/.claude/skills}"
MANIFEST="$REPO_ROOT/installed.sha256"
SKILLS=(convert-to-sdi mvp-architect sdi-mode sdi-next-plan sdi-review)

CHECK_ONLY=0
case "${1:-}" in
  --check) CHECK_ONLY=1 ;;
  -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) echo "install.sh: unknown argument '$1' (expected --check or nothing)" >&2; exit 2 ;;
esac

# --- 1. the three states -----------------------------------------------------

# Hash every file of the five skills under $1, printing "<sha256>  <relpath>".
# Skill directories absent from $1 contribute nothing, so an empty skills
# directory hashes to nothing and every file counts as missing; anything in the
# directory that is not one of the five skills is never listed, so a user's
# other skills are neither read nor touched.
# The sort is LC_ALL=C so that the manifest's order does not depend on the
# locale of whoever runs the script: a collation difference alone would
# otherwise rewrite all 108 lines without changing a single hash.
hash_tree() {
  local root="$1" skill
  for skill in "${SKILLS[@]}"; do
    [ -d "$root/$skill" ] || continue
    ( cd -- "$root" && find "$skill" -type f -print ) || return 1
  done | LC_ALL=C sort | while IFS= read -r rel; do
    ( cd -- "$root" && sha256sum -- "$rel" )
  done
}

declare -A MANIFEST_H INSTALLED_H REPO_H

if [ ! -f "$MANIFEST" ]; then
  cat >&2 <<MSG
install.sh: no manifest at $MANIFEST — stopping.

Without it there is no way to tell a stale installed file from a local edit,
so this script refuses to copy. Generate the first manifest from a copy you
trust, then commit it:

  ( cd "$SKILLS_DIR" && for s in ${SKILLS[*]}; do find "\$s" -type f; done \\
      | LC_ALL=C sort | xargs sha256sum ) > installed.sha256
MSG
  exit 2
fi

while read -r sum rel; do
  [ -n "${rel:-}" ] || continue
  MANIFEST_H["$rel"]="$sum"
done < "$MANIFEST"

while read -r sum rel; do
  [ -n "${rel:-}" ] || continue
  INSTALLED_H["$rel"]="$sum"
done < <(hash_tree "$SKILLS_DIR")

while read -r sum rel; do
  [ -n "${rel:-}" ] || continue
  REPO_H["$rel"]="$sum"
done < <(hash_tree "$REPO_ROOT")

# --- 2. local drift: the installed copy against the manifest ------------------
# Drift is what an install would destroy, and only that: a file whose installed
# content no longer matches the manifest, or one present in the installed copy
# that the manifest never recorded. A file the manifest lists and the installed
# copy does not have is *not* drift — there is no local edit to lose, so it is
# an install (section 3). That is what makes the first install work: an empty
# skills directory is every file missing and nothing edited.

drift=()
for rel in "${!MANIFEST_H[@]}"; do
  if [ -n "${INSTALLED_H[$rel]+set}" ] && [ "${INSTALLED_H[$rel]}" != "${MANIFEST_H[$rel]}" ]; then
    drift+=("edited locally    $rel")
  fi
done
for rel in "${!INSTALLED_H[@]}"; do
  if [ -z "${MANIFEST_H[$rel]+set}" ]; then
    drift+=("added locally     $rel")
  fi
done

if [ ${#drift[@]} -gt 0 ]; then
  echo "install.sh: LOCAL DRIFT — the installed copy at $SKILLS_DIR does not match the manifest."
  echo "Nothing was copied and nothing was deleted. ${#drift[@]} file(s):"
  printf '%s\n' "${drift[@]}" | LC_ALL=C sort
  echo
  echo "Carry the change back into the repo and commit it, or restore the installed"
  echo "copy from the repo, then run this again."
  exit 1
fi

# --- 3. what an install would do ---------------------------------------------
# Past this point every file the installed copy has matches the manifest, so the
# installed copy can be compared with the repo directly. Three disjoint sets:
# never installed, installed but out of date, installed but gone from the repo.

to_install=()
to_copy=()
to_delete=()
stale=()
for rel in "${!REPO_H[@]}"; do
  if [ -z "${INSTALLED_H[$rel]+set}" ]; then
    to_install+=("$rel")
  elif [ "${INSTALLED_H[$rel]}" != "${REPO_H[$rel]}" ]; then
    to_copy+=("$rel")
  fi
done
for rel in "${!INSTALLED_H[@]}"; do
  if [ -z "${REPO_H[$rel]+set}" ]; then
    to_delete+=("$rel")
  fi
done
# A manifest line for a file that is in neither tree records an install that no
# longer exists. Nothing to copy and nothing to delete, but the manifest should
# stop carrying it, so it counts as work to do.
for rel in "${!MANIFEST_H[@]}"; do
  if [ -z "${INSTALLED_H[$rel]+set}" ] && [ -z "${REPO_H[$rel]+set}" ]; then
    stale+=("$rel")
  fi
done

if [ ${#to_install[@]} -eq 0 ] && [ ${#to_copy[@]} -eq 0 ] \
   && [ ${#to_delete[@]} -eq 0 ] && [ ${#stale[@]} -eq 0 ]; then
  echo "install.sh: up to date — installed copy matches the manifest and the repo (${#INSTALLED_H[@]} files)."
  exit 0
fi

if [ ${#to_install[@]} -gt 0 ]; then
  echo "missing   (${#to_install[@]}):"
  printf '  %s\n' "${to_install[@]}" | LC_ALL=C sort
fi
if [ ${#to_copy[@]} -gt 0 ]; then
  echo "to copy   (${#to_copy[@]}):"
  printf '  %s\n' "${to_copy[@]}" | LC_ALL=C sort
fi
if [ ${#to_delete[@]} -gt 0 ]; then
  echo "to delete (${#to_delete[@]}):"
  printf '  %s\n' "${to_delete[@]}" | LC_ALL=C sort
fi
if [ ${#stale[@]} -gt 0 ]; then
  echo "stale manifest lines (${#stale[@]}), dropped on the next rewrite:"
  printf '  %s\n' "${stale[@]}" | LC_ALL=C sort
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo
  if [ ${#to_install[@]} -gt 0 ]; then
    echo "--check: no local drift, but ${#to_install[@]} file(s) listed above are not installed."
    echo "Run install.sh without --check to install them; nothing already installed is overwritten."
    exit 1
  fi
  echo "--check: no local drift. Run install.sh without --check to apply."
  exit 0
fi

# --- 4. apply, then rewrite the manifest -------------------------------------
# The ${a[@]+"${a[@]}"} form is what keeps an empty array from tripping `set -u`
# on bash 4.0-4.3, which the header still promises to support.

for rel in ${to_install[@]+"${to_install[@]}"} ${to_copy[@]+"${to_copy[@]}"}; do
  mkdir -p -- "$SKILLS_DIR/$(dirname -- "$rel")"
  cp -- "$REPO_ROOT/$rel" "$SKILLS_DIR/$rel"
done
for rel in ${to_delete[@]+"${to_delete[@]}"}; do
  rm -f -- "$SKILLS_DIR/$rel"
done

hash_tree "$SKILLS_DIR" > "$MANIFEST"

echo
echo "installed ${#to_install[@]}, copied ${#to_copy[@]}, deleted ${#to_delete[@]}; manifest rewritten with $(wc -l < "$MANIFEST") files."
