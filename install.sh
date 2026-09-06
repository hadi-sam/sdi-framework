#!/usr/bin/env bash
#
# install.sh — install the five SDI skills from this repo into the agent's
# skills directory, using installed.sha256 as the record of what was installed
# last time.
#
#   ./install.sh          copy the repo over the installed copy, then rewrite
#                         the manifest
#   ./install.sh --check  compare only; exit 1 if the installed copy has drifted
#                         away from the manifest
#
# Three states are compared per file: the manifest (what was installed last
# time), the installed copy, and the repo. The manifest is what makes the
# difference between "the repo changed" and "somebody edited the installed
# copy" legible — without it the two are indistinguishable and an install
# silently destroys local edits.
#
#   installed == manifest, repo differs   -> copy (normal update)
#   installed == manifest, absent in repo -> delete from the installed copy
#   installed != manifest                 -> LOCAL DRIFT: stop, list, copy nothing
#   no manifest                           -> stop, always
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
  -h|--help) sed -n '2,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  "") ;;
  *) echo "install.sh: unknown argument '$1' (expected --check or nothing)" >&2; exit 2 ;;
esac

# --- 1. the three states -----------------------------------------------------

# Hash every file of the five skills under $1, printing "<sha256>  <relpath>".
# Skill directories absent from $1 contribute nothing; anything in the
# directory that is not one of the five skills is never listed, so a user's
# other skills are neither read nor touched.
# The sort is the invoking locale's, not LC_ALL=C: that is the order the
# manifest committed at CP1 already has, so a rewrite here only changes the
# lines whose hash changed.
hash_tree() {
  local root="$1" skill
  for skill in "${SKILLS[@]}"; do
    [ -d "$root/$skill" ] || continue
    ( cd -- "$root" && find "$skill" -type f -print ) || return 1
  done | sort | while IFS= read -r rel; do
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

  ( cd "$SKILLS_DIR" && for s in ${SKILLS[*]}; do find "\$s" -type f; done | sort \\
      | xargs sha256sum ) > installed.sha256
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

drift=()
for rel in "${!MANIFEST_H[@]}"; do
  if [ -z "${INSTALLED_H[$rel]+set}" ]; then
    drift+=("deleted locally   $rel")
  elif [ "${INSTALLED_H[$rel]}" != "${MANIFEST_H[$rel]}" ]; then
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
  printf '%s\n' "${drift[@]}" | sort
  echo
  echo "Carry the change back into the repo and commit it, or restore the installed"
  echo "copy from the repo, then run this again."
  exit 1
fi

# --- 3. what an install would do ---------------------------------------------
# Past this point installed == manifest for every file, so the manifest can
# stand in for the installed copy.

to_copy=()
to_delete=()
for rel in "${!REPO_H[@]}"; do
  if [ -z "${MANIFEST_H[$rel]+set}" ] || [ "${MANIFEST_H[$rel]}" != "${REPO_H[$rel]}" ]; then
    to_copy+=("$rel")
  fi
done
for rel in "${!MANIFEST_H[@]}"; do
  if [ -z "${REPO_H[$rel]+set}" ]; then
    to_delete+=("$rel")
  fi
done

if [ ${#to_copy[@]} -eq 0 ] && [ ${#to_delete[@]} -eq 0 ]; then
  echo "install.sh: up to date — installed copy matches the manifest and the repo (${#MANIFEST_H[@]} files)."
  exit 0
fi

if [ ${#to_copy[@]} -gt 0 ]; then
  echo "to copy   (${#to_copy[@]}):"
  printf '  %s\n' "${to_copy[@]}" | sort
fi
if [ ${#to_delete[@]} -gt 0 ]; then
  echo "to delete (${#to_delete[@]}):"
  printf '  %s\n' "${to_delete[@]}" | sort
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo
  echo "--check: no local drift. Run install.sh without --check to apply."
  exit 0
fi

# --- 4. apply, then rewrite the manifest -------------------------------------

for rel in "${to_copy[@]}"; do
  mkdir -p -- "$SKILLS_DIR/$(dirname -- "$rel")"
  cp -- "$REPO_ROOT/$rel" "$SKILLS_DIR/$rel"
done
for rel in "${to_delete[@]}"; do
  rm -f -- "$SKILLS_DIR/$rel"
done

hash_tree "$SKILLS_DIR" > "$MANIFEST"

echo
echo "copied ${#to_copy[@]}, deleted ${#to_delete[@]}; manifest rewritten with $(wc -l < "$MANIFEST") files."
