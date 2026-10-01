#!/usr/bin/env python3
"""Reconstructed 5-task C1/C4 bench for the Qwen3.8-27B Dual-ANE pack.

The M3U headline (results/2026-08-23-dualane-cpu-gdn-c1c4.json in the pack) was
produced by a harness that was never published. This rebuilds it from what the
JSON records: tasks structural/list/essay/reading/count, chat completions with
thinking off, temperature 0, streamed, decode measured post-TTFT, C1 x3 and
C4 x2. Prompts are reconstructed from the recorded output previews and
max_tokens from the recorded completion counts, so treat M3U-vs-M5U deltas on
this harness as approximate.

    python3 qwen_task_bench.py --model qwen38-27b-ablit --out m5u-qwen-tasks.json
"""
import argparse, json, statistics, threading, time, urllib.request, uuid

READING_DOC = (
    "Multi-agent systems often rely on a common system prompt to define shared behaviors, tools, "
    "and context for all agents. In standard LLM inference, each agent's request re-processes that "
    "shared prefix from scratch, which wastes prefill compute and inflates time-to-first-token. "
    "Prefix caching stores the key/value tensors for the shared prompt once and lets later requests "
    "reuse them, so only the agent-specific suffix must be prefilled. The trade-off is memory: cached "
    "blocks occupy KV capacity that could otherwise serve more concurrent sequences. "
) * 6

TASKS = {
    # role, prompt, max_tokens
    "structural": ("primary",
        "Emit one compact single-line JSON array (no spaces, no newlines) of 40 GPU telemetry "
        "objects: hosts gpu-node-01 to gpu-node-05, gpuIndex 0-7 on each host, keys host, gpuIndex, "
        "utilPct, tempC, powerW, memUsedMb, with varied realistic values. Start with [{ and output "
        "only the JSON.", 512),
    "list": ("primary",
        "List the 60 most common English words in frequency order as a single numbered line, "
        "like: 1. the 2. be 3. to ... Output only the list.", 190),
    "essay": ("primary",
        "Write a 400-word essay on the role of public parks in urban life.", 320),
    "reading": ("primary",
        READING_DOC + "\n\nSummarize the passage above in one paragraph of about 120 words.", 179),
    "count": ("diagnostic",
        "Count from 1 to 40 separated by single spaces. Output only the numbers.", 110),
}


def stream_one(url, model, prompt, max_tokens):
    body = {
        "model": model,
        "messages": [{"role": "user", "content": f"[{uuid.uuid4().hex[:8]}] " + prompt}],
        "max_tokens": max_tokens, "temperature": 0, "stream": True,
        "stream_options": {"include_usage": True},
        "chat_template_kwargs": {"enable_thinking": False}, "thinking": False,
    }
    req = urllib.request.Request(url + "/v1/chat/completions", data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    t0 = time.perf_counter(); first = None; n = 0; text = []; finish = None; usage = None
    with urllib.request.urlopen(req, timeout=1800) as r:
        for raw in r:
            line = raw.decode().strip()
            if not line.startswith("data:"):
                continue
            p = line[5:].strip()
            if p == "[DONE]":
                break
            d = json.loads(p)
            if d.get("usage"):
                usage = d["usage"]
            for ch in d.get("choices", []):
                piece = (ch.get("delta") or {}).get("content") or ""
                if piece:
                    if first is None:
                        first = time.perf_counter()
                    n += 1; text.append(piece)
                finish = ch.get("finish_reason") or finish
    end = time.perf_counter()
    toks = (usage or {}).get("completion_tokens") or n
    ttft = (first or end) - t0
    dec = (toks - 1) / (end - first) if first and end > first and toks > 1 else 0.0
    return {"ttft_ms": round(ttft * 1000), "decode_tok_s": round(dec, 2),
            "wall_tok_s": round(toks / (end - t0), 2), "completion_tokens": toks,
            "finish": finish, "preview": "".join(text)[:140], "wall_s": end - t0}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", default="http://127.0.0.1:11500")
    ap.add_argument("--model", required=True)
    ap.add_argument("--reps", type=int, default=3)
    ap.add_argument("--conc", type=int, default=4)
    ap.add_argument("--conc-samples", type=int, default=2)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    stream_one(a.url, a.model, "Say hi.", 8)  # warmup, discarded
    out = {"note": "Reconstructed harness (see docstring). thinking=false temp=0. decode=post-TTFT.",
           "url": a.url, "model": a.model, "conc": a.conc, "c1": {}, "c4": {}, "ts": time.time()}
    for name, (role, prompt, cap) in TASKS.items():
        runs = [stream_one(a.url, a.model, prompt, cap) for _ in range(a.reps)]
        dec = [r["decode_tok_s"] for r in runs]
        out["c1"][name] = {"decode_tok_s": dec, "wall_tok_s": [r["wall_tok_s"] for r in runs],
                           "completion_tokens": [r["completion_tokens"] for r in runs],
                           "ttft_ms": [r["ttft_ms"] for r in runs],
                           "median_decode": statistics.median(dec), "best_decode": max(dec),
                           "median_wall": statistics.median(r["wall_tok_s"] for r in runs),
                           "preview": runs[0]["preview"], "finish": [r["finish"] for r in runs],
                           "role": role}
        print(json.dumps({"c1": name, "median_decode": out["c1"][name]["median_decode"],
                          "ttft_ms": out["c1"][name]["ttft_ms"]}), flush=True)
    for name, (role, prompt, cap) in TASKS.items():
        samples = []
        for _ in range(a.conc_samples):
            res = [None] * a.conc
            def go(i):
                res[i] = stream_one(a.url, a.model, prompt, cap)
            t0 = time.perf_counter()
            th = [threading.Thread(target=go, args=(i,)) for i in range(a.conc)]
            [t.start() for t in th]; [t.join() for t in th]
            wall = time.perf_counter() - t0
            tot = sum(r["completion_tokens"] for r in res)
            samples.append({"aggregate_tok_s": round(tot / wall, 1),
                            "median_stream_decode": statistics.median(r["decode_tok_s"] for r in res),
                            "total_tok": tot, "wall_s": round(wall, 2),
                            "median_ttft_ms": statistics.median(r["ttft_ms"] for r in res)})
        agg = [s["aggregate_tok_s"] for s in samples]
        out["c4"][name] = {"samples": samples, "median_aggregate": statistics.median(agg),
                           "best_aggregate": max(agg),
                           "median_stream_decode": statistics.median(s["median_stream_decode"] for s in samples),
                           "role": role}
        print(json.dumps({"c4": name, "median_aggregate": out["c4"][name]["median_aggregate"]}), flush=True)
    with open(a.out, "w") as f:
        json.dump(out, f, indent=1)


if __name__ == "__main__":
    main()
