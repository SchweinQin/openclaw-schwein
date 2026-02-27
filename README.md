# openclaw-schwein
openclaw workspace

## Next step: run security scan
Use the script below to check for plaintext tokens/secrets in both current files and git history:

```bash
bash scripts/security_scan.sh
```

What it does:
- scans working tree for common secret patterns
- scans all commits in git history for the same patterns
- runs `git fsck --strict` for git object integrity
