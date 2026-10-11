#!/bin/bash
# Start (or restart) the engine for this recipe and confirm the fast path engaged.
# Log: $PREFIX/serve.out
set -euo pipefail
PREFIX="${PREFIX:-$HOME/.local/opt/tensorfold-aeon}"
PORT="${PORT:-8080}"
NAME="${NAME:-qwen38-27b-aeon}"
MODEL="${MODEL:-choppedgarlic/Qwen3.8-27B-AEON-ULTIMATE-UNCENSORED-4bit-MLX}"

for p in $(lsof -t -nP -iTCP:"$PORT" -sTCP:LISTEN 2>/dev/null); do kill "$p"; done
while lsof -t -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; do sleep 1; done

# background the server itself (not a `cd && ... &` subshell, which holds the caller's pipe)
nohup "$PREFIX/venv/bin/tensorfold" serve "$MODEL" --name "$NAME" --host 127.0.0.1 --port "$PORT" \
  --no-update-check > "$PREFIX/serve.out" 2>&1 < /dev/null &
echo $! > "$PREFIX/serve.pid"
disown

until curl -s -m 2 "127.0.0.1:$PORT/v1/models" | grep -q "$NAME"; do
  kill -0 "$(cat "$PREFIX/serve.pid")" 2>/dev/null || { tail -20 "$PREFIX/serve.out" >&2; exit 1; }
  sleep 2
done
grep -q 'lane kernels on' "$PREFIX/serve.out" && echo "  ✓ lane kernels on (M5 tensor units)" \
  || echo "  ! lane kernels not on (non-M5 Mac: packed row decoder)"
grep -q 'drafter .*DFlash2' "$PREFIX/serve.out" && echo "  ✓ DFlash2 drafter loaded" \
  || echo "  ! DFlash2 drafter not loaded: run 'tensorfold pull z-lab/Qwen3.8-27B-DFlash2'"
grep -E 'weights kept resident' "$PREFIX/serve.out" | sed 's/\[tensorfold\]/  ✓/'
echo "  ✓ serving on :$PORT (pid $(cat "$PREFIX/serve.pid"))"
