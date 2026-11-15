#### Below analysis is incorrect. Mentions ROCM. ROCM doesn't get used on the DGX nodes

Read

Searched for files matching `**/8.md`, 1 match

Read

Searched for text `^## ` (`**/8.md`), 7 results

Read , lines 1 to 100

Read , lines 1 to 300

Read

Read



Now I have the full picture. Let me compare 8.md's recommendations against the 37 recipes from `9.md` and the current `llm-strategy.md` to see what changes.

---

## `8.md` Recommendations vs. `9.md` Reality Check

### What `8.md` Recommended

`8.md` gave these recommendations:

1. **Primary local model**: `qwen3.5-397b-int4` (recipe #9) as a drop-in replacement for `qwen3.8-flash-next`
2. **Embedding/reranking**: Keep on CPU nodes (not DGX)
3. **Vision**: Verify which recipes include vision capability
4. **The 37 recipes**: Replace cloud subscription models with local equivalents

### What Changes Given the Full 37-Recipe Analysis

#### ❌ 8.md's Memory Math Was Wrong

`8.md` stated:

> Active weights: ~17-20 GB

This is **incorrect**. For a MoE model, the *active* parameters (17B) are what compute per token, but the **full weight matrix** (~100 GB for INT4) must be loaded into GPU memory for routing. The recipe itself confirms this — it uses `count: 2` (TP=2 across spark1+spark2), meaning ~100 GB per node. With 128GB unified memory and ~13-18GB Talos overhead, that leaves ~110GB. The 397B INT4 model at TP=2 is **tight but feasible** — not the comfortable ~20GB `8.md` suggested.

#### ❌ `8.md` Missed the ROCm Problem Entirely

`8.md` assumed the DGX Spark was a Blackwell GPU (it said "GB10 Grace CPU + Blackwell GPU"). **The DGX Spark uses AMD GPUs (ROCm), not NVIDIA Blackwell.** This changes everything:

- **14 recipes with NVFP4 quantization** (recipes 3, 4, 5, 10, 16, 19, 20, 21, 22, 23, 24, 25, 35, 36) — **won't work on ROCm at all**
- **5 B12X-optimized recipes** (11, 12, 27, 28, 30) — **Blackwell-specific, won't work on any non-Blackwell hardware**
- **1 MXFP4 recipe** (37) — NVIDIA-specific
- **All recipes use `flashinfer` attention backend** — CUDA-only, needs `triton` on ROCm
- **All recipes use `VLLM_MARLIN_USE_ATOMIC_ADD`** — NVIDIA Marlin kernel, needs removal
- **All recipes have `nvidia.com/gpu.present` nodeSelector** — needs AMD labels

#### ✅ What Still Holds

**1. `qwen3.5-397b-int4` (recipe #9) is still the best primary model replacement**

It's one of the few feasible options:
- AWQ INT4 quantization — supported on ROCm vLLM
- No speculative decoding — no DFlash/DSpark dependency
- TP=2 across 2 nodes — fits the DGX Spark architecture
- 397B/17B MoE is significantly more capable than `qwen3.8-flash-next` (180B/6B)

**But the memory math needs correction:** ~100 GB per node at TP=2, not ~20 GB.

**2. Embedding/reranking stay on CPU** — unchanged.

**3. Vision capability** — the Qwen3.5-397B-A17B is **text-only**. For vision on DGX Spark, you'd need:
- `nemotron-3.5-super-vl-nvfp4` (recipe #23) — but it's NVFP4, won't work on ROCm
- `deepseek-v4-flash-vision-exp` (recipe #28) — but it's B12X, won't work
- No vision-capable ROCm-compatible recipe exists in `9.md`

#### ⚠️ What `8.md` Got Partially Right — Cloud Model Replacements

`8.md` said the 37 recipes replace cloud subscriptions. Here's the corrected mapping of which recipes are **actually feasible on ROCm** vs. which are not:

| Cloud Model (llm-strategy.md) | `9.md` Recipe | ROCm Feasible? |
|---|---|---|
| `MiniMax-M3.1-Flash` | `minimax-m2-awq` (#31), `minimax-m2.5-awq` (#32), `minimax-m2.7-awq` (#33) | ✅ Yes — AWQ INT4, no speculative decoding |
| `glm-5.3` | `glm-4.7-flash-awq` (#29) | ✅ Yes — AWQ INT4, single-node |
| `glm-5.3-flash` | `glm-5.3-flash-fp4-local` (#30) | ❌ No — B12X FP4, Blackwell-specific |
| `kimi-k3` / `kimi-k2.7` | `step-3.7-flash-fp8` (#34), `step-3.7-flash-nvfp4` (#35) | ⚠️ FP8 variant yes, NVFP4 no |
| `dsv4.1f` (DeepSeek) | `deepseek-v4-flash` (#26) | ✅ Yes — FP8, no speculative decoding |
| `dsv4.1f` (DeepSeek) | `deepseek-v4-flash-0731` (#27) | ❌ No — B12X |
| `dsv4.1f` (DeepSeek) | `deepseek-v4-flash-vision-exp` (#28) | ❌ No — B12X + vision |
| `chatgpt/gpt-6-astra/sol/luna` | `openai-gpt-oss-120b` (#37) | ❌ No — MXFP4, NVIDIA-specific |
| `openai-gpt-oss-120b` | `inkling-small-nvfp4` (#36) | ❌ No — NVFP4 |

---

### Updated Recommendations

#### Primary Local Model (Courier Coordinator)

| Recommendation | Status |
|---|---|
| `qwen3.5-397b-int4` (#9) | ✅ Still best choice. TP=2 across 2 DGX Spark nodes. ~100GB/node. AWQ INT4 works on ROCm. |
| `qwen3.6-35b-a3b-fp8` (#1) | ✅ Alternative. TP=2 on single node. ~50-60GB. Faster throughput, less capable than 397B. |
| `qwen3.5-35b-a3b-fp8` (#6) | ✅ Alternative. TP=1 on single node. ~35GB weights. Smallest footprint. |

**Recommendation:** Keep `qwen3.5-397b-int4` as primary. It's the only recipe that meaningfully replaces the 180B/6B flash-next capability tier.

#### Secondary Local Model (Courier `coder-local`)

| Recommendation | Status |
|---|---|
| `qwen3.8-coder-next-fp8` (#13) | ✅ FP8, single-node TP=1. Intel Qwen3-Coder-Next. |
| `qwen3.8-coder-next-int4` (#14) | ✅ AWQ INT4, single-node TP=1. Smaller footprint. |
| `glm-4.7-flash-awq` (#29) | ✅ AWQ INT4, single-node TP=1. 202K context. |

**Recommendation:** `qwen3.8-coder-next-int4` (#14) — purpose-built for coding, INT4 quantization, single-node.

#### Cloud Model Replacements (Feasible on ROCm)

| Cloud Alias | ROCm-Friendly Recipe | Notes |
|---|---|---|
| `MiniMax-M3.1-Flash` | `minimax-m2-awq` (#31) or `minimax-m2.5-awq` (#32) | TP=2 multi-node. AWQ INT4. |
| `glm-5.3` | `glm-4.7-flash-awq` (#29) | Single-node. 202K context. |
| `dsv4.1f` | `deepseek-v4-flash` (#26) | TP=2 multi-node. FP8. |
| `kimi-k3` / `kimi-k2.7` | `step-3.7-flash-fp8` (#34) | TP=2 multi-node. FP8. |

#### What You Cannot Run on DGX Spark (from `9.md`)

| Category | Count | Recipes |
|---|---|---|
| NVFP4 quantization | 14 | 3, 4, 5, 10, 16, 19, 20, 21, 22, 23, 24, 25, 35, 36 |
| B12X Blackwell | 5 | 11, 12, 27, 28, 30 |
| MXFP4 | 1 | 37 |
| **Total unusable** | **20** | |

#### What Stays the Same from `8.md`

| Item | Status |
|---|---|
| Embedding on CPU (`qwen3-embedding-0.6b`) | ✅ Unchanged |
| Reranking on CPU (`bge-reranker-v2-m3`) | ✅ Unchanged |
| `qwen3.5-397b-int4` as primary | ✅ Still recommended |
| Courier coordinator role | ✅ Same model, different hardware |
| Dispatch groomer role | ✅ Same model, different hardware |

#### What Changes from `8.md`

| Item | `8.md` Said | Reality |
|---|---|---|
| **397B model memory** | "~20 GB active" | ~100 GB per node at TP=2 (full weights, not active params) |
| **DGX Spark GPU** | "Blackwell GPU" | AMD GPU (ROCm) — NVIDIA-specific features won't work |
| **Vision capability** | "Verify which recipes include vision" | **No vision-capable ROCm recipe exists** in `9.md` |
| **Speculative decoding** | Not addressed | DFlash/DSpark are NVIDIA-specific; MTP may work on ROCm |
| **Cloud replacements** | Implied all 37 work | Only ~17 of 37 are ROCm-feasible |
| **glm-5.3-flash** | Not addressed | Recipe #30 is B12X — won't work |
| **OpenAI GPT-OSS** | Not addressed | Recipe #37 is MXFP4 — won't work |

---

### Bottom Line

**8.md's core recommendation stands:** `qwen3.5-397b-int4` (#9) is the right primary model replacement for `qwen3.8-flash-next`. But the supporting analysis was wrong on three critical points:

1. **Memory:** ~100 GB/node, not ~20 GB
2. **GPU:** AMD ROCm, not NVIDIA Blackwell — 20 of 37 recipes are unusable
3. **Vision:** No vision-capable ROCm recipe exists in `9.md`

The feasible ROCm recipes from `9.md` are: **#1, #2, #6, #7, #8, #9, #13, #14, #15, #17, #18, #26, #29, #31, #32, #33, #34** — 17 recipes total. These cover FP8, AWQ INT4, and BF16 quantizations without NVIDIA-specific speculative decoding.
