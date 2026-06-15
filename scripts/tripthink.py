#!/usr/bin/env python3
"""
TripThink Orchestrator — CLI-agnostic parallel dispatcher for multi-model deliberation.

Supports Anthropic-compatible, OpenAI-compatible, and OpenRouter APIs.
Reads model config from $TRIPTHINK_HOME/config.json (default ~/.tripthink/config.json).

Usage:
  # All models get the same prompt
  python3 tripthink.py dispatch --prompt "What is X?"

  # Each model gets a different prompt (role-based)
  python3 tripthink.py dispatch --prompts prompts.json

  # Read prompt from file, write results to file
  python3 tripthink.py dispatch --prompt-file /tmp/prompt.txt --output /tmp/results.json

  # Use specific models only
  python3 tripthink.py dispatch --models model_a,model_b --prompt "..."

  # List / check
  python3 tripthink.py list
  python3 tripthink.py check

Config path discovery (in order):
  1. $TRIPTHINK_HOME/config.json
  2. ~/.tripthink/config.json
  3. ../config.json  (relative to this script)
"""

import asyncio
import json
import os
import sys
import time
import argparse
from pathlib import Path
from typing import Optional

try:
    import httpx
except ImportError:
    print("Error: 'httpx' package not found.", file=sys.stderr)
    print(f"Install: {sys.executable} -m pip install httpx", file=sys.stderr)
    sys.exit(1)

# ── Config path discovery ────────────────────────────────────────────
def _find_config() -> Path:
    """Resolve config.json path in order: env var → ~/.tripthink/ → script-relative."""
    if "TRIPTHINK_HOME" in os.environ:
        return Path(os.environ["TRIPTHINK_HOME"]) / "config.json"
    home = Path.home() / ".tripthink" / "config.json"
    if home.exists():
        return home
    relative = Path(__file__).resolve().parent.parent / "config.json"
    if relative.exists():
        return relative
    # Default: ~/.tripthink/config.json (may not exist yet — callers handle)
    return Path.home() / ".tripthink" / "config.json"

CONFIG_PATH = _find_config()
TRIPTHINK_HOME = str(CONFIG_PATH.parent)

def load_models():
    """Return configured models (excluding _-prefixed examples). Returns empty dict if none."""
    if not CONFIG_PATH.exists():
        return {}
    with open(CONFIG_PATH) as f:
        cfg = json.load(f)
    models = cfg.get("models", {})
    return {k: v for k, v in models.items() if not k.startswith("_")}

def require_models():
    """Load models or exit with helpful message."""
    if not CONFIG_PATH.exists():
        print(f"FATAL: {CONFIG_PATH} not found.", file=sys.stderr)
        print("Run 'tripthink.py list' to see expected path.", file=sys.stderr)
        print("Set TRIPTHINK_HOME to override.", file=sys.stderr)
        sys.exit(1)
    models = load_models()
    if not models:
        print(f"FATAL: no models configured in {CONFIG_PATH}", file=sys.stderr)
        print("Add model entries to the 'models' map. See README for examples.", file=sys.stderr)
        sys.exit(1)
    return models

def load_defaults():
    """Load global defaults from config (max_tokens, timeout, concurrency)."""
    if not CONFIG_PATH.exists():
        return {}
    with open(CONFIG_PATH) as f:
        cfg = json.load(f)
    return {
        "default_max_tokens": cfg.get("_default_max_tokens", 8192),
        "default_timeout": cfg.get("_timeout_seconds", 120),
        "default_concurrency": cfg.get("_concurrency", 6),
    }

def resolve_api_key(cfg: dict) -> str:
    """Return api_key from config, resolving api_key_env if set."""
    if "api_key_env" in cfg and cfg["api_key_env"]:
        key = os.environ.get(cfg["api_key_env"], "")
        if key:
            return key
    return cfg.get("api_key", "")

# ── Query ───────────────────────────────────────────────────────────
async def query_model(client: httpx.AsyncClient, key: str, cfg: dict,
                      prompt: str, timeout: int) -> dict:
    """Query one model. Dispatches on provider type for correct API format."""
    start = time.time()
    provider = cfg.get("provider", "anthropic")
    defaults = load_defaults()
    max_tok = cfg.get("max_tokens", defaults.get("default_max_tokens", 8192))
    api_key = resolve_api_key(cfg)
    endpoint = cfg["endpoint"]
    model_id = cfg["model"]

    try:
        if provider in ("openai", "openrouter"):
            # OpenAI Chat Completions format
            payload = {
                "model": model_id,
                "max_tokens": max_tok,
                "messages": [{"role": "user", "content": prompt}],
            }
            headers = {
                "Authorization": f"Bearer {api_key}",
                "Content-Type": "application/json",
            }
            # OpenRouter-specific headers
            if provider == "openrouter":
                headers["HTTP-Referer"] = "https://github.com/ZhijunLStudio/tripthink"
                headers["X-Title"] = "TripThink"

            resp = await client.post(
                endpoint, json=payload, headers=headers,
                timeout=httpx.Timeout(timeout),
            )
            elapsed_ms = (time.time() - start) * 1000

            if resp.status_code == 200:
                data = resp.json()
                text = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                usage = data.get("usage", {})
                return {
                    "model": key,
                    "model_name": cfg["name"],
                    "provider": provider,
                    "status": "ok",
                    "latency_ms": round(elapsed_ms),
                    "text": text,
                    "input_tokens": usage.get("prompt_tokens", 0),
                    "output_tokens": usage.get("completion_tokens", 0),
                }
            else:
                return {
                    "model": key,
                    "model_name": cfg["name"],
                    "provider": provider,
                    "status": "error",
                    "latency_ms": round(elapsed_ms),
                    "http_status": resp.status_code,
                    "error": resp.text[:500],
                }

        else:
            # Anthropic Messages format (default)
            payload = {
                "model": model_id,
                "max_tokens": max_tok,
                "messages": [{"role": "user", "content": prompt}],
            }
            headers = {
                "x-api-key": api_key,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json",
            }

            resp = await client.post(
                endpoint, json=payload, headers=headers,
                timeout=httpx.Timeout(timeout),
            )
            elapsed_ms = (time.time() - start) * 1000

            if resp.status_code == 200:
                data = resp.json()
                text = "".join(
                    b.get("text", "") for b in data.get("content", [])
                    if b.get("type") == "text"
                )
                usage = data.get("usage", {})
                return {
                    "model": key,
                    "model_name": cfg["name"],
                    "provider": provider,
                    "status": "ok",
                    "latency_ms": round(elapsed_ms),
                    "text": text,
                    "input_tokens": usage.get("input_tokens", 0),
                    "output_tokens": usage.get("output_tokens", 0),
                }
            else:
                return {
                    "model": key,
                    "model_name": cfg["name"],
                    "provider": provider,
                    "status": "error",
                    "latency_ms": round(elapsed_ms),
                    "http_status": resp.status_code,
                    "error": resp.text[:500],
                }

    except httpx.TimeoutException:
        return {
            "model": key, "model_name": cfg["name"], "provider": provider,
            "status": "timeout",
            "latency_ms": round((time.time() - start) * 1000),
        }
    except Exception as e:
        return {
            "model": key, "model_name": cfg["name"], "provider": provider,
            "status": "error",
            "latency_ms": round((time.time() - start) * 1000),
            "error": str(e)[:500],
        }

# ── Dispatch ────────────────────────────────────────────────────────
async def dispatch(models: dict, prompts_map: dict[str, str],
                   timeout: int, concurrency: int) -> list[dict]:
    """Dispatch prompts to models in parallel. Returns results in config order."""
    sem = asyncio.Semaphore(concurrency)
    async def bounded_query(client, key, cfg, prompt):
        async with sem:
            return await query_model(client, key, cfg, prompt, timeout)

    async with httpx.AsyncClient() as client:
        tasks = []
        for key, cfg in models.items():
            if key in prompts_map:
                tasks.append(bounded_query(client, key, cfg, prompts_map[key]))
        results = await asyncio.gather(*tasks)

    # Sort to match config order
    order = {k: i for i, k in enumerate(models)}
    results.sort(key=lambda r: order.get(r["model"], 999))
    return results

# ── CLI ─────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="TripThink Orchestrator")
    sub = parser.add_subparsers(dest="cmd", required=True)

    # dispatch
    disp = sub.add_parser("dispatch", help="Parallel dispatch to models")
    disp.add_argument("--prompt", help="Prompt text (same for all models)")
    disp.add_argument("--prompts", help="JSON file mapping model_key -> prompt (role-based)")
    disp.add_argument("--prompt-file", help="Read prompt from file (same for all)")
    disp.add_argument("--models", help="Comma-separated model keys (default: all)")
    disp.add_argument("--output", "-o", help="Write results to JSON file")
    disp.add_argument("--timeout", type=int, default=None, help="Per-model timeout in seconds")
    disp.add_argument("--concurrency", type=int, default=None, help="Max concurrent requests")

    # list
    ls = sub.add_parser("list", help="List configured models")
    ls.add_argument("--json", action="store_true", help="Output as JSON")

    # check
    sub.add_parser("check", help="Ping all models, report status")

    # path
    sub.add_parser("path", help="Show config path and TRIPTHINK_HOME")

    args = parser.parse_args()
    defaults = load_defaults()

    # ── path ───────────────────────────────────────────────────────
    if args.cmd == "path":
        print(f"TRIPTHINK_HOME={TRIPTHINK_HOME}")
        print(f"Config: {CONFIG_PATH}")
        return

    # ── list ───────────────────────────────────────────────────────
    if args.cmd == "list":
        print(f"Config: {CONFIG_PATH}")
        if not CONFIG_PATH.exists():
            print("No config file found. Run install.sh or create config.json manually.")
            return
        with open(CONFIG_PATH) as f:
            cfg = json.load(f)
        models = {k: v for k, v in cfg.get("models", {}).items() if not k.startswith("_")}
        if not models:
            print("No models configured. Add entries to the 'models' map.")
            print("Examples in config.json show setup for OpenRouter, Anthropic, and OpenAI providers.")
            return

        if args.json:
            info = {k: {"name": v["name"], "model": v["model"], "provider": v.get("provider", "anthropic")}
                    for k, v in models.items()}
            print(json.dumps(info, indent=2))
        else:
            for k, v in models.items():
                prov = v.get("provider", "anthropic")
                print(f"  {k:<14} → {v['name']} ({v['model']}) [{prov}]")
        return

    # ── check ─────────────────────────────────────────────────────
    if args.cmd == "check":
        try:
            models = require_models()
        except SystemExit:
            return

        timeout = defaults.get("default_timeout", 15)
        async def run_check():
            prompt = "Reply with exactly 'OK' and nothing else."
            results = await dispatch(models, {k: prompt for k in models}, timeout, 6)
            for r in results:
                emoji = "✅" if r["status"] == "ok" else "❌"
                extra = f"  {r.get('error', '')[:80]}" if r["status"] != "ok" else ""
                print(f"  {emoji} {r['model']:<14} {r['latency_ms']:>6}ms  "
                      f"{r.get('output_tokens', 0):>4}tok  {r.get('provider', '')}{extra}")
        asyncio.run(run_check())
        return

    # ── dispatch ──────────────────────────────────────────────────
    if args.cmd == "dispatch":
        try:
            models = require_models()
        except SystemExit:
            return
        if args.models:
            selected = set(m.strip() for m in args.models.split(","))
            models = {k: v for k, v in models.items() if k in selected}
        if not models:
            print("FATAL: no models matched filter", file=sys.stderr)
            sys.exit(1)

        # Resolve timeout / concurrency
        timeout = args.timeout if args.timeout else defaults.get("default_timeout", 120)
        concurrency = args.concurrency if args.concurrency else defaults.get("default_concurrency", 6)

        # Resolve prompts
        if args.prompts:
            with open(args.prompts) as f:
                prompts_map = json.load(f)
        elif args.prompt_file:
            prompt = Path(args.prompt_file).read_text()
            prompts_map = {k: prompt for k in models}
        elif args.prompt:
            prompts_map = {k: args.prompt for k in models}
        else:
            print("FATAL: need --prompt, --prompts, or --prompt-file", file=sys.stderr)
            sys.exit(1)

        # Run
        results = asyncio.run(dispatch(models, prompts_map, timeout, concurrency))

        # Output
        output = {
            "models_queried": len(results),
            "ok": sum(1 for r in results if r["status"] == "ok"),
            "errors": sum(1 for r in results if r["status"] != "ok"),
            "total_latency_ms": sum(r["latency_ms"] for r in results),
            "results": results,
        }

        if args.output:
            with open(args.output, "w") as f:
                json.dump(output, f, indent=2, ensure_ascii=False)
            print(f"Results written to {args.output}", file=sys.stderr)
        else:
            print(json.dumps(output, indent=2, ensure_ascii=False))

        # Summary to stderr
        ok_count = output["ok"]
        total = output["models_queried"]
        print(f"\n{ok_count}/{total} ok, {output['total_latency_ms']:.0f}ms total",
              file=sys.stderr)


if __name__ == "__main__":
    main()
