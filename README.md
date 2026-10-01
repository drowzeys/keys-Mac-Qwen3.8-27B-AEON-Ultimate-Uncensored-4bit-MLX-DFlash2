# keys-Mac-TensorFold-0.6.0-Qwen3.8-27B-AEON-Ultimate-Uncensored-4bit-MLX-DFlash2

**1.0** · Mac Studio M5 Ultra 256 GB · [TensorFold](https://github.com/ashhart/TensorFold) **0.6.0** ·
**Qwen3.8-27B AEON Ultimate Uncensored** (AEON-7) as **4-bit MLX** (choppedgarlic) · **DFlash2** speculative
decoding (z-lab) · M5 tensor-unit lane kernels

**191 tok/s single-stream decode, 97 ms TTFT, 1.4k tok/s prefill** for an uncensored 27B on one Mac, with
exact speculative decoding: every drafted token equals what the model would produce serially.
One-shot install from a GHCR prebuilt carrier.

This model has had safety refusals removed. Read [RESPONSIBLE_USE.md](RESPONSIBLE_USE.md) first.

**All credit to the authors:** AEON-7 / SpaceTimeViking (the model), choppedgarlic (the 4-bit MLX
conversion), Ash Hart (TensorFold) and z-lab (DFlash2). See [CREDITS.md](CREDITS.md).

## Headline (measured 2026-09-30, Mac Studio M5 Ultra 256 GB)

**Single stream** = one request at a time. **4 concurrent** = four requests in flight together;
"total" is their combined throughput.

| llmprobe 0.6.13 (thinking on, 192-token decode) | Single stream |
|---|---:|
| **Decode** | **191.1 tok/s** (163.8–191.3) |
| **TTFT** (short prompt) | **97 ms** |
| **Prefill** (10,406-token prompt) | **1,386 tok/s** |
| Speculative decode | 4.38× (predictable 461 tok/s · novel 105 tok/s) |
| Prefix cache | 25.5× (1.1 s cold → 42 ms warm) |
| Sustained | 191.1 → 185.7 tok/s over 99 min (−2.8%) |

| | 4 concurrent, short prompts |
|---|---:|
| Total throughput | **278.7 tok/s** (vs 129.7 tok/s for one alone) |
| Slowest TTFT | 321 ms |

### By task (thinking off, temp 0, decode measured after first token)

| Task | **Single stream** decode | TTFT | **4 concurrent** total | 4 concurrent, per stream |
|---|---:|---:|---:|---:|
| structural (512-tok JSON) | **228.0 tok/s** | 118 ms | **399.2 tok/s** | 111.5 tok/s |
| list (190 tok) | **188.4** | 69 ms | **375.1** | 109.0 |
| essay (320-tok prose) | **102.8** | 75 ms | **254.6** | 69.1 |
| reading (summary of a 1.3k-token passage) | **114.3** | 554 ms | **137.7** | 54.7 |
| count (110 tok) | **378.7** | 75 ms | **461.1** | 156.1 |

Recipe verification run (fresh install from `oneshot-setup.sh`): structural 205.7, list 181.8, essay 102.1,
reading 111.9, count 373.9 tok/s single stream; within 10% of the table.

### Prefill (cold cache, pack harness `bench/bench_pp.py`, single stream)

| Prompt | Prefill | TTFT |
|---:|---:|---:|
| 4,096 | **1,502 tok/s** | 2.7 s |
| 16,384 | **1,318 tok/s** | 12.4 s |
| 32,768 | **1,131 tok/s** | 29.0 s |

### Context ladder (llmprobe, thinking on)

| Context | **Single stream** decode | Prefill | TTFT | **4 concurrent** total | 4 concurrent, per stream | Worst TTFT (4 concurrent) |
|---|---:|---:|---:|---:|---:|---:|
| 2k | 148.3 | 1,468 | 1.4 s | 88.0 | 47.7 | 6.8 s |
| 4k | 142.7 | 1,467 | 2.8 s | 51.9 | 34.9 | 13.2 s |
| 8k | 146.7 | 1,422 | 5.8 s | 27.2 | 30.5 | 26.9 s |
| 16k | 139.7 | 1,309 | 12.4 s | 13.9 | 25.3 | 54.1 s |
| 33k | 122.4 | 1,131 | 29.1 s | 6.3 | 23.9 | 121.2 s |
| 66k | 109.9 | 887 | 73.8 s | 2.5 | 19.8 | 301.7 s |
| 131k | 86.3 | 567 | 231.5 s | 0.8 | 14.8 | 958.5 s |
| 256k | 62.3 | 330 | 775.3 s | 0.2 | 10.9 | 3,153.4 s |

- Requests with long prompts (2k and up in this test) are prefilled one at a time, so 4 concurrent long prompts
  are slower in total than one, and the 4th waits for the first three. Short prompts batch well (above).
- Docker Desktop ran for ~90 s (21:47:29–21:48:58) during the start of the 131k rung to push the
  carrier image. The 131k numbers match the same rung on the abliterated build within 3%.
- Long-context recall is not verified here. Every rung reports
  `answer never used RETRY_BUDGET_MS — context may be unread`: with thinking on and decode capped at 192 tokens
  the answer never gets past reasoning. Speed numbers are unaffected.

Raw: [`bench/results/`](bench/results/) and [`bench/results/llmprobe/`](bench/results/llmprobe/).

## Same Mac, other engines and builds

**Single stream** decode by task (thinking off, temp 0), plus 4-concurrent total for `structural`:

| | structural | list | essay | reading | count | 4 concurrent total (structural) | TTFT |
|---|---:|---:|---:|---:|---:|---:|---:|
| **AEON 4-bit MLX on TensorFold (this recipe)** | **228.0** | **188.4** | **102.8** | **114.3** | **378.7** | **399.2** | **~75 ms** |
| Huihui ablit oQ4e on TensorFold | 217.7 | 203.7 | 100.4 | 127.7 | 324.4 | 394.9 | ~75 ms |
| Stock Vontra 4-bit on TensorFold | 226.5 | 163.9 | 99.1 | 128.3 | 380.5 | 355.4 | ~75 ms |
| Huihui ablit oQ4e on oMLX 0.6.3rc2 (keys-Mac Dual-ANE pack) | 124.1 | 133.4 | 82.3 | 103.8 | 135.8 | 125.9 | ~360 ms |
| Same, M3 Ultra (pack's published numbers) | 69.1 | 77.6 | 49.6 | 49.1 | 79.1 | 79.7 | ~550 ms |

- **The engine matters far more than the build.** Without drafting, TensorFold decodes at ~37.7 tok/s on every
  task (`--no-drafts`). DFlash2 plus context-copy drafting gives the 2.7× (prose) to 8.6× (counting) on top,
  because the M5 lane kernels verify a 16-row draft window in 26.7 ms against 24.2 ms for one row.
- DFlash2 was trained on stock Qwen3.8-27B and still drafts as well for AEON's abliterated weights.
- `--prefill-pass 16` (default 8) changed nothing: prefill is compute-bound.

## One-shot

```bash
git clone https://github.com/drowzeys/keys-Mac-TensorFold-0.6.0-Qwen3.8-27B-AEON-Ultimate-Uncensored-4bit-MLX-DFlash2.git
cd keys-Mac-TensorFold-0.6.0-Qwen3.8-27B-AEON-Ultimate-Uncensored-4bit-MLX-DFlash2
brew install python@3.11 uv
bash oneshot-setup.sh
```

`oneshot-setup.sh` does the following:

1. Gets TensorFold 0.6.0 at commit `c4646171`, from the **GHCR prebuilt carrier** when Docker is available
   (checksums verified), otherwise from git at the same commit.
2. Installs it with the exact dependency lock ([`requirements.lock`](requirements.lock): mlx 0.32.3, mlx-lm
   0.31.3, transformers 5.18.0, …) into its own venv at `~/.local/opt/tensorfold-aeon`.
3. Pulls the model (15.2 GB) and drafter (3.8 GB).
4. Serves on **:8080**, then confirms the lane kernels and DFlash2 engaged.

Verified end to end from fresh prefixes on the M5 Ultra by both routes: GHCR carrier and git fallback,
22 s with the weights cached. Override `PREFIX`, `PORT` or `NAME` through the environment.
`bash oneshot-setup.sh --verify` checks an existing install. Restart with `bash scripts/serve.sh`.

### GHCR prebuilt carrier

```bash
docker pull ghcr.io/drowzeys/keys-mac-tensorfold-qwen38-27b-aeon:0.6.0
# index digest sha256:97228fdec198a63210f65e19d848fc6a90e318aecb20b25a4c48947e9bce3bc0 (linux/arm64 + linux/amd64)
docker run --rm -v "$PWD":/out ghcr.io/drowzeys/keys-mac-tensorfold-qwen38-27b-aeon:0.6.0 cp -a /payload/. /out/payload/
```

The carrier holds the TensorFold wheel, `requirements.lock` and `SHA256SUMS`. **It is not a Mac runtime**:
Metal does not run in a container, so `oneshot-setup.sh` installs the payload natively. Rebuild it with
`PUSH=1 bash scripts/build-carrier.sh`.

### Use

```bash
curl -s http://127.0.0.1:8080/v1/chat/completions -H 'content-type: application/json' -d '{
  "model": "qwen38-27b-aeon", "temperature": 0, "max_tokens": 512,
  "chat_template_kwargs": {"enable_thinking": false},
  "messages": [{"role": "user", "content": "Write a Python LRU cache with TTL."}]}'
```

OpenAI-compatible: chat completions, completions and `/v1/responses`. Thinking is on by default in the
template; the request above turns it off. Default sampling is the model's (temperature 1.0, top_k 20,
top_p 0.95).

## Stack

| Piece | Value |
|---|---|
| Host | Mac Studio M5 Ultra (Mac17,15), 256 GB, macOS 27.0.1 |
| Engine | TensorFold 0.6.0 @ `c4646171139ee8a3c38103eaa1699dad226ec12b` (Apache-2.0), MLX lane engine |
| Model | `choppedgarlic/Qwen3.8-27B-AEON-ULTIMATE-UNCENSORED-4bit-MLX` @ `875c8523` — 4-bit affine, groups of 64, 15.2 GB |
| Source | `AEON-7/Qwen3.8-27B-AEON-ULTIMATE-UNCENSORED-BF16` @ `449fcbf9` (Apache-2.0) |
| Drafter | `z-lab/Qwen3.8-27B-DFlash2` @ `50307d4c` (Apache-2.0), block 8, 4-bit |
| Resident | 18.3 GiB, loaded in ~14 s |
| Context | 262,144 tokens (model maximum) |
| Concurrency | up to 8 requests share a round (TensorFold default) |

## Notes

- **TensorFold has not tested this checkpoint.** At pull time it prints that `choppedgarlic/...-4bit-MLX` is
  not one of its tested checkpoints: "replies stay exact to serial decoding, speed and quality are unmeasured".
  The speed is measured here. Quality of the 4-bit conversion is not.
- **Refusal behavior of this 4-bit conversion is not measured.** AEON-7 publishes its own evaluation of the
  BF16 master on its card. 4-bit quantization can shift an abliterated model's behavior.
- **M5 only for these numbers.** M1–M4 run TensorFold's packed row decoder instead of the tensor-unit lane
  kernels.
- **No NVFP4 / FP8 on a Mac.** AEON-7's NVFP4-MIXED cut and TensorFold's FP8 paths are CUDA-only (DGX Spark,
  RTX 5090, RTX PRO 6000).
- TensorFold's prefill drops past 64k (330 tok/s at 256k). oMLX 0.6.3rc2 measured 443 tok/s at 256k on the
  same Mac, so for very long single prompts oMLX prefills faster. TensorFold decodes 2× faster there.

## Credits

Cite the original authors first: AEON-7 / SpaceTimeViking (model, abliteration pipeline) and the work they credit
(Qwen team, FernflowerAI, Wangzhang Wu's abliterix, Philipp Emanuel Weidmann's Heretic, Arditi et al., grimjim,
Huang et al.), choppedgarlic (4-bit MLX conversion), Ash Hart (TensorFold), z-lab (DFlash2), Apple MLX. Full list:
[CREDITS.md](CREDITS.md). Pack: drowzeys / keys.
