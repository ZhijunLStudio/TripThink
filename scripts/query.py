#!/usr/bin/env python3
"""
TripThink Query — Query a single LLM via Anthropic, OpenAI, or OpenRouter API.
All model configuration (endpoint, api_key, model name, provider, max_tokens)
is read from config.json — the single source of truth.

Config path discovery (in order):
  1. $TRIPTHINK_HOME/config.json
  2. ~/.tripthink/config.json
  3. ../config.json (relative to this script)

Usage: python3 query.py <model_key> "<prompt>"
Output: plain text (model response) to stdout; metadata to stderr
"""

import json
import os
import sys
from pathlib import Path

try:
    import httpx
except ImportError:
    print("Error: 'httpx' package not found.", file=sys.stderr)
    print(f"Install: {sys.executable} -m pip install httpx", file=sys.stderr)
    sys.exit(1)

# ── Config path discovery ────────────────────────────────────────────
def _find_config() -> Path:
    if "TRIPTHINK_HOME" in os.environ:
        return Path(os.environ["TRIPTHINK_HOME"]) / "config.json"
    home = Path.home() / ".tripthink" / "config.json"
    if home.exists():
        return home
    relative = Path(__file__).resolve().parent.parent / "config.json"
    if relative.exists():
        return relative
    return Path.home() / ".tripthink" / "config.json"

CONFIG_PATH = _find_config()
TRIPTHINK_HOME = str(CONFIG_PATH.parent)

def load_models():
    if not CONFIG_PATH.exists():
        print(f"Error: {CONFIG_PATH} not found.", file=sys.stderr)
        print("Run install.sh first or set TRIPTHINK_HOME.", file=sys.stderr)
        sys.exit(1)
    with open(CONFIG_PATH) as f:
        cfg = json.load(f)
    models = cfg.get("models", {})
    models = {k: v for k, v in models.items() if not k.startswith("_")}
    if not models:
        print(f"Error: no models configured in {CONFIG_PATH}.", file=sys.stderr)
        print("Add model entries to the 'models' map. See README for examples.", file=sys.stderr)
        sys.exit(1)
    return models

def load_defaults():
    if not CONFIG_PATH.exists():
        return {}
    with open(CONFIG_PATH) as f:
        cfg = json.load(f)
    return {
        "default_max_tokens": cfg.get("_default_max_tokens", 8192),
        "default_timeout": cfg.get("_timeout_seconds", 120),
    }

def resolve_api_key(cfg: dict) -> str:
    if "api_key_env" in cfg and cfg["api_key_env"]:
        key = os.environ.get(cfg["api_key_env"], "")
        if key:
            return key
    return cfg.get("api_key", "")


def main():
    if len(sys.argv) < 3:
        print("Usage: query.py <model_key> <prompt>", file=sys.stderr)
        try:
            models = load_models()
            print(f"Available: {', '.join(models.keys())}", file=sys.stderr)
        except SystemExit:
            pass
        sys.exit(1)

    model_key = sys.argv[1].lower()
    prompt = sys.argv[2]

    models = load_models()

    if model_key not in models:
        print(f"Unknown model: {model_key}. Available: {', '.join(models.keys())}", file=sys.stderr)
        sys.exit(1)

    cfg = models[model_key]
    defaults = load_defaults()
    provider = cfg.get("provider", "anthropic")
    max_tok = cfg.get("max_tokens", defaults.get("default_max_tokens", 8192))
    api_key = resolve_api_key(cfg)
    endpoint = cfg["endpoint"]
    model_id = cfg["model"]
    timeout = defaults.get("default_timeout", 120)

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
            if provider == "openrouter":
                headers["HTTP-Referer"] = "https://github.com/ZhijunLStudio/tripthink"
                headers["X-Title"] = "TripThink"

            resp = httpx.post(endpoint, json=payload, headers=headers,
                              timeout=httpx.Timeout(timeout))

            if resp.status_code == 200:
                data = resp.json()
                text = data.get("choices", [{}])[0].get("message", {}).get("content", "")
                print(text)
                usage = data.get("usage", {})
                print(
                    f"\n[{cfg['name']} | {usage.get('completion_tokens', 0)} tok | "
                    f"model: {data.get('model', model_id)} | {provider}]",
                    file=sys.stderr,
                )
            else:
                print(f"API Error ({resp.status_code}): {resp.text[:500]}", file=sys.stderr)
                sys.exit(1)

        else:
            # Anthropic Messages format
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

            resp = httpx.post(endpoint, json=payload, headers=headers,
                              timeout=httpx.Timeout(timeout))

            if resp.status_code == 200:
                data = resp.json()
                for block in data.get("content", []):
                    if block.get("type") == "text":
                        print(block["text"])
                usage = data.get("usage", {})
                print(
                    f"\n[{cfg['name']} | {usage.get('output_tokens', 0)} tok | "
                    f"model: {data.get('model', '')}]",
                    file=sys.stderr,
                )
            else:
                print(f"API Error ({resp.status_code}): {resp.text[:500]}", file=sys.stderr)
                sys.exit(1)

    except httpx.TimeoutException:
        print(f"Error: request timed out after {timeout}s", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
