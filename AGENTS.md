# Agent one-shot — Qwen3.8-27B AEON Ultimate Uncensored (4-bit MLX) on TensorFold

**Repo:** https://github.com/drowzeys/keys-Mac-TensorFold-0.6.0-Qwen3.8-27B-AEON-Ultimate-Uncensored-4bit-MLX-DFlash2  
**Carrier image:** `ghcr.io/drowzeys/keys-mac-tensorfold-qwen38-27b-aeon:0.6.0` (not a runtime; TensorFold wheel + lock)  
**Engine:** TensorFold 0.6.0 @ `c4646171`, own venv, MLX lane kernels + DFlash2

```bash
git clone https://github.com/drowzeys/keys-Mac-TensorFold-0.6.0-Qwen3.8-27B-AEON-Ultimate-Uncensored-4bit-MLX-DFlash2.git
cd keys-Mac-TensorFold-0.6.0-Qwen3.8-27B-AEON-Ultimate-Uncensored-4bit-MLX-DFlash2
brew install python@3.11 uv
bash oneshot-setup.sh      # engine (GHCR carrier or git), weights 15.2 GB + drafter 3.8 GB, serve :8080
```

Serve id: `qwen38-27b-aeon`. Base URL `http://127.0.0.1:8080/v1`. Default sampling is the model's
(temperature 1.0, top_k 20, top_p 0.95); send `temperature: 0` for greedy.

Rules:

- Keep the DFlash2 drafter pulled (`z-lab/Qwen3.8-27B-DFlash2`). Without it, decode is ~37 tok/s flat.
- Do not pass `--no-drafts`. Drafted output equals serial output; drafting only changes speed.
- The fast path is M5-only (lane kernels on tensor units). Other Apple Silicon runs the packed row decoder;
  the README numbers do not apply there.
- Thinking is on by default in the template. For short answers send
  `chat_template_kwargs: {"enable_thinking": false}`.
- Restart with `scripts/serve.sh`, which frees the port first.
- NVFP4 / FP8 builds of this model (AEON-7's NVFP4-MIXED) are CUDA-only and do not run here.
- Read RESPONSIBLE_USE.md: the model is abliterated; AEON-7's card terms apply.

**Credits:** keep CREDITS.md in sync. AEON-7 / SpaceTimeViking (model) and the credits they carry,
choppedgarlic (4-bit MLX conversion), Ash Hart (TensorFold), z-lab (DFlash2), Qwen team, MLX. Authors only — no
credit hyperlinks.
