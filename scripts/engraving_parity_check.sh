#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 scripts/build_openapi_typed.py
python3 scripts/check_typed_parity.py
python3 scripts/check_trace.py
python3 scripts/check_property_parity.py
echo "Engraving parity checks passed."

