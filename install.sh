#!/usr/bin/env bash
#
# install.sh — install the five managed SDI skills without overwriting local
# edits. One invocation may update one or more skill directories atomically.
#
#   ./install.sh                         use SKILLS_DIR or the default directory
#   ./install.sh /path/one /path/two     update every listed directory
#   ./install.sh --check [dest ...]      compare only
#   ./install.sh --restore BACKUP_DIR    restore a backup printed by an install
#
# The committed installed.sha256 records the last installed content. Every
# destination is checked against it before anything is copied. A successful
# update leaves a temporary backup available for the caller's post-install
# smoke; run the printed restore command on smoke failure, or remove the backup
# after PASS. Only the five managed skill trees are ever copied or removed.

set -Eeuo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST="$REPO_ROOT/installed.sha256"
SKILLS=(convert-to-sdi mvp-architect sdi-mode sdi-next-plan sdi-review)

usage() {
  sed -n '2,15p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

hash_tree() {
  local root="$1" skill
  for skill in "${SKILLS[@]}"; do
    [ -d "$root/$skill" ] || continue
    ( cd -- "$root" && find "$skill" -type f -print ) || return 1
  done | LC_ALL=C sort | while IFS= read -r rel; do
    ( cd -- "$root" && sha256sum -- "$rel" )
  done
}

restore_backup() {
  local backup="$1" index=0 destination skill
  [ -d "$backup" ] || { echo "install.sh: backup not found: $backup" >&2; return 2; }
  [ -f "$backup/destinations" ] || { echo "install.sh: invalid backup: missing destinations" >&2; return 2; }
  [ -f "$backup/installed.sha256" ] || { echo "install.sh: invalid backup: missing manifest" >&2; return 2; }

  while IFS= read -r destination; do
    [ -n "$destination" ] || { echo "install.sh: invalid empty destination in backup" >&2; return 2; }
    for skill in "${SKILLS[@]}"; do
      rm -rf -- "$destination/$skill"
      if [ -e "$backup/dest-$index/$skill" ]; then
        mkdir -p -- "$destination"
        cp -a -- "$backup/dest-$index/$skill" "$destination/$skill"
      fi
    done
    index=$((index + 1))
  done < "$backup/destinations"
  cp -a -- "$backup/installed.sha256" "$MANIFEST"
  echo "install.sh: restored all managed skill trees and the manifest from $backup"
}

CHECK_ONLY=0
if [ "${1:-}" = "--restore" ]; then
  [ "$#" -eq 2 ] || { echo "install.sh: --restore requires exactly one backup directory" >&2; exit 2; }
  restore_backup "$2"
  exit 0
fi
if [ "${1:-}" = "--check" ]; then
  CHECK_ONLY=1
  shift
elif [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
elif [ "${1:-}" = "--" ]; then
  shift
elif [[ "${1:-}" == -* ]]; then
  echo "install.sh: unknown argument '$1'" >&2
  exit 2
fi

if [ "$#" -eq 0 ]; then
  DESTINATIONS=("${SKILLS_DIR:-$HOME/.claude/skills}")
else
  DESTINATIONS=("$@")
fi

for destination in "${DESTINATIONS[@]}"; do
  [ -n "$destination" ] || { echo "install.sh: destination may not be empty" >&2; exit 2; }
  case "$destination" in
    *$'\n'*) echo "install.sh: destination may not contain a newline" >&2; exit 2 ;;
  esac
done
NORMALIZED_DESTINATIONS=()
for destination in "${DESTINATIONS[@]}"; do
  NORMALIZED_DESTINATIONS+=("$(realpath -m -- "$destination")")
done
DESTINATIONS=("${NORMALIZED_DESTINATIONS[@]}")

if [ ! -f "$MANIFEST" ]; then
  echo "install.sh: no manifest at $MANIFEST — stopping before copy." >&2
  exit 2
fi

declare -A MANIFEST_H REPO_H INSTALLED_H
while read -r sum rel; do
  [ -n "${rel:-}" ] && MANIFEST_H["$rel"]="$sum"
done < "$MANIFEST"
while read -r sum rel; do
  [ -n "${rel:-}" ] && REPO_H["$rel"]="$sum"
done < <(hash_tree "$REPO_ROOT")

TOTAL_INSTALL=0
TOTAL_COPY=0
TOTAL_DELETE=0
TOTAL_STALE=0
MISSING_ANY=0

preflight_destination() {
  local destination="$1" rel
  local -a drift=() to_install=() to_copy=() to_delete=() stale=()
  INSTALLED_H=()
  while read -r sum rel; do
    [ -n "${rel:-}" ] && INSTALLED_H["$rel"]="$sum"
  done < <(hash_tree "$destination")

  for rel in "${!MANIFEST_H[@]}"; do
    if [ -n "${INSTALLED_H[$rel]+set}" ] && [ "${INSTALLED_H[$rel]}" != "${MANIFEST_H[$rel]}" ]; then
      drift+=("edited locally    $rel")
    fi
  done
  for rel in "${!INSTALLED_H[@]}"; do
    [ -n "${MANIFEST_H[$rel]+set}" ] || drift+=("added locally     $rel")
  done
  if [ "${#drift[@]}" -gt 0 ]; then
    echo "install.sh: LOCAL DRIFT at $destination — stopping all destinations."
    printf '  %s\n' "${drift[@]}" | LC_ALL=C sort
    return 1
  fi

  for rel in "${!REPO_H[@]}"; do
    if [ -z "${INSTALLED_H[$rel]+set}" ]; then
      to_install+=("$rel")
    elif [ "${INSTALLED_H[$rel]}" != "${REPO_H[$rel]}" ]; then
      to_copy+=("$rel")
    fi
  done
  for rel in "${!INSTALLED_H[@]}"; do
    [ -n "${REPO_H[$rel]+set}" ] || to_delete+=("$rel")
  done
  for rel in "${!MANIFEST_H[@]}"; do
    if [ -z "${INSTALLED_H[$rel]+set}" ] && [ -z "${REPO_H[$rel]+set}" ]; then
      stale+=("$rel")
    fi
  done

  echo "destination: $destination"
  echo "  missing ${#to_install[@]}, copy ${#to_copy[@]}, delete ${#to_delete[@]}, stale manifest ${#stale[@]}"
  TOTAL_INSTALL=$((TOTAL_INSTALL + ${#to_install[@]}))
  TOTAL_COPY=$((TOTAL_COPY + ${#to_copy[@]}))
  TOTAL_DELETE=$((TOTAL_DELETE + ${#to_delete[@]}))
  TOTAL_STALE=$((TOTAL_STALE + ${#stale[@]}))
  [ "${#to_install[@]}" -eq 0 ] || MISSING_ANY=1
}

# Preflight every destination before creating a backup or mutating a target.
PREFLIGHT_FAILED=0
for destination in "${DESTINATIONS[@]}"; do
  if ! preflight_destination "$destination"; then
    PREFLIGHT_FAILED=1
  fi
done
if [ "$PREFLIGHT_FAILED" -eq 1 ]; then
  echo "install.sh: preflight failed; nothing was copied and the manifest is unchanged."
  exit 1
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  if [ "$MISSING_ANY" -eq 1 ]; then
    echo "--check: no local drift, but at least one managed file is not installed."
    exit 1
  fi
  if [ "$TOTAL_COPY" -gt 0 ] || [ "$TOTAL_DELETE" -gt 0 ] || [ "$TOTAL_STALE" -gt 0 ]; then
    echo "--check: no local drift. Run install.sh without --check to apply."
  else
    echo "install.sh: up to date in all ${#DESTINATIONS[@]} destination(s)."
  fi
  exit 0
fi

if [ "$TOTAL_INSTALL" -eq 0 ] && [ "$TOTAL_COPY" -eq 0 ] \
   && [ "$TOTAL_DELETE" -eq 0 ] && [ "$TOTAL_STALE" -eq 0 ]; then
  echo "install.sh: up to date in all ${#DESTINATIONS[@]} destination(s)."
  exit 0
fi

BACKUP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/sdi-install-backup.XXXXXX")"
cp -a -- "$MANIFEST" "$BACKUP_DIR/installed.sha256"
printf '%s\n' "${DESTINATIONS[@]}" > "$BACKUP_DIR/destinations"
index=0
for destination in "${DESTINATIONS[@]}"; do
  mkdir -p -- "$BACKUP_DIR/dest-$index"
  for skill in "${SKILLS[@]}"; do
    if [ -e "$destination/$skill" ]; then
      cp -a -- "$destination/$skill" "$BACKUP_DIR/dest-$index/$skill"
    fi
  done
  index=$((index + 1))
done

MUTATING=1
rollback_on_error() {
  local status=$?
  trap - ERR
  set +e
  if [ "${MUTATING:-0}" -eq 1 ]; then
    echo "install.sh: apply failed; restoring every destination and the manifest." >&2
    restore_backup "$BACKUP_DIR" >&2
  fi
  exit "$status"
}
trap rollback_on_error ERR

apply_destination() {
  local destination="$1" rel
  INSTALLED_H=()
  while read -r sum rel; do
    [ -n "${rel:-}" ] && INSTALLED_H["$rel"]="$sum"
  done < <(hash_tree "$destination")

  for rel in "${!REPO_H[@]}"; do
    if [ -z "${INSTALLED_H[$rel]+set}" ] || [ "${INSTALLED_H[$rel]}" != "${REPO_H[$rel]}" ]; then
      mkdir -p -- "$destination/$(dirname -- "$rel")"
      cp -- "$REPO_ROOT/$rel" "$destination/$rel"
    fi
  done
  for rel in "${!INSTALLED_H[@]}"; do
    [ -n "${REPO_H[$rel]+set}" ] || rm -f -- "$destination/$rel"
  done
}

for destination in "${DESTINATIONS[@]}"; do
  apply_destination "$destination"
done

manifest_tmp="$BACKUP_DIR/installed.sha256.new"
hash_tree "$REPO_ROOT" > "$manifest_tmp"
cp -- "$manifest_tmp" "$MANIFEST"
MUTATING=0
trap - ERR

echo "install.sh: installed $TOTAL_INSTALL, copied $TOTAL_COPY, deleted $TOTAL_DELETE across ${#DESTINATIONS[@]} destination(s); manifest rewritten once."
echo "BACKUP_DIR=$BACKUP_DIR"
printf 'Restore after a failed smoke: %q --restore %q\n' "$REPO_ROOT/install.sh" "$BACKUP_DIR"
echo "After smoke PASS, remove the backup directory: $BACKUP_DIR"
