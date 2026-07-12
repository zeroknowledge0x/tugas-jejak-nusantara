#!/usr/bin/env bash
# Jejak Nusantara — headless verification gate.
# Runs after every commit. Fails loudly if any layer fails.
# Usage: bash tooling/verify.sh
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/tooling/bin"
SRC="$ROOT/src"
echo "== Jejak Nusantara verify =="
echo "ROOT=$ROOT"

fail=0

# 1) Luau syntax check (authoritative parser)
echo "[1/4] luau-compile --only-parse (Luau syntax)"
mapfile -t files < <(find "$SRC" -name '*.luau')
if [ "${#files[@]}" -eq 0 ]; then echo "  no .luau files yet (skipping)"; else
  for f in "${files[@]}"; do
    if ! "$BIN/luau-compile" --only-parse "$f" >/dev/null 2>"$ROOT/.luau_err"; then
      echo "  SYNTAX ERROR in $f"; cat "$ROOT/.luau_err"; fail=1
    fi
  done
  [ "$fail" -eq 0 ] && echo "  OK (${#files[@]} files parsed)"
fi

# 2) selene lint (undefined globals, anti-patterns)
echo "[2/4] selene check (lua51 std + Roblox globals)"
if ! "$BIN/selene" "$SRC" >"$ROOT/.selene_out" 2>&1; then
  echo "  SELENE ISSUES:"; cat "$ROOT/.selene_out"; fail=1
else
  echo "  OK"
fi

# 3) stylua format check
echo "[3/4] stylua --check"
if ! "$BIN/stylua" --check "$SRC" >"$ROOT/.stylua_out" 2>&1; then
  echo "  FORMAT ISSUES (run stylua to fix):"; cat "$ROOT/.stylua_out"; fail=1
else
  echo "  OK"
fi

# 4) rojo build (place compiles -> package structure valid)
echo "[4/4] rojo build (place file)"
if ! "$BIN/rojo" build --output "$ROOT/build/JejakNusantara.rbxlx" >"$ROOT/.rojo_out" 2>&1; then
  echo "  ROJO BUILD FAILED:"; cat "$ROOT/.rojo_out"; fail=1
else
  echo "  OK -> build/JejakNusantara.rbxlx"
fi

if [ "$fail" -ne 0 ]; then
  echo "== VERIFY FAILED =="; exit 1
fi
echo "== VERIFY PASSED =="
