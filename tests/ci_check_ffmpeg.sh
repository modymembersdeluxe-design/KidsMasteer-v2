#!/usr/bin/env bash
set -euo pipefail

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "[FAIL] ffmpeg is not available on PATH"
  exit 1
fi

ffmpeg -version | head -n 1

echo "[PASS] ffmpeg check completed"
