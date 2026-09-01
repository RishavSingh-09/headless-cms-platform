#!/usr/bin/env bash
# log_rotate.sh — Rotate and gzip application logs on an EC2 host or CI runner.
#
# Usage: ./log_rotate.sh /var/log/cms 14
#   Rotates *.log files in the given dir, keeps 14 days of compressed history.
set -euo pipefail

LOG_DIR=${1:-/var/log/cms}
RETENTION_DAYS=${2:-14}
TS=$(date +%Y%m%d-%H%M%S)

if [[ ! -d "$LOG_DIR" ]]; then
  echo "log dir $LOG_DIR does not exist" >&2
  exit 1
fi

echo "[*] Rotating logs in $LOG_DIR (retention: $RETENTION_DAYS days)"

shopt -s nullglob
for f in "$LOG_DIR"/*.log; do
  base=$(basename "$f" .log)
  rotated="$LOG_DIR/${base}-${TS}.log"
  mv "$f" "$rotated"
  gzip "$rotated"
  : > "$f"
  echo "  rotated $f -> ${rotated}.gz"
done

find "$LOG_DIR" -name "*.log.gz" -mtime "+${RETENTION_DAYS}" -print -delete
echo "[+] Done."
