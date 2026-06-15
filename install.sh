#!/bin/bash
set -e

# ================================================================
# TripThink v2 — Multi-Platform One-Click Install
# Installs shared runtime + 3 skills to your chosen AI platforms.
# Compatible with bash 3.2+ (macOS default) and zsh.
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

# ── Platform detection (bash 3.2 compatible — no associative arrays) ──
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Detecting AI platforms..."
echo ""

PLATFORM_KEYS=""
PLATFORM_DIRS=""
PLATFORM_NAMES=""

add_platform() {
    local key="$1" dir="$2" name="$3"
    PLATFORM_KEYS="$PLATFORM_KEYS|$key"
    PLATFORM_DIRS="$PLATFORM_DIRS|$dir"
    PLATFORM_NAMES="$PLATFORM_NAMES|$name"
}

get_dir() {
    local target="$1"
    local old_ifs="$IFS"
    IFS='|'
    local keys=($PLATFORM_KEYS)
    local dirs=($PLATFORM_DIRS)
    IFS="$old_ifs"
    local i=0
    for k in "${keys[@]}"; do
        if [ "$k" = "$target" ]; then
            echo "${dirs[$i]}"
            return
        fi
        i=$((i + 1))
    done
}

get_name() {
    local target="$1"
    local old_ifs="$IFS"
    IFS='|'
    local keys=($PLATFORM_KEYS)
    local names=($PLATFORM_NAMES)
    IFS="$old_ifs"
    local i=0
    for k in "${keys[@]}"; do
        if [ "$k" = "$target" ]; then
            echo "${names[$i]}"
            return
        fi
        i=$((i + 1))
    done
}

detect_platforms() {
    [ -d "$HOME/.claude" ]          && add_platform "claude-code" "$HOME/.claude/skills"         "Claude Code"
    [ -d "$HOME/.agents" ]          && add_platform "codex"      "$HOME/.agents/skills"           "Codex CLI"
    [ -d "$HOME/.config/opencode" ] && add_platform "opencode"   "$HOME/.config/opencode/skills"  "OpenCode"
    [ -d "$HOME/.gemini" ]          && add_platform "gemini"     "$HOME/.gemini/skills"           "Gemini CLI"
    [ -d "$HOME/.copilot" ]         && add_platform "copilot"    "$HOME/.copilot/skills"          "GitHub Copilot"
    [ -d "$HOME/.kiro" ]            && add_platform "kiro"       "$HOME/.kiro/skills"             "Kiro"
    [ -d "$HOME/.config/goose" ]    && add_platform "goose"      "$HOME/.config/goose/skills"     "Goose"
    [ -d "$HOME/.roo" ]             && add_platform "roo"        "$HOME/.roo/skills"              "Roo Code"
    [ -d "$HOME/.cline" ]           && add_platform "cline"      "$HOME/.cline/skills"            "Cline"
    [ -d "$HOME/.kilocode" ]        && add_platform "kilocode"   "$HOME/.kilocode/skills"         "Kilo Code"
    [ -d "$HOME/.factory" ]         && add_platform "factory"    "$HOME/.factory/skills"          "Factory Droid"
    [ -d "$PWD/.cursor" ]           && add_platform "cursor"     "$PWD/.cursor/skills"            "Cursor (project-local)"
    [ -d "$PWD/.windsurf" ]         && add_platform "windsurf"   "$PWD/.windsurf/rules"           "Windsurf (project-local)"
    [ -d "$PWD/.trae" ]             && add_platform "trae"       "$PWD/.trae/rules"               "Trae (project-local)"
    return 0  # always succeed — last [ -d ... ] may return 1 with set -e
}

detect_platforms

# Strip leading | from the strings
PLATFORM_KEYS="${PLATFORM_KEYS#|}"
PLATFORM_DIRS="${PLATFORM_DIRS#|}"
PLATFORM_NAMES="${PLATFORM_NAMES#|}"

FOUND=0
PLATFORM_LIST=(); IFS='|' read -ra PLATFORM_LIST <<< "$PLATFORM_KEYS"
for key in "${PLATFORM_LIST[@]}"; do
    echo "  ✅ $(get_name "$key") → $(get_dir "$key")"
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

for key in "${PLATFORM_LIST[@]}"; do
    echo "  $COUNT) $(get_name "$key")"
    COUNT=$((COUNT + 1))
done

echo ""
read -p "Choice [0]: " CHOICES
CHOICES=${CHOICES:-0}

# Resolve choices
SELECTED_KEYS=""
if [ "$CHOICES" = "a" ] || [ "$CHOICES" = "A" ]; then
    SELECTED_KEYS="universal $PLATFORM_KEYS"
else
    for num in $CHOICES; do
        if [ "$num" = "0" ]; then
            SELECTED_KEYS="$SELECTED_KEYS universal"
        else
            local_idx=1
            for key in "${PLATFORM_LIST[@]}"; do
                if [ "$num" = "$local_idx" ]; then
                    SELECTED_KEYS="$SELECTED_KEYS $key"
                fi
                local_idx=$((local_idx + 1))
            done
        fi
    done
    if [ -z "$SELECTED_KEYS" ]; then
        SELECTED_KEYS="universal"
    fi
fi

echo ""
echo "Installing to:"
for key in $SELECTED_KEYS; do
    if [ "$key" = "universal" ]; then
        echo "  • Universal (~/.tripthink/)"
    else
        echo "  • $(get_name "$key")"
    fi
done

# ── Check for existing install ──────────────────────────────────
existing=""
[ -d "$SHARED_DIR" ] && existing="$existing $SHARED_DIR"

for key in $SELECTED_KEYS; do
    if [ "$key" = "universal" ]; then continue; fi
    for sd in "${SKILL_DIRS[@]}"; do
        dir="$(get_dir "$key")/$sd"
        [ -d "$dir" ] && existing="$existing $dir"
    done
done

# Trim leading space
existing=$(echo "$existing" | xargs)

if [ -n "$existing" ]; then
    echo ""
    echo "⚠️  Existing installs:"
    for d in $existing; do
        echo "  $d"
    done
    read -p "Overwrite? [y/N] " yn
    case $yn in
        [Yy]* )
            for d in $existing; do rm -rf "$d"; done
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

cp "$SCRIPT_DIR/scripts/tripthink.py" "$SHARED_DIR/scripts/tripthink.py"
cp "$SCRIPT_DIR/scripts/query.py" "$SHARED_DIR/scripts/query.py"
chmod +x "$SHARED_DIR/scripts/tripthink.py" "$SHARED_DIR/scripts/query.py"
echo "  ✅ scripts/tripthink.py"
echo "  ✅ scripts/query.py"

if [ ! -f "$SHARED_DIR/config.json" ]; then
    cp "$SCRIPT_DIR/config.json" "$SHARED_DIR/config.json"
    echo "  ✅ config.json (template)"
else
    echo "  ⏭️  config.json (existing, kept)"
fi

# ── Install skills to each target platform ──────────────────────
for key in $SELECTED_KEYS; do
    if [ "$key" = "universal" ]; then
        TARGET="$SHARED_DIR"
        echo ""
        echo "  📁 Universal → $SHARED_DIR"
    else
        TARGET="$(get_dir "$key")"
        echo ""
        echo "  📁 $(get_name "$key") → $TARGET"
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

# ── Shell env config ────────────────────────────────────────────
SHELL_RC=""
[ -f "$HOME/.zshrc" ] && SHELL_RC="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && SHELL_RC="$HOME/.bashrc"

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
    echo "Choose 3 models from OpenRouter. Format: provider/model-name"
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

    export TRIPTHINK_OPENROUTER_KEY="$OR_KEY"
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
    echo "Configure 3 models. For each, provide name, provider, endpoint, model ID, key."
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
        COMMA=""
        if [ $i -lt 3 ]; then COMMA=","; fi
        MODELS_JSON="${MODELS_JSON}    \"${KEY_NAME}\": {
      \"name\": \"${M_NAME:-Model $i}\",
      \"provider\": \"${M_PROV}\",
      \"endpoint\": \"${M_ENDP}\",
      \"api_key\": \"${M_KEY}\",
      \"model\": \"${M_MODEL}\",
      \"max_tokens\": ${M_MAX}
    }${COMMA}
"
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

for key in $SELECTED_KEYS; do
    if [ "$key" = "universal" ]; then
        TARGET="$SHARED_DIR"
    else
        TARGET="$(get_dir "$key")"
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
echo "  💡 Usage (Claude Code):"
echo "     /tripthink-deep <question>"
echo "     /tripthink-debate <proposition>"
echo "     /tripthink-research <research question>"
echo ""
echo "  💡 Usage (shell / any tool):"
echo "     python3 \$TRIPTHINK_HOME/scripts/tripthink.py dispatch --prompt \"Your question\""
echo ""
echo "  ⚙️  Config: $CONFIG_FILE"
echo "  📖 Guide:  https://github.com/ZhijunLStudio/TripThink#readme"
echo ""
echo "  Restart your AI tool to load the skills."
