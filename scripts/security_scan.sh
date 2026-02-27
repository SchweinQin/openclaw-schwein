#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

echo "[1/4] Repo snapshot"
git remote -v || true
git branch -vv || true

echo
echo "[2/4] Working tree secret pattern scan"
rg -n --hidden --glob '!.git' \
  "(ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|EC|OPENSSH|DSA)? ?PRIVATE KEY|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z\-_]{35}|token\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{12,}|password\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{8,})" \
  . || true

echo
echo "[3/4] Git history secret pattern scan"
while read -r commit; do
  git grep -nE \
    "ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|BEGIN (RSA|EC|OPENSSH|DSA)? ?PRIVATE KEY|xox[baprs]-[A-Za-z0-9-]{10,}|AIza[0-9A-Za-z\-_]{35}|token\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{12,}|password\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{8,}" \
    "$commit" -- . || true
done < <(git rev-list --all)

echo
echo "[4/4] Git object integrity"
git fsck --strict

echo
echo "Done. If any lines were printed in steps [2/4] or [3/4], inspect and rotate leaked secrets immediately."
