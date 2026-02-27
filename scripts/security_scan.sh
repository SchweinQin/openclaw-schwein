#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

SECRET_PATTERN="ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|EC|OPENSSH|DSA)? ?PRIVATE KEY|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z\-_]{35}|token\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{12,}|password\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{8,}"

run_scan_allow_no_matches() {
  local scan_name="$1"
  shift

  local status
  set +e
  "$@"
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    return 0
  fi

  if [[ "$status" -eq 1 ]]; then
    echo "$scan_name: no matches found"
    return 0
  fi

  echo "$scan_name: scan failed with exit code $status" >&2
  return "$status"
}

echo "[1/4] Repo snapshot"
git branch -vv || true

echo
echo "[2/4] Working tree secret pattern scan"
run_scan_allow_no_matches "Working tree scan" \
  rg -n --hidden --glob '!.git' "$SECRET_PATTERN" .

echo
echo "[3/4] Git history secret pattern scan"
while read -r commit; do
  run_scan_allow_no_matches "History scan for commit $commit" \
    git grep -nE "$SECRET_PATTERN" "$commit" -- .
done < <(git rev-list --all)

echo
echo "[4/4] Git object integrity"
git fsck --strict

echo
echo "Done. If any lines were printed in steps [2/4] or [3/4], inspect and rotate leaked secrets immediately."
