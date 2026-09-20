#!/usr/bin/env bash
set -e

BASE="$HOME/.trust-issues"
mkdir -p "$BASE"

if [[ -n "${PREFIX:-}" && -d "$PREFIX" ]]; then
    echo "[+] Termux detected"

    pkg update -y
    pkg install -y python ffmpeg mpv

    python -m pip install -U yt-dlp syncedlyrics

    PYTHON_CMD="python"
    DEST="$PREFIX/bin/trust"
    SYNCEDLYRICS_CMD="syncedlyrics"
else
    echo "[+] Linux detected"

    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv ffmpeg mpv
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --needed --noconfirm python python-pip ffmpeg mpv
    else
        echo "Unsupported package manager."
        exit 1
    fi

    python3 -m venv "$BASE/venv"
    "$BASE/venv/bin/python" -m pip install -U pip yt-dlp syncedlyrics

    PYTHON_CMD="$BASE/venv/bin/python"

    mkdir -p "$HOME/.local/bin"
    DEST="$HOME/.local/bin/trust"
    SYNCEDLYRICS_CMD="$BASE/venv/bin/syncedlyrics"
fi

cp music.py "$BASE/music.py"

if [[ ! -f "$BASE/trust_issues.lrc" ]]; then
    echo "[+] Downloading synced lyrics..."

    "$SYNCEDLYRICS_CMD" \
        "The Weeknd Trust Issues" \
        --synced-only \
        -o "$BASE/trust_issues.lrc" || true
fi

cat > "$DEST" <<EOF
#!/usr/bin/env bash

clear
stty -echo
printf '\033[?25l'

cleanup() {
    stty echo 2>/dev/null || true
    printf '\033[?25h'
    clear
}

trap cleanup EXIT INT TERM

"$PYTHON_CMD" "$BASE/music.py"
EOF

chmod +x "$DEST"

echo
echo "[+] Installed."
echo "    Run: trust issues"
echo "    Controls: p = pause/resume, q = quit"
