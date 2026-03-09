# Local Models Research for OpenClaw on Mac Mini M4 (32GB)

> Research date: 2026-03-09 (updated: LM Studio replaces Ollama as serving backend)
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

**Serving:** LM Studio (MLX backend for fastest Apple Silicon inference, OpenAI-compatible API, GUI + headless modes)

---

## 1. OpenClaw Local Model Support

OpenClaw natively supports local models via any OpenAI-compatible API server. We're using **LM Studio** as the serving backend.

### Why LM Studio

- **MLX backend** on Apple Silicon — 20-30% faster than llama.cpp alternatives
- **OpenAI-compatible API** at `http://localhost:1234/v1` — drop-in for OpenClaw
- **GUI + CLI + headless** — browse/download models visually, automate with `lms` CLI, or run headless via `llmster` daemon
- **JIT model loading** — models auto-load on first API request, auto-unload after inactivity
- **Tool/function calling** — supports OpenAI-format tool calls via `/v1/chat/completions` and `/v1/responses`
- **Dual backend** — MLX (fastest on Apple Silicon) and llama.cpp (GGUF), can mix and match
- Docs: [lmstudio.ai/docs](https://lmstudio.ai/docs/app) | [Developer API](https://lmstudio.ai/docs/developer/rest) | [Tool Use](https://lmstudio.ai/docs/developer/openai-compat/tools)

### LM Studio API Details

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/models` | GET | List loaded models |
| `/v1/chat/completions` | POST | Chat with tool calling support |
| `/v1/responses` | POST | Stateful interactions (v0.3.29+) |
| `/v1/embeddings` | POST | Generate embeddings |
| `/v1/completions` | POST | Legacy text completion |

- **Default port:** 1234 (configurable)
- **API key:** `"lm-studio"` (dummy — no real key required unless you enable auth)
- **Streaming:** Supported via SSE (`stream: true`)
- **Auth tokens:** Optional, configurable in Developer > Server Settings (v0.4.0+)

### OpenClaw Configuration

LM Studio connects to OpenClaw as a custom provider using the OpenAI-compatible API:

```json5
{
  models: {
    mode: "merge",  // keeps cloud providers available as fallback
    providers: {
      lmstudio: {
        baseUrl: "http://127.0.0.1:1234/v1",
        apiKey: "lm-studio",
        api: "openai-completions",  // NOT "openai-responses" — known bug (openclaw#1695)
        models: [
          {
            id: "qwen3-30b-a3b",        // must match model ID from /v1/models
            name: "Qwen3 30B-A3B",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 32768,
            maxTokens: 8192
          },
          {
            id: "qwen3.5-9b",
            name: "Qwen3.5 9B",
            reasoning: false,
            input: ["text"],
            cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
            contextWindow: 32768,
            maxTokens: 8192
          }
        ]
      }
    }
  },
  agents: {
    defaults: {
      model: {
        primary: "lmstudio/qwen3-30b-a3b",
        heartbeat: "lmstudio/qwen3.5-9b",
        fallbacks: ["openrouter/google/gemini-2.5-flash-lite"]
      }
    }
  }
}
```

> **Notes:**
> - `"mode": "merge"` keeps paid/cloud providers active alongside LM Studio.
> - `cost` block at all zeros tells OpenClaw this model is free, affecting routing priority.
> - Use `"api": "openai-completions"`, NOT `"openai-responses"` — there's a [known bug](https://github.com/openclaw/openclaw/issues/1695) where the API type arrives as `undefined` with the responses variant.
> - Set `"reasoning": false` — setting it to `true` causes OpenClaw to send "developer" role messages, which most local models don't support.
> - Verify your model IDs match what `curl http://localhost:1234/v1/models` returns.
> - Run `openclaw doctor` to verify connectivity and config after setup.

### LM Studio CLI (`lms`)

```bash
lms status              # Check LM Studio status
lms server start        # Start the API server
lms server stop         # Stop the API server
lms ls                  # List downloaded models
lms ps                  # List loaded models (in memory)
lms load <model> -y     # Load model with max GPU acceleration
lms unload --all        # Unload all models
lms get <user/repo>     # Download model from Hugging Face
lms get <repo>@Q4_K_M   # Download specific quantization
```

Install CLI: `npx lmstudio install-cli` (if `lms` not in PATH)

### Headless Mode (`llmster`)

For running LM Studio without the GUI (e.g., as a background service on the Mac Mini):

```bash
lms daemon up           # Start headless daemon
lms get <model>         # Download model
lms server start        # Start API server
```

Can be configured as a **macOS launch agent** or **Linux systemd service** to auto-start on login.
JIT loading means you don't need to pre-load models — they load on first API request.

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

### Recommendation: LM Studio

| Framework | OpenClaw Integration | Ease of Setup | Performance | Apple Silicon |
|-----------|---------------------|---------------|-------------|---------------|
| **LM Studio** | Via OpenAI API | Easy (GUI + CLI) | Best (MLX) | MLX + Metal native |
| Ollama | Native (Feb 2026) | Easiest | Good | Full Metal support |
| llama.cpp | Via API server | Moderate | Best (raw) | Full Metal support |
| MLX (direct) | Manual | Moderate | Best for Apple | Native Apple framework |

**LM Studio wins** for this use case because:
1. **MLX backend** — 20-30% faster inference than llama.cpp on Apple Silicon
2. **GUI for model management** — browse, download, test models visually before committing
3. **OpenAI-compatible API** at `localhost:1234/v1` — works with OpenClaw out of the box
4. **Headless mode** (`llmster`) — run as a daemon without GUI, auto-start on login
5. **JIT model loading** — models load automatically on first API request
6. **Dual backend** — MLX for speed, llama.cpp for GGUF compatibility, can mix both
7. **Tool calling support** — OpenAI-format function calling through the API
8. **CLI (`lms`)** — full model management, server control, and downloads from terminal

### Performance on 32GB Mac Mini M4

- **Unified memory** = CPU and GPU share all 32GB (no separate VRAM)
- Practical limit: ~20-22GB for model weights, leaving room for OS + context
- MoE models are ideal: only active parameters need compute, total params just need storage
- Expected speeds: 15-30 tok/s for 3B active MoE models, 8-15 tok/s for 8-9B dense models
- **MLX vs llama.cpp**: MLX is 21-87% faster on Apple Silicon with zero-copy unified memory access
- **Memory bandwidth is the bottleneck** — determines token generation speed, not compute
- **GPU offloading is automatic** on Mac with MLX (unified memory, no manual layer config needed)

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
    "primary": "lmstudio/qwen3-30b-a3b",
    "heartbeat": "lmstudio/lfm2.5-1.2b-instruct",
    "fallbacks": ["lmstudio/qwen3.5-9b"]
  }
}
```

- **Pro**: Zero data leaves the machine, zero API costs
- **Con**: No frontier-model fallback for complex reasoning

### Option B: Hybrid (Local Primary + Cloud Fallback)

```json
{
  "model": {
    "primary": "lmstudio/qwen3-30b-a3b",
    "heartbeat": "lmstudio/lfm2.5-1.2b-instruct",
    "fallbacks": [
      "lmstudio/qwen3.5-9b",
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
    "primary": "lmstudio/lfm2-24b-a2b",
    "heartbeat": "lmstudio/lfm2.5-1.2b-instruct",
    "fallbacks": ["lmstudio/qwen3-30b-a3b"]
  }
}
```

- **Pro**: Fastest local inference, designed for tool dispatch (<400ms), constant memory
- **Con**: LFM2 ecosystem is newer, less community testing than Qwen

---

## 6. Installation Steps

### Install LM Studio

```bash
# Mac/Linux — one-line install
curl -fsSL https://lmstudio.ai/install.sh | bash

# Or download from https://lmstudio.ai/ (GUI installer)
```

### Download Models

**Option 1 — GUI:** Open LM Studio > Discover tab > search and download models. LM Studio shows RAM estimates and recommends quantizations for your hardware.

**Option 2 — CLI:**
```bash
# Install CLI if needed
npx lmstudio install-cli

# Download recommended models
lms get qwen/qwen3-30b-a3b-gguf@Q4_K_M     # Primary (~16GB)
lms get qwen/qwen3.5-9b-gguf@Q4_K_M         # Fallback (~6.6GB)

# For LFM2 option:
lms get LiquidAI/LFM2-24B-A2B-GGUF          # Primary (~14.4GB)
lms get LiquidAI/LFM2.5-1.2B-Instruct       # Heartbeat (~700MB)
```

### Start the Server

```bash
# GUI: Developer tab > toggle "Start Server"
# CLI:
lms server start

# Verify
curl http://localhost:1234/v1/models
```

### Configure OpenClaw

Update `~/.openclaw/openclaw.json` with the LM Studio provider config from Section 1.

```bash
# Verify OpenClaw can reach LM Studio
openclaw models status
```

### Optional: Headless Auto-Start

For running as a background service on the Mac Mini (no GUI needed):

```bash
# Start daemon
lms daemon up
lms server start

# Or set up as a macOS launch agent for auto-start on login
# See: https://lmstudio.ai/docs/developer/core/headless
```

### Performance Tips

- Use **MLX format** models when available (fastest on Apple Silicon)
- For GGUF models, LM Studio's MLX backend reads Q4_0, Q4_1, Q8_0 directly; other quants get cast to float16
- **Q4_K_M** is the sweet spot for quality/size ratio
- Keep models loaded — cold-load adds startup latency (or use JIT loading)
- Set context window to 32K-64K for best memory/performance balance

---

## 7. Key Considerations

### Tool Calling Reliability

OpenClaw is an agent framework with high requirements for tool calling stability. Community consensus:
- **<14B models**: Prone to hallucinated tool calls, loops, forgotten parameters
- **14B-32B**: Reliable for most tasks
- **32B+**: Most stable

The MoE models (Qwen3-30B-A3B, LFM2-24B-A2B) are excellent choices because they have large total parameter counts (30B/24B of knowledge) but small active counts (3B/2B) for speed.

### Privacy Gains Over Current Setup

| Current (OpenRouter) | Local (LM Studio) |
|-----------------------|--------------------|
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

### LM Studio
- [LM Studio Docs](https://lmstudio.ai/docs/app)
- [LM Studio Developer Docs](https://lmstudio.ai/docs/developer)
- [LM Studio REST API](https://lmstudio.ai/docs/developer/rest)
- [LM Studio OpenAI Compatibility](https://lmstudio.ai/docs/developer/openai-compat)
- [LM Studio Tool Use / Function Calling](https://lmstudio.ai/docs/developer/openai-compat/tools)
- [LM Studio CLI](https://lmstudio.ai/docs/cli)
- [LM Studio Headless Mode](https://lmstudio.ai/docs/developer/core/headless)
- [LM Studio Python SDK](https://lmstudio.ai/docs/python)
- [LM Studio API Changelog](https://lmstudio.ai/docs/developer/api-changelog)
- [LM Studio MLX Engine (GitHub)](https://github.com/lmstudio-ai/mlx-engine)
- [LM Studio Server Settings](https://lmstudio.ai/docs/developer/core/server/settings)
- [LM Studio v0.3.6 — Tool Calling](https://lmstudio.ai/blog/lmstudio-v0.3.6)
- [LM Studio v0.4.0 — llmster Daemon](https://lmstudio.ai/blog/0.4.0)

### OpenClaw
- [OpenClaw Model Providers Docs](https://docs.openclaw.ai/concepts/model-providers)
- [OpenClaw Local Models Guide](https://docs.openclaw.ai/gateway/local-models)
- [OpenClaw + LM Studio Setup (Medium)](https://nwosunneoma.medium.com/how-to-setup-openclaw-with-lmstudio-1960a8046f6b)
- [OpenClaw Custom Model Config](https://blog.laozhang.ai/en/posts/openclaw-custom-model)
- [OpenClaw + LM Studio Bug #1695](https://github.com/openclaw/openclaw/issues/1695)

### Models
- [Qwen3 GitHub](https://github.com/QwenLM/Qwen3)
- [Qwen3.5 GitHub](https://github.com/QwenLM/Qwen3.5)
- [Qwen Function Calling Docs](https://qwen.readthedocs.io/en/latest/framework/function_call.html)
- [Qwen-Agent Framework](https://github.com/QwenLM/Qwen-Agent)
- [Qwen3-Coder-Next GGUF (Unsloth)](https://huggingface.co/unsloth/Qwen3-Coder-Next-GGUF)
- [Qwen3-Coder-Next Hardware Requirements](https://www.hardware-corner.net/qwen3-coder-next-hardware-requirements/)
- [LFM2 Blog Post](https://www.liquid.ai/blog/liquid-foundation-models-v2-our-second-series-of-generative-ai-models)
- [LFM2-24B-A2B Tool Calling Blog](https://www.liquid.ai/blog/no-cloud-tool-calling-agents-consumer-hardware-lfm2-24b-a2b)
- [LFM2-24B-A2B GGUF on Hugging Face](https://huggingface.co/LiquidAI/LFM2-24B-A2B-GGUF)
- [LFM2.5-1.2B-Instruct on Hugging Face](https://huggingface.co/LiquidAI/LFM2.5-1.2B-Instruct)
- [Liquid AI Tool Use Docs](https://docs.liquid.ai/lfm/key-concepts/tool-use)
