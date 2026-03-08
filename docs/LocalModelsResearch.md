# Local Models Research for OpenClaw on Mac Mini M4 (32GB)

> Research date: 2026-03-08
> Goal: Privacy-preserving local inference for email/message processing

---

## TL;DR — Recommended Setup

| Role | Model | Size (Q4) | Why |
|------|-------|-----------|-----|
| **Primary** | Qwen3.5-35B-A3B | ~18 GB | MoE, 3B active, outperforms prev-gen 235B model, newest architecture |
| **Alt Primary** | Qwen3-30B-A3B | ~16 GB | MoE, only 3B active params, excellent tool calling, proven track record |
| **Speed Primary** | LFM2-24B-A2B | ~14.4 GB | 2x faster CPU decode than Qwen3, native tool calling, only 2B active |
| **Fallback** | Qwen3.5-9B | ~6.6 GB | Best small model for its size, multimodal, great for light tasks |
| **Ultralight** | LFM2.5-1.2B-Instruct | ~0.7 GB | Fastest possible, good tool calling at 1B scale, RL-trained |

**Serving:** Ollama (simplest, official OpenClaw integration since Feb 2026)

---

## 1. OpenClaw Local Model Support

OpenClaw natively supports local models. No hacks needed.

### How It Works

- OpenClaw has a **native Ollama integration** documented at [docs.openclaw.ai/providers/ollama](https://docs.openclaw.ai/providers/ollama)
- Ollama announced official OpenClaw integration on **February 1, 2026** with `ollama launch openclaw`
- Model references use the format: `ollama/<model-name>` (e.g., `ollama/qwen3:30b-a3b`)
- Auto-discovery: set `OLLAMA_API_KEY="ollama-local"` and OpenClaw finds tool-capable models automatically

### Configuration

Three setup methods (simplest first):

**Method 1 — Environment Variable (auto-discovery):**
```bash
export OLLAMA_API_KEY="ollama-local"
# OpenClaw auto-discovers tool-capable models from http://127.0.0.1:11434
```

**Method 2 — Native Ollama provider in `openclaw.json`:**

> **IMPORTANT:** For native Ollama integration, do NOT use `/v1` suffix on the URL.
> Use `http://127.0.0.1:11434` (not `http://127.0.0.1:11434/v1`) — the `/v1` path breaks tool calling.

```json5
{
  models: {
    providers: {
      ollama: {
        baseUrl: "http://127.0.0.1:11434",
        apiKey: "ollama-local",
        models: [
          { id: "qwen3:30b-a3b", name: "Qwen3 30B-A3B" },
          { id: "qwen3.5:9b", name: "Qwen3.5 9B" }
        ]
      }
    }
  },
  agents: {
    defaults: {
      model: {
        primary: "ollama/qwen3:30b-a3b",
        heartbeat: "ollama/qwen3.5:9b",
        fallbacks: ["openrouter/google/gemini-2.5-flash-lite"]
      }
    }
  }
}
```

**Method 3 — OpenAI-compatible mode** (if native mode has issues):
```json5
{
  models: {
    providers: {
      "ollama-oai": {
        baseUrl: "http://127.0.0.1:11434/v1",
        apiKey: "ollama-local",
        api: "openai-completions",
        models: [{ id: "qwen3:30b-a3b", name: "Qwen3 30B-A3B" }]
      }
    }
  }
}
```

### Hybrid Setup (Recommended)

Local models handle 80-90% of tasks (messages, automations, lookups). Keep an OpenRouter fallback for edge cases requiring frontier-level reasoning. This gives you:
- **Privacy**: All routine processing stays on-device
- **Zero cost**: No API charges for daily usage
- **Reliability**: Cloud fallback when local model struggles

### Context Window

OpenClaw recommends **64k tokens minimum** for local models. MoE models handle long context well — KV cache growth is manageable.

---

## 2. Qwen Models (Latest as of March 2026)

### Model Family Overview

| Generation | Released | Key Models |
|-----------|----------|------------|
| **Qwen3** | Apr 2025 | Dense: 0.6B, 1.7B, 4B, 8B, 14B, 32B. MoE: 30B-A3B, 235B-A22B |
| **Qwen3-2507** | Jul 2025 | Updated 235B-A22B, 30B-A3B, 4B with enhanced reasoning + 256K context |
| **Qwen3-Next** | Sep 2025 | 80B-A3B ultra-sparse MoE with hybrid attention |
| **Qwen3-Coder-Next** | Feb 2026 | 80B-A3B, MoE, specialized for coding agents + tool calling |
| **Qwen3.5** | Feb 2026 | Flagship 397B-A17B, Medium (27B, 35B-A3B, 122B-A10B), Small (0.8B-9B) |

### Best Qwen Models for 32GB RAM

| Model | Quant | VRAM/RAM | Fits? | Tool Calling | Notes |
|-------|-------|----------|-------|--------------|-------|
| **Qwen3-30B-A3B** | Q4_K_XL | ~16 GB | Yes | Excellent | Best bang for buck. 3B active params, 91.0 ArenaHard |
| **Qwen3-32B** | Q4_K_M | ~19 GB | Tight | Good | Dense model, more consistent but slower |
| **Qwen3-Coder-Next 80B-A3B** | UD-Q2_K_XL | ~30 GB | Barely | Best | Needs >30GB, experimental on 32GB. Superb tool calling |
| **Qwen3.5-9B** | Q4_K_M | ~6.6 GB | Easy | Good | Multimodal, 262K context, best at 9B class |
| **Qwen3.5-35B-A3B** | Q4_K_M | ~TBD | Likely | Very good | MoE, 3B active. Outperforms previous 235B model |
| **Qwen3-8B** | Q8_0 | ~9 GB | Easy | Good | Reliable workhorse |

### Qwen Tool Calling Details

- Uses **Hermes-style** tool calling templates
- Best used with **Qwen-Agent** framework for parsing tool calls
- Qwen3-Coder-Next has the strongest tool calling of any Qwen model
- For reasoning models: avoid stopword-based templates (ReAct) — use Hermes instead
- Supported in Ollama, vLLM, SGLang, llama.cpp

### Qwen3.5 Notes

- Released in 3 waves: Flagship (Feb 16), Medium (Feb 24), Small (Mar 2)
- Uses **Gated Delta Networks + sparse MoE** — new architecture
- Small series (0.8B-9B) designed from scratch for on-device, not shrunken from larger models
- As of Mar 5, 2026: all GGUFs re-quantized with improved imatrix for better tool calling
- **Caveat:** Qwen3.5 GGUF in Ollama has issues with separate mmproj vision files. Use llama.cpp for multimodal. Text-only works in Ollama.

---

## 3. Liquid AI LFM Models

### Architecture

LFMs use a **non-transformer architecture** based on liquid neural networks — rooted in dynamical systems, numerical linear algebra, and signal processing. Key properties:
- **Inference-time adaptation**: Model behavior changes based on input without retraining
- **Constant memory**: Long inputs don't cause memory spikes (unlike transformers)
- **CPU-optimized**: 2x faster decode and prefill than Qwen3 on CPU

### Model Family

| Model | Params | Active | Released | GGUF Q4_K_M Size |
|-------|--------|--------|----------|------------------|
| LFM2-350M | 350M | 350M | Sep 2025 | ~230 MB |
| LFM2-700M | 700M | 700M | Sep 2025 | ~400 MB |
| LFM2-1.2B | 1.2B | 1.2B | Sep 2025 | ~730 MB |
| LFM2-2.6B | 2.6B | 2.6B | Sep 2025 | ~1.6 GB |
| LFM2-8B-A1B | 8B | 1B | Sep 2025 | ~TBD |
| **LFM2-24B-A2B** | **24B** | **2B** | Late 2025 | **~14.4 GB** |
| LFM2.5-1.2B-Instruct | 1.2B | 1.2B | Jan 2026 | ~700 MB |
| LFM2.5-1.2B-Thinking | 1.2B | 1.2B | Jan 2026 | ~700 MB |

### LFM2-24B-A2B — The Standout for This Use Case

- **14.4 GB at Q4_K_M** — fits comfortably in 32GB with room for context
- Only **2B active parameters** per token — extremely fast inference
- **112 tok/s decode** on AMD CPU, even faster on Apple Silicon Metal
- **Tool dispatch in under 400ms** — tested with 67 tools across 13 MCP servers
- Liquid AI built **LocalCowork**, an open-source desktop agent that runs entirely on-device
- Specifically designed for privacy-sensitive local tool-calling agents

### LFM Tool Calling Format

LFM2/2.5 use special tokens for tool calling:
- Tool definitions: `<|tool_list_start|>` / `<|tool_list_end|>` (LFM2)
- Tool calls: `<|tool_call_start|>` / `<|tool_call_end|>` (both)
- Tool responses: `<|tool_response_start|>` / `<|tool_response_end|>` (LFM2)
- Default output: Pythonic function calls (can override to JSON via system prompt)
- Compatible with llama.cpp, Ollama, LM Studio, vLLM

### LFM2.5-1.2B-Instruct

- Trained on 28T tokens + multi-stage RL focused on **instruction following, tool use, math, knowledge**
- Best-in-class at 1B scale for agentic tasks
- Specialized variants: Japanese, vision-language (1.6B), audio-language (1.5B)

### Why LFMs Matter for Privacy

- Constant memory regardless of input length — can process long emails/threads without memory spikes
- CPU-optimized — Mac Mini M4 CPU alone can drive good performance without GPU offloading concerns
- Designed explicitly for on-device, privacy-preserving inference
- Shopify signed a multi-year deal to deploy LFMs for quality-sensitive workflows

---

## 4. Serving Options for Mac Mini M4

### Recommendation: Ollama

| Framework | OpenClaw Integration | Ease of Setup | Performance | Apple Silicon |
|-----------|---------------------|---------------|-------------|---------------|
| **Ollama** | Native (Feb 2026) | Easiest | Good | Full Metal support |
| LM Studio | Via OpenAI API | Easy | Good | Full Metal support |
| llama.cpp | Via API server | Moderate | Best (raw) | Full Metal support |
| MLX | Manual | Moderate | Best for Apple | Native Apple framework |

**Ollama wins** for this use case because:
1. Official OpenClaw integration (`ollama launch openclaw`)
2. OpenAI-compatible API out of the box
3. Automatic model management (pull, quantize, serve)
4. Runs as a background service
5. Full Apple Silicon Metal acceleration

### Performance on 32GB Mac Mini M4

- **Unified memory** = CPU and GPU share all 32GB (no separate VRAM)
- Practical limit: ~20-22GB for model weights, leaving room for OS + context
- MoE models are ideal: only active parameters need compute, total params just need storage
- Expected speeds: 15-30 tok/s for 3B active MoE models, 8-15 tok/s for 8-9B dense models

### Model Size Guide for 32GB

| Budget | Max Model Size | Examples |
|--------|---------------|----------|
| Comfortable (16GB) | Up to 30B MoE or 14B dense at Q4 | Qwen3-30B-A3B, LFM2-24B-A2B |
| Tight (20-22GB) | Up to 32B dense at Q4 | Qwen3-32B Q4_K_M |
| Experimental (28-30GB) | Up to 80B MoE at Q2 | Qwen3-Coder-Next UD-Q2_K_XL |

---

## 5. Recommended Configuration for Claw

### Option A: Maximum Privacy (All Local)

```json
{
  "model": {
    "primary": "ollama/qwen3:30b-a3b-q4_K_M",
    "heartbeat": "ollama/lfm2.5:1.2b-instruct",
    "fallbacks": ["ollama/qwen3.5:9b"]
  }
}
```

- **Pro**: Zero data leaves the machine, zero API costs
- **Con**: No frontier-model fallback for complex reasoning

### Option B: Hybrid (Local Primary + Cloud Fallback)

```json
{
  "model": {
    "primary": "ollama/qwen3:30b-a3b-q4_K_M",
    "heartbeat": "ollama/lfm2.5:1.2b-instruct",
    "fallbacks": [
      "ollama/qwen3.5:9b",
      "openrouter/google/gemini-2.5-flash-lite"
    ]
  }
}
```

- **Pro**: Privacy for 80-90% of tasks, cloud quality when needed
- **Con**: Rare fallback requests go through OpenRouter (still zero-data-retention)

### Option C: LFM2-Focused (Speed Priority)

```json
{
  "model": {
    "primary": "ollama/lfm2-24b-a2b-q4_K_M",
    "heartbeat": "ollama/lfm2.5:1.2b-instruct",
    "fallbacks": ["ollama/qwen3:30b-a3b-q4_K_M"]
  }
}
```

- **Pro**: Fastest local inference, designed for tool dispatch (<400ms), constant memory
- **Con**: LFM2 ecosystem is newer, less community testing than Qwen

---

## 6. Installation Steps

```bash
# 1. Install Ollama
brew install ollama

# 2. Start Ollama service
ollama serve

# 3. Pull recommended models
ollama pull qwen3:30b-a3b          # Primary (~16GB)
ollama pull qwen3.5:9b             # Fallback (~6.6GB)

# For LFM2 option:
ollama pull lfm2:24b-a2b           # Primary (~14.4GB)
ollama pull lfm2.5:1.2b-instruct   # Heartbeat (~700MB)

# 4. Verify
ollama list
curl http://localhost:11434/v1/models

# 5. Update openclaw.json with local provider config
```

---

## 7. Key Considerations

### Tool Calling Reliability

OpenClaw is an agent framework with high requirements for tool calling stability. Community consensus:
- **<14B models**: Prone to hallucinated tool calls, loops, forgotten parameters
- **14B-32B**: Reliable for most tasks
- **32B+**: Most stable

The MoE models (Qwen3-30B-A3B, LFM2-24B-A2B) are excellent choices because they have large total parameter counts (30B/24B of knowledge) but small active counts (3B/2B) for speed.

### Privacy Gains Over Current Setup

| Current (OpenRouter) | Local (Ollama) |
|-----------------------|----------------|
| Email content sent to MiniMax servers | Email content never leaves Mac Mini |
| Text messages routed through API | Messages processed entirely on-device |
| Zero-data-retention policy (trust-based) | Physically impossible to leak (no network) |
| API costs (~$20/month cap) | Zero marginal cost |

### Tradeoffs

- **Quality**: Local 30B MoE models are good but not frontier-level. Complex multi-step reasoning may need cloud fallback.
- **Speed**: First token latency is higher than API (~1-3s vs ~0.3s). Throughput is comparable for MoE models.
- **Context window**: Local models with 32K-64K context vs cloud models with 128K+. Sufficient for email/message processing.

---

## Sources

- [Qwen3 GitHub](https://github.com/QwenLM/Qwen3)
- [Qwen3.5 GitHub](https://github.com/QwenLM/Qwen3.5)
- [Qwen Function Calling Docs](https://qwen.readthedocs.io/en/latest/framework/function_call.html)
- [Qwen-Agent Framework](https://github.com/QwenLM/Qwen-Agent)
- [Qwen3 on Ollama](https://ollama.com/library/qwen3)
- [Qwen3.5 on Ollama](https://ollama.com/library/qwen3.5)
- [Qwen3-Coder-Next GGUF (Unsloth)](https://huggingface.co/unsloth/Qwen3-Coder-Next-GGUF)
- [Qwen3-Coder-Next Hardware Requirements](https://www.hardware-corner.net/qwen3-coder-next-hardware-requirements/)
- [LFM2 Blog Post](https://www.liquid.ai/blog/liquid-foundation-models-v2-our-second-series-of-generative-ai-models)
- [LFM2-24B-A2B Tool Calling Blog](https://www.liquid.ai/blog/no-cloud-tool-calling-agents-consumer-hardware-lfm2-24b-a2b)
- [LFM2-24B-A2B GGUF on Hugging Face](https://huggingface.co/LiquidAI/LFM2-24B-A2B-GGUF)
- [LFM2.5-1.2B-Instruct on Hugging Face](https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct)
- [Liquid AI Tool Use Docs](https://docs.liquid.ai/lfm/key-concepts/tool-use)
- [OpenClaw + Ollama Integration (Ollama Blog)](https://ollama.com/blog/openclaw)
- [OpenClaw Model Providers Docs](https://docs.openclaw.ai/concepts/model-providers)
- [Best Ollama Models for OpenClaw 2026](https://clawdbook.org/blog/openclaw-best-ollama-models-2026)
- [OpenClaw + Qwen 3.5 + Ollama Tutorial](https://atalupadhyay.wordpress.com/2026/03/01/build-your-own-free-personal-ai-agent-using-qwen-3-5-ollama-openclaw/)
