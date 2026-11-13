#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
credentials_file="$(mktemp "${TMPDIR:-/tmp}/sketchlens-dart-defines.XXXXXX")"
trap 'rm -f "$credentials_file"' EXIT

python3 - "$(dirname "$PWD")/server/.env" "$credentials_file" <<'PY'
import json
import os
import sys
from pathlib import Path

env_path = Path(sys.argv[1])
defines_path = Path(sys.argv[2])
values = {}
if env_path.is_file():
    for line in env_path.read_text().splitlines():
        entry = line.strip()
        if not entry or entry.startswith("#") or "=" not in entry:
            continue
        key, value = entry.split("=", 1)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[key.strip()] = value

token = values.get("TELEGRAM_BOT_TOKEN", "")
chat_id = values.get("TELEGRAM_CHAT_ID", "")
if not token or not chat_id:
    raise SystemExit("Set TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID in server/.env first.")

os.chmod(defines_path, 0o600)
defines_path.write_text(
    json.dumps({"TELEGRAM_BOT_TOKEN": token, "TELEGRAM_CHAT_ID": chat_id})
)
PY

flutter build apk --release --dart-define-from-file="$credentials_file" "$@"
