#!/usr/bin/env bash
set -e

BASE="$HOME/.trust-issues"
mkdir -p "$BASE"

if [[ -n "${PREFIX:-}" && -d "$PREFIX" ]]; then
    echo "[+] Termux detected"
    pkg update -y
    pkg install python ffmpeg mpv -y
    python -m pip install -U yt-dlp syncedlyrics
else
    echo "[+] Linux detected"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv ffmpeg mpv
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --needed --noconfirm python python-pip ffmpeg mpv
    else
        echo "Unsupported package manager. Install Python 3, mpv, ffmpeg, yt-dlp and syncedlyrics manually."
        exit 1
    fi

    if python3 -m venv "$BASE/venv" 2>/dev/null; then
        "$BASE/venv/bin/python" -m pip install -U pip yt-dlp syncedlyrics
    else
        python3 -m pip install --user -U yt-dlp syncedlyrics
    fi
fi

cp music.py "$BASE/music.py"

if [[ -n "${PREFIX:-}" && -d "$PREFIX/bin" ]]; then
    DEST="$PREFIX/bin/trust"
else
    mkdir -p "$HOME/.local/bin"
    DEST="$HOME/.local/bin/trust"
fi

cp trust "$DEST"
chmod +x "$DEST"

if [[ -n "${PREFIX:-}" && -d "$PREFIX/bin" ]]; then
    PYTHON_CMD="python"
else
    PYTHON_CMD="python3"
fi

# Keep the launcher portable between Termux and Linux.
sed -i "s#python3 \"\$HOME/.trust-issues/music.py\"#$PYTHON_CMD \"\$HOME/.trust-issues/music.py\"#" "$DEST"

if [[ ! -f "$BASE/trust_issues.lrc" ]]; then
    echo "[+] Downloading synced lyrics..."
    if [[ -x "$BASE/venv/bin/syncedlyrics" ]]; then
        "$BASE/venv/bin/syncedlyrics" "The Weeknd Trust Issues" --synced-only -o "$BASE/trust_issues.lrc" || true
    else
        syncedlyrics "The Weeknd Trust Issues" --synced-only -o "$BASE/trust_issues.lrc" || true
    fi
fi

echo
if [[ ! -f "$BASE/trust_issues.lrc" ]]; then
    echo "[!] Lyrics could not be downloaded automatically."
    echo "    Install syncedlyrics and run it again when online."
fi

echo "[+] Installed."
echo "    Run: trust issues"
echo "    Controls: p = pause/resume, q = quit"
