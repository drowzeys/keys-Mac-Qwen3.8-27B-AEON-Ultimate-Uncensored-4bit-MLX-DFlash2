#!/usr/bin/env bash
# =============================================================================
# One-shot: Qwen3.8-27B AEON Ultimate Uncensored (4-bit MLX) on engine 0.6.0 + DFlash2
#
#   bash oneshot-setup.sh            # install engine, pull weights + drafter, serve on :8080
#   bash oneshot-setup.sh --verify   # check an existing install, no downloads
#
# Engine payload order: this git clone's ./payload -> GHCR carrier image -> git at the pinned commit.
# Installs into its own venv ($PREFIX, default ~/.local/opt/tensorfold-aeon). Touches nothing else.
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX="${PREFIX:-$HOME/.local/opt/tensorfold-aeon}"
PORT="${PORT:-8080}"
IMAGE="${IMAGE:-ghcr.io/drowzeys/keys-mac-qwen38-27b-aeon:0.6.0}"
TF_COMMIT="c4646171139ee8a3c38103eaa1699dad226ec12b"
MODEL="choppedgarlic/Qwen3.8-27B-AEON-ULTIMATE-UNCENSORED-4bit-MLX"
DRAFTER="z-lab/Qwen3.8-27B-DFlash2"
NAME="${NAME:-qwen38-27b-aeon}"
VERIFY_ONLY=0; [ "${1:-}" = "--verify" ] && VERIFY_ONLY=1

die() { echo "FATAL: $*" >&2; exit 1; }
ok()  { echo "  ✓ $*"; }
step(){ echo; echo "==> $*"; }

step "Preflight"
[ "$(uname -s)" = Darwin ] && [ "$(uname -m)" = arm64 ] || die "Apple silicon macOS only (CUDA: see the engine's RUNBOOK)"
CHIP=$(sysctl -n machdep.cpu.brand_string); RAM=$(( $(sysctl -n hw.memsize) / 1073741824 ))
ok "$CHIP, macOS $(sw_vers -productVersion), ${RAM} GB"
[ "$RAM" -ge 32 ] || die "needs 32 GB+ unified memory (18.3 GiB resident + context)"
case "$CHIP" in *M5*) ok "M5: lane kernels (tensor units) + draft trees";;
  *) echo "  ! $CHIP is not M5: the engine uses its packed row decoder; the numbers in README are M5 Ultra";; esac
command -v uv >/dev/null || die "uv required: brew install uv"
command -v python3.11 >/dev/null || die "python3.11 required: brew install python@3.11"

fetch_ghcr() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 || return 1
  echo "  payload from GHCR $IMAGE"
  docker pull -q "$IMAGE" >/dev/null || return 1
  docker run --rm -v "$HERE":/out "$IMAGE" cp -a /payload/. /out/payload/
}

step "Engine 0.6.0 @ ${TF_COMMIT:0:8} (own venv at $PREFIX)"
if [ ! -x "$PREFIX/venv/bin/tensorfold" ]; then
  [ $VERIFY_ONLY -eq 1 ] && die "engine not installed at $PREFIX"
  mkdir -p "$HERE/payload"
  ls "$HERE"/payload/tensorfold-*.whl >/dev/null 2>&1 || fetch_ghcr || echo "  no carrier payload; installing from git"
  uv venv -q -p "$(command -v python3.11)" "$PREFIX/venv"
  if ls "$HERE"/payload/tensorfold-*.whl >/dev/null 2>&1; then
    ( cd "$HERE/payload" && shasum -a 256 -c SHA256SUMS >/dev/null ) || die "carrier payload checksum mismatch"
    ok "carrier payload checksums verified"
    uv pip install -q -p "$PREFIX/venv/bin/python" -c "$HERE/requirements.lock" "$HERE"/payload/tensorfold-*.whl
  else
    uv pip install -q -p "$PREFIX/venv/bin/python" -c "$HERE/requirements.lock" \
      "tensorfold @ git+https://github.com/ashhart/TensorFold.git@$TF_COMMIT"
  fi
fi
"$PREFIX/venv/bin/python" - "$TF_COMMIT" <<'EOF' || die "installed engine is not the pinned commit"
import importlib.metadata as m, json, sys
d = m.distribution("tensorfold"); u = d.read_text("direct_url.json")
commit = json.loads(u).get("vcs_info", {}).get("commit_id") if u else None
ok = d.version == "0.6.0" and (commit in (None, sys.argv[1]))
print(f"  ✓ engine {d.version}" + (f" @ {commit[:8]}" if commit else " (wheel)")) if ok else None
raise SystemExit(0 if ok else 1)
EOF
"$PREFIX/venv/bin/python" -c "import mlx.core as mx; print('  ✓ mlx', mx.__version__)"

step "Weights + drafter"
if [ $VERIFY_ONLY -eq 0 ]; then
  "$PREFIX/venv/bin/tensorfold" pull "$MODEL" "$DRAFTER" 2>&1 | grep -v -E 'Fetching|it/s' | sed 's/^/  /'
fi
"$PREFIX/venv/bin/tensorfold" info "$MODEL" 2>/dev/null | grep -E 'family|quantization' | sed 's/^/  /'

step "Serve"
PREFIX="$PREFIX" PORT="$PORT" NAME="$NAME" MODEL="$MODEL" bash "$HERE/scripts/serve.sh"
echo
echo "DONE. $NAME on http://127.0.0.1:$PORT/v1 (engine 0.6.0, lane kernels + DFlash2)"
echo "Bench: python3 $HERE/bench/qwen_task_bench.py --url http://127.0.0.1:$PORT --model $NAME --out mine.json"
