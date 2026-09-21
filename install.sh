#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[+] Installing Trust Issues..."

if [[ -n "${PREFIX:-}" && -d "$PREFIX" ]]; then
    echo "[+] Termux detected"

    pkg update -y
    pkg install -y python ffmpeg mpv curl

    if ! command -v deno >/dev/null 2>&1; then
        echo "[+] Installing Deno..."
        pkg install -y deno
    fi

    python -m pip install -U yt-dlp syncedlyrics

    PYTHON_CMD="python"
    SYNCEDLYRICS_CMD="syncedlyrics"
    DEST="$PREFIX/bin/trust"

else
    echo "[+] Linux detected"

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y \
            python3 \
            python3-pip \
            python3-venv \
            ffmpeg \
            mpv \
            curl \
            unzip

    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --needed --noconfirm \
            python \
            python-pip \
            ffmpeg \
            mpv \
            curl \
            unzip
    else
        echo "Unsupported package manager."
        exit 1
    fi

    if ! command -v deno >/dev/null 2>&1; then
        echo "[+] Installing Deno..."

        curl -fsSL https://deno.land/install.sh | sh

        export PATH="$HOME/.deno/bin:$PATH"
    fi

    python3 -m venv "$SCRIPT_DIR/venv"

    "$SCRIPT_DIR/venv/bin/python" -m pip install -U pip
    "$SCRIPT_DIR/venv/bin/python" -m pip install -U yt-dlp syncedlyrics

    PYTHON_CMD="$SCRIPT_DIR/venv/bin/python"
    SYNCEDLYRICS_CMD="$SCRIPT_DIR/venv/bin/syncedlyrics"

    mkdir -p "$HOME/.local/bin"

    DEST="$HOME/.local/bin/trust"

    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    if ! grep -q 'export PATH="$HOME/.deno/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.deno/bin:$PATH"' >> "$HOME/.bashrc"
    fi

    export PATH="$SCRIPT_DIR/venv/bin:$HOME/.local/bin:$HOME/.deno/bin:$PATH"
fi

if [[ ! -f "$SCRIPT_DIR/trust_issues.lrc" ]]; then
    echo "[+] Downloading synced lyrics..."

    "$SYNCEDLYRICS_CMD" \
        "The Weeknd Trust Issues" \
        --synced-only \
        -o "$SCRIPT_DIR/trust_issues.lrc" || true
fi

cat > "$DEST" <<EOF
#!/usr/bin/env bash

SCRIPT_DIR="$SCRIPT_DIR"

export PATH="$SCRIPT_DIR/venv/bin:\$HOME/.local/bin:\$HOME/.deno/bin:\$PATH"

clear
stty -echo
printf '\033[?25l'

cleanup() {
    stty echo 2>/dev/null || true
    printf '\033[?25h'
    clear
}

trap cleanup EXIT INT TERM

"$PYTHON_CMD" "\$SCRIPT_DIR/music.py"
EOF

chmod +x "$DEST"

echo
echo "[+] Installation complete."
echo
echo "    Run:"
echo "    trust issues"
echo
echo "    Controls:"
echo "    p = pause/resume"
echo "    q = quit"
