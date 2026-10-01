# Credits

**Big thanks.** This recipe is other people's work: the model, the abliteration, the Apple Silicon
conversion, the engine and the drafter. Keys / drowzeys only packaged it, pinned it and measured it on a
Mac Studio M5 Ultra. Cite the authors first.

## The model: AEON-7 / SpaceTimeViking

**AEON-7** (AeonForge7, @SpaceTimeViking on X) made **Qwen3.8-27B AEON Ultimate Uncensored**: the
abliteration pipeline, trial selection, leftover-refusal audit and serve validation, the MTP-head graft
back from stock, and the BF16 master (`AEON-7/Qwen3.8-27B-AEON-ULTIMATE-UNCENSORED-BF16`) this recipe
runs. Their NVFP4-MIXED deploy cut and DGX Spark recipes are on their Hugging Face and Patreon.

AEON's own credits for the abliteration, carried here in full:

- **Qwen team (Alibaba)** — base model Qwen/Qwen3.8-27B.
- **FernflowerAI** — SSM conv1d outlier-repair methodology.
- **Wangzhang Wu** — abliterix 1.12.2, the Heretic-derived multi-objective Optuna abliteration tool.
- **Philipp Emanuel Weidmann** — Heretic (p-e-w/heretic), upstream of abliterix.
- **Arditi et al. 2024** — the original abliteration concept, "Refusal in Language Models Is Mediated by a
  Single Direction".
- **grimjim** — NPBA / projected abliteration (2025).
- **Huang et al. 2025** — safety-tax quantification (arXiv:2503.00555).

## The 4-bit MLX conversion: choppedgarlic

**choppedgarlic** converted AEON's BF16 master to 4-bit affine MLX (groups of 64) for Apple Silicon:
`choppedgarlic/Qwen3.8-27B-AEON-ULTIMATE-UNCENSORED-4bit-MLX`. That is the exact checkpoint this recipe
serves. Per their card, all model and fine-tuning credit belongs to AEON-7 and the Qwen team; their
repository provides the conversion only.

## The engine: Ash Hart

**Ash Hart** (ashhart) — **TensorFold**: exact speculative decoding on Apple Silicon, the M5 tensor-unit
lane kernels, draft trees, shared rounds across concurrent requests, and prefix reuse. Every speed number
in this repo is TensorFold's engineering. Recipe pins TensorFold 0.6.0 at commit `c4646171`
(Apache-2.0).

## The drafter: z-lab

**z-lab** (DFlash) — the `z-lab/Qwen3.8-27B-DFlash2` block-diffusion draft model (Apache-2.0) that
TensorFold verifies against the target. It was trained on stock Qwen3.8-27B and still drafts well for
AEON.

## Platform and tools

- **Apple / ml-explore** — MLX.
- **llmprobe** — benchmark harness for the context ladder.
- Task and prefill harnesses are from the keys-Mac Qwen3.8-27B Dual-ANE pack.

Pack: drowzeys / keys.
