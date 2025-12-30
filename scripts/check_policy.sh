#!/usr/bin/env bash

set -euo pipefail

FAILED=0

# Disallow direct terraform entries in tools.txt and profiles
for f in tools.txt profiles/*.txt; do
  if grep -E "(^|\s)terraform(\s|$)" "$f" >/dev/null 2>&1; then
    echo "[POLICY-FAIL] Direct terraform entry found in $f; use tfswitch instead." >&2
    FAILED=1
  fi
done

if [ $FAILED -ne 0 ]; then
  exit 2
fi
echo "[POLICY-OK] No direct terraform entries detected."
