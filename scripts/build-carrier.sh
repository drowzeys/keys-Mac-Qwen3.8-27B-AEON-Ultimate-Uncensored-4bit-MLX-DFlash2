#!/bin/bash
# Build and push the GHCR carrier image (engine wheel at the pinned commit + dependency lock).
#   bash scripts/build-carrier.sh           # build only
#   PUSH=1 bash scripts/build-carrier.sh    # build + push (needs `docker login ghcr.io` with write:packages)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${IMAGE:-ghcr.io/drowzeys/keys-mac-tensorfold-qwen38-27b-aeon}"
TAG="${TAG:-0.6.0}"
TF_COMMIT="c4646171139ee8a3c38103eaa1699dad226ec12b"
cd "$HERE"
rm -rf payload && mkdir -p payload
python3.11 -m pip wheel --no-deps -q -w payload "tensorfold @ git+https://github.com/ashhart/TensorFold.git@$TF_COMMIT"
cp requirements.lock payload/
( cd payload && shasum -a 256 tensorfold-*.whl requirements.lock > SHA256SUMS )
cat payload/SHA256SUMS
docker build -f Dockerfile.ghcr -t "$IMAGE:$TAG" -t "$IMAGE:latest" .
if [ "${PUSH:-0}" = 1 ]; then
  docker push "$IMAGE:$TAG"
  docker push "$IMAGE:latest"
  docker buildx imagetools inspect "$IMAGE:$TAG" | grep -E '^Digest' || true
fi
