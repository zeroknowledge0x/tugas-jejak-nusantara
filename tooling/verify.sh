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
echo "[1/6] luau-compile --only-parse (Luau syntax)"
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
echo "[2/6] selene check (lua51 std + Roblox globals)"
if ! "$BIN/selene" "$SRC" >"$ROOT/.selene_out" 2>&1; then
  echo "  SELENE ISSUES:"; cat "$ROOT/.selene_out"; fail=1
else
  echo "  OK"
fi

# 3) stylua format check
echo "[3/6] stylua --check"
if ! "$BIN/stylua" --check "$SRC" >"$ROOT/.stylua_out" 2>&1; then
  echo "  FORMAT ISSUES (run stylua to fix):"; cat "$ROOT/.stylua_out"; fail=1
else
  echo "  OK"
fi

# 4) rojo build (place compiles -> package structure valid)
echo "[4/6] rojo build (place file)"
mkdir -p "$ROOT/build"
if ! "$BIN/rojo" build --output "$ROOT/build/JejakNusantara.rbxlx" >"$ROOT/.rojo_out" 2>&1; then
  echo "  ROJO BUILD FAILED:"; cat "$ROOT/.rojo_out"; fail=1
else
  echo "  OK -> build/JejakNusantara.rbxlx"
fi

# 5) runtime smoke test (real execution of framework logic)
echo "[5/6] runtime smoke test (luau interpreter)"
if ! python3 "$ROOT/tooling/bundle_runtime.py" >/dev/null 2>&1; then
  echo "  BUNDLE GEN FAILED"; fail=1
elif ! "$BIN/luau" "$ROOT/tooling/bundle.luau" >"$ROOT/.smoke_out" 2>&1; then
  echo "  RUNTIME SMOKE FAILED:"; cat "$ROOT/.smoke_out"; fail=1
else
  echo "  OK ($(grep -c PASS "$ROOT/.smoke_out") checks passed)"
fi

# 6) studio readiness (entry Script/LocalScript classes + require path audit)
echo "[6/6] studio readiness (rbxlx classes + require graph)"
if ! python3 "$ROOT/tooling/studio_readiness.py" >"$ROOT/.studio_out" 2>&1; then
  echo "  STUDIO READINESS FAILED:"; cat "$ROOT/.studio_out"; fail=1
else
  echo "  OK"; sed -n 's/^  PASS: /    - /p' "$ROOT/.studio_out" | head -12
fi

if [ "$fail" -ne 0 ]; then
  echo "== VERIFY FAILED =="; exit 1
fi
echo "== VERIFY PASSED =="
