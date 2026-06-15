#!/bin/bash
set -e

# ================================================================
# TripThink v2 — Multi-Platform One-Click Install
# Installs shared runtime + 3 skills to your chosen AI platforms.
# ================================================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SHARED_DIR="$HOME/.tripthink"
SKILL_DIRS=(tripthink-deep tripthink-debate tripthink-research)

# ── Banner ──────────────────────────────────────────────────────
echo "========================================"
echo "  TripThink — Triple-Model Deliberation"
echo "  v2.0 — Multi-Platform Installer"
echo "========================================"
echo ""

# ── Pre-flight checks ───────────────────────────────────────────
for cmd in python3; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "❌ Missing requirement: $cmd"
        exit 1
    fi
done

if ! python3 -c "import httpx" 2>/dev/null; then
    echo "❌ Python package 'httpx' not found."
    read -p "Auto-install? [Y/n] " yn
    case $yn in
        [Nn]* ) echo "  Install manually: python3 -m pip install httpx"; exit 1 ;;
        * )
            echo "  Installing httpx..."
            python3 -m pip install httpx 2>/dev/null || python3 -m pip install --user httpx 2>/dev/null || {
                echo "  ❌ Failed. Install manually: python3 -m pip install httpx"
                exit 1
            }
            echo "  ✅ httpx installed"
            ;;
    esac
fi

# ── Platform detection ──────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Detecting AI platforms..."
echo ""

declare -A PLATFORM_DIRS
declare -A PLATFORM_NAMES

# Map of platform name → skills directory
detect_platforms() {
    [ -d "$HOME/.claude" ]          && PLATFORM_DIRS["claude-code"]="$HOME/.claude/skills"         && PLATFORM_NAMES["claude-code"]="Claude Code"
    [ -d "$HOME/.agents" ]          && PLATFORM_DIRS["codex"]="$HOME/.agents/skills"                && PLATFORM_NAMES["codex"]="Codex CLI"
    [ -d "$HOME/.config/opencode" ] && PLATFORM_DIRS["opencode"]="$HOME/.config/opencode/skills"    && PLATFORM_NAMES["opencode"]="OpenCode"
    [ -d "$HOME/.gemini" ]          && PLATFORM_DIRS["gemini"]="$HOME/.gemini/skills"               && PLATFORM_NAMES["gemini"]="Gemini CLI"
    [ -d "$HOME/.copilot" ]         && PLATFORM_DIRS["copilot"]="$HOME/.copilot/skills"             && PLATFORM_NAMES["copilot"]="GitHub Copilot"
    [ -d "$HOME/.kiro" ]            && PLATFORM_DIRS["kiro"]="$HOME/.kiro/skills"                   && PLATFORM_NAMES["kiro"]="Kiro"
    [ -d "$HOME/.config/goose" ]    && PLATFORM_DIRS["goose"]="$HOME/.config/goose/skills"          && PLATFORM_NAMES["goose"]="Goose"
    [ -d "$HOME/.roo" ]             && PLATFORM_DIRS["roo"]="$HOME/.roo/skills"                     && PLATFORM_NAMES["roo"]="Roo Code"
    [ -d "$HOME/.cline" ]           && PLATFORM_DIRS["cline"]="$HOME/.cline/skills"                 && PLATFORM_NAMES["cline"]="Cline"
    [ -d "$HOME/.kilocode" ]        && PLATFORM_DIRS["kilocode"]="$HOME/.kilocode/skills"           && PLATFORM_NAMES["kilocode"]="Kilo Code"
    [ -d "$HOME/.factory" ]         && PLATFORM_DIRS["factory"]="$HOME/.factory/skills"             && PLATFORM_NAMES["factory"]="Factory Droid"
    # Project-local: only if running inside a project with .cursor or .windsurf
    [ -d "$PWD/.cursor" ]           && PLATFORM_DIRS["cursor"]="$PWD/.cursor/skills"                && PLATFORM_NAMES["cursor"]="Cursor (project-local)"
    [ -d "$PWD/.windsurf" ]         && PLATFORM_DIRS["windsurf"]="$PWD/.windsurf/rules"             && PLATFORM_NAMES["windsurf"]="Windsurf (project-local)"
    [ -d "$PWD/.trae" ]             && PLATFORM_DIRS["trae"]="$PWD/.trae/rules"                     && PLATFORM_NAMES["trae"]="Trae (project-local)"
}

detect_platforms

FOUND=0
for key in "${!PLATFORM_DIRS[@]}"; do
    echo "  ✅ ${PLATFORM_NAMES[$key]} → ${PLATFORM_DIRS[$key]}"
    FOUND=$((FOUND + 1))
done

if [ $FOUND -eq 0 ]; then
    echo "  ℹ️  No AI coding tools detected."
    echo "     TripThink will install to ~/.tripthink/ (universal)."
    echo "     The scripts work from any shell, any platform."
fi
echo ""

# ── Platform selection ──────────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Install targets (enter numbers separated by space, or 'a' for all)"
echo ""

# Always include universal
echo "  0) Universal (~/.tripthink/) — works everywhere"
COUNT=1
declare -A MENU_MAP
MENU_MAP[0]="universal"

for key in "${!PLATFORM_DIRS[@]}"; do
    echo "  $COUNT) ${PLATFORM_NAMES[$key]}"
    MENU_MAP[$COUNT]="$key"
    COUNT=$((COUNT + 1))
done

echo ""
read -p "Choice [0]: " CHOICES
CHOICES=${CHOICES:-0}

if [ "$CHOICES" = "a" ] || [ "$CHOICES" = "A" ]; then
    SELECTED_KEYS=("universal")
    for key in "${!PLATFORM_DIRS[@]}"; do
        SELECTED_KEYS+=("$key")
    done
else
    SELECTED_KEYS=()
    for num in $CHOICES; do
        if [ -n "${MENU_MAP[$num]}" ]; then
            SELECTED_KEYS+=("${MENU_MAP[$num]}")
        fi
    done
    if [ ${#SELECTED_KEYS[@]} -eq 0 ]; then
        SELECTED_KEYS=("universal")
    fi
fi

echo ""
echo "Installing to:"
for key in "${SELECTED_KEYS[@]}"; do
    if [ "$key" = "universal" ]; then
        echo "  • Universal (~/.tripthink/)"
    else
        echo "  • ${PLATFORM_NAMES[$key]}"
    fi
done

# ── Check for existing install ──────────────────────────────────
existing=()
for dir in "$SHARED_DIR"; do
    [ -d "$dir" ] && existing+=("$dir")
done
for key in "${SELECTED_KEYS[@]}"; do
    if [ "$key" = "universal" ]; then continue; fi
    for sd in "${SKILL_DIRS[@]}"; do
        dir="${PLATFORM_DIRS[$key]}/$sd"
        [ -d "$dir" ] && existing+=("$dir")
    done
done

if [ ${#existing[@]} -gt 0 ]; then
    echo ""
    echo "⚠️  Existing installs:"
    printf '  %s\n' "${existing[@]}"
    read -p "Overwrite? [y/N] " yn
    case $yn in
        [Yy]* )
            for dir in "${existing[@]}"; do rm -rf "$dir"; done
            ;;
        * ) echo "Aborted."; exit 0 ;;
    esac
fi

# ── Install shared runtime ──────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📁 Shared runtime → $SHARED_DIR"
echo ""

mkdir -p "$SHARED_DIR/scripts"

# Copy scripts
cp "$SCRIPT_DIR/scripts/tripthink.py" "$SHARED_DIR/scripts/tripthink.py"
cp "$SCRIPT_DIR/scripts/query.py" "$SHARED_DIR/scripts/query.py"
chmod +x "$SHARED_DIR/scripts/tripthink.py" "$SHARED_DIR/scripts/query.py"
echo "  ✅ scripts/tripthink.py"
echo "  ✅ scripts/query.py"

# Copy config template (don't overwrite existing user config)
if [ ! -f "$SHARED_DIR/config.json" ]; then
    cp "$SCRIPT_DIR/config.json" "$SHARED_DIR/config.json"
    echo "  ✅ config.json (template)"
else
    echo "  ⏭️  config.json (existing, kept)"
fi

# ── Install skills to each target platform ──────────────────────
for key in "${SELECTED_KEYS[@]}"; do
    if [ "$key" = "universal" ]; then
        TARGET="$SHARED_DIR"
        echo ""
        echo "  📁 Universal install → $SHARED_DIR"
    else
        TARGET="${PLATFORM_DIRS[$key]}"
        echo ""
        echo "  📁 ${PLATFORM_NAMES[$key]} → $TARGET"
    fi

    mkdir -p "$TARGET"

    for skill in "${SKILL_DIRS[@]}"; do
        SRC="$SCRIPT_DIR/$skill"
        DST="$TARGET/$skill"

        if [ ! -d "$SRC" ]; then
            echo "    ⚠️  Source not found: $SRC — skipping"
            continue
        fi

        rm -rf "$DST"
        cp -r "$SRC" "$DST"
        echo "    ✅ /$skill"
    done
done

# ── Config: Add universal path note to SKILL.md files ───────────
# The SKILL.md files reference $TRIPTHINK_HOME — set up the env var hint
SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then SHELL_RC="$HOME/.zshrc"; fi
if [ -f "$HOME/.bashrc" ]; then SHELL_RC="$HOME/.bashrc"; fi

if [ -n "$SHELL_RC" ] && ! grep -q "TRIPTHINK_HOME" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# TripThink — multi-model deliberation" >> "$SHELL_RC"
    echo "export TRIPTHINK_HOME=\"$SHARED_DIR\"" >> "$SHELL_RC"
    echo "  ✅ Added TRIPTHINK_HOME to $(basename $SHELL_RC)"
fi

# ── Interactive model setup ─────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🔑 Model Configuration"
echo ""
echo "TripThink needs 3 models to deliberate. You can use:"
echo ""
echo "  A) OpenRouter — one API key, access 300+ models"
echo "     Get key: https://openrouter.ai/keys"
echo ""
echo "  B) Individual APIs — separate keys per model/provider"
echo "     E.g., DeepSeek + GLM + MiniMax, or any Anthropic/OpenAI-compatible"
echo ""
read -p "Use OpenRouter? [A/b] " PROVIDER_CHOICE
PROVIDER_CHOICE=${PROVIDER_CHOICE:-A}

CONFIG_FILE="$SHARED_DIR/config.json"

generate_openrouter_config() {
    read -p "OpenRouter API key: " OR_KEY
    if [ -z "$OR_KEY" ]; then
        echo "  ⚠️  No key provided. Edit $CONFIG_FILE manually."
        return
    fi

    echo ""
    echo "Choose 3 models from OpenRouter. Use the format: provider/model-name"
    echo "Examples: anthropic/claude-opus-4-8, google/gemini-2.5-pro, openai/gpt-5"
    echo "Browse: https://openrouter.ai/models"
    echo ""

    read -p "Model 1 name (display): " M1_NAME
    read -p "Model 1 ID (e.g. anthropic/claude-opus-4-8): " M1_ID
    read -p "Model 2 name (display): " M2_NAME
    read -p "Model 2 ID: " M2_ID
    read -p "Model 3 name (display): " M3_NAME
    read -p "Model 3 ID: " M3_ID

    cat > "$CONFIG_FILE" << EOF
{
  "_comment": "TripThink config — 3 models via OpenRouter",
  "_default_max_tokens": 81920,
  "_timeout_seconds": 120,
  "_concurrency": 6,
  "models": {
    "model_a": {
      "name": "${M1_NAME:-Model A}",
      "provider": "openrouter",
      "endpoint": "https://openrouter.ai/api/v1/chat/completions",
      "api_key_env": "TRIPTHINK_OPENROUTER_KEY",
      "model": "${M1_ID:-anthropic/claude-opus-4-8}",
      "max_tokens": 81920
    },
    "model_b": {
      "name": "${M2_NAME:-Model B}",
      "provider": "openrouter",
      "endpoint": "https://openrouter.ai/api/v1/chat/completions",
      "api_key_env": "TRIPTHINK_OPENROUTER_KEY",
      "model": "${M2_ID:-google/gemini-2.5-pro}",
      "max_tokens": 81920
    },
    "model_c": {
      "name": "${M3_NAME:-Model C}",
      "provider": "openrouter",
      "endpoint": "https://openrouter.ai/api/v1/chat/completions",
      "api_key_env": "TRIPTHINK_OPENROUTER_KEY",
      "model": "${M3_ID:-openai/gpt-5}",
      "max_tokens": 81920
    }
  }
}
EOF

    # Export the env var for this session
    export TRIPTHINK_OPENROUTER_KEY="$OR_KEY"

    # Add to shell rc
    if [ -n "$SHELL_RC" ]; then
        if ! grep -q "TRIPTHINK_OPENROUTER_KEY" "$SHELL_RC" 2>/dev/null; then
            echo "export TRIPTHINK_OPENROUTER_KEY=\"$OR_KEY\"" >> "$SHELL_RC"
        fi
    fi

    echo ""
    echo "  ✅ OpenRouter config written to $CONFIG_FILE"
    echo "  ✅ Key saved to $(basename $SHELL_RC) as TRIPTHINK_OPENROUTER_KEY"
}

generate_individual_config() {
    echo ""
    echo "Configure 3 models. For each, provide:"
    echo "  - Display name (any label)"
    echo "  - Provider type: anthropic | openai"
    echo "  - API endpoint URL"
    echo "  - Model ID (the model string sent to API)"
    echo "  - API key"
    echo ""

    MODELS_JSON=""
    for i in 1 2 3; do
        echo "── Model $i ──"
        read -p "  Display name: " M_NAME
        read -p "  Provider [anthropic]: " M_PROV
        M_PROV=${M_PROV:-anthropic}
        read -p "  Endpoint URL: " M_ENDP
        read -p "  Model ID: " M_MODEL
        read -p "  API key: " M_KEY
        read -p "  Max tokens [81920]: " M_MAX
        M_MAX=${M_MAX:-81920}
        echo ""

        KEY_NAME="model_$(echo $i | tr '1-3' 'a-c')"
        # Use api_key_env for consistency, but fall back to inline for simplicity
        if [ -n "$M_KEY" ]; then
            MODELS_JSON+=$(cat << INNER
    "${KEY_NAME}": {
      "name": "${M_NAME:-Model $i}",
      "provider": "${M_PROV}",
      "endpoint": "${M_ENDP}",
      "api_key": "${M_KEY}",
      "model": "${M_MODEL}",
      "max_tokens": ${M_MAX}
    }$([ $i -lt 3 ] && echo ",")
INNER
)
            MODELS_JSON+=$'\n'
        fi
    done

    cat > "$CONFIG_FILE" << EOF
{
  "_comment": "TripThink config — individually configured models",
  "_default_max_tokens": 81920,
  "_timeout_seconds": 120,
  "_concurrency": 6,
  "models": {
${MODELS_JSON}  }
}
EOF

    echo "  ✅ Config written to $CONFIG_FILE"
}

case $PROVIDER_CHOICE in
    [Bb]*|[Nn]*) generate_individual_config ;;
    *) generate_openrouter_config ;;
esac

# ── Verify ──────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Verification"
echo ""

verify_file() {
    if [ -f "$1" ] || [ -d "$1" ]; then
        echo "  ✅ $1"
    else
        echo "  ❌ MISSING: $1"
    fi
}

verify_file "$SHARED_DIR/config.json"
verify_file "$SHARED_DIR/scripts/tripthink.py"
verify_file "$SHARED_DIR/scripts/query.py"

for key in "${SELECTED_KEYS[@]}"; do
    if [ "$key" = "universal" ]; then
        TARGET="$SHARED_DIR"
    else
        TARGET="${PLATFORM_DIRS[$key]}"
    fi
    for skill in "${SKILL_DIRS[@]}"; do
        verify_file "$TARGET/$skill/SKILL.md"
    done
done

# ── Done ────────────────────────────────────────────────────────
echo ""
echo "========================================"
echo "  ✅ TripThink v2 installed!"
echo "========================================"
echo ""
echo "  TRIPTHINK_HOME = $SHARED_DIR"
echo ""
echo "  🚀 Quick test:"
echo "     python3 $SHARED_DIR/scripts/tripthink.py list"
echo "     python3 $SHARED_DIR/scripts/tripthink.py check"
echo ""
echo "  💡 Usage with Claude Code:"
echo "     /tripthink-deep <question>"
echo "     /tripthink-debate <proposition>"
echo "     /tripthink-research <research question>"
echo ""
echo "  💡 Usage from other tools (shell):"
echo "     python3 \$TRIPTHINK_HOME/scripts/tripthink.py dispatch --prompt \"Your question\""
echo ""
echo "  ⚙️  Config: $CONFIG_FILE"
echo "  📖 Guide:  https://github.com/ZhijunLStudio/tripthink#readme"
echo ""
echo "  Restart your AI tool to load the skills."
