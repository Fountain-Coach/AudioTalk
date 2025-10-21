#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
# Parity checks against Engraving (source of truth). Do not mutate Engraving in CI.
python3 scripts/check_parity.py
python3 scripts/check_typed_parity.py
python3 scripts/check_trace.py
python3 scripts/check_property_parity.py
echo "Engraving parity checks passed."
