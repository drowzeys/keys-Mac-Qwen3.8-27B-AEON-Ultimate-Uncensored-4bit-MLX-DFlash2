# Responsible Use

**WARNING:** Qwen3.8-27B AEON Ultimate Uncensored has had safety refusals removed (abliterated). It will
write what the base model refuses. That makes it useful for red-teaming, security research, alignment
work and creative writing, and it also removes guardrails you must therefore supply yourself.

This repo ships no weights. It installs an engine and points it at third-party checkpoints:

- `choppedgarlic/Qwen3.8-27B-AEON-ULTIMATE-UNCENSORED-4bit-MLX` (Apache-2.0), an MLX conversion of
- `AEON-7/Qwen3.8-27B-AEON-ULTIMATE-UNCENSORED-BF16` (Apache-2.0).

**AEON-7's model card terms apply to your use of the model.** Read them on the BF16 card before
downloading: as-is with no warranty, your own legal compliance, no endorsement of outputs, and
indemnification of the authors, contributors and publishers. Downloading, running, quantizing or
distributing the model means you accept them.

## Prohibited uses

1. Anything involving the sexual exploitation or endangerment of minors.
2. Use by anyone under 18.
3. Generating material that can cause physical harm (for example weapons or dangerous-substance
   synthesis). You are responsible and accountable for what you prompt and for what you do with it.
4. Content promoting self-harm or suicide.
5. Material illegal in your jurisdiction, or targeting real individuals for harassment, doxxing or fraud.
6. Anything prohibited by the upstream Qwen license or AEON-7's terms.

## Your responsibility

Add your own safety filtering, human review and access controls before exposing this model to anyone
else. TensorFold binds to `127.0.0.1` in this recipe on purpose; do not put it on a network without them.

Refusal behavior of this 4-bit conversion has **not** been measured here. AEON-7 reports its own
evaluation of the BF16 master on its card.
