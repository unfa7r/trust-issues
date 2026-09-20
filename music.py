import json
import math
import os
import re
import select
import shutil
import socket
import subprocess
import sys
import termios
import textwrap
import threading
import time
import tty

BASE = os.path.dirname(os.path.abspath(__file__))
LRC = os.path.join(BASE, "trust_issues.lrc")
TMP = os.environ.get("TMPDIR", "/tmp")
SOCK = os.path.join(TMP, "trust_issues_mpv.sock")
LYRIC_OFFSET = 4

RESET = "\033[0m"
DIM = "\033[2m"
BOLD = "\033[1m"
RED = "\033[91m"

lyrics = []
running = True
position = 0
last_index = -1


def load_lyrics():
    if not os.path.exists(LRC):
        return
    with open(LRC, encoding="utf-8") as f:
        for line in f:
            if not line.startswith("["):
                continue
            try:
                tag, text = line.split("]", 1)
                tag = tag[1:]
                m, s = tag.split(":", 1)
                lyrics.append((int(m) * 60 + float(s), text.strip()))
            except (ValueError, IndexError):
                pass
    lyrics.sort(key=lambda x: x[0])


def ipc(command):
    try:
        s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        s.connect(SOCK)
        s.sendall((json.dumps({"command": command}) + "\n").encode())
        data = s.recv(4096).decode()
        s.close()
        return json.loads(data).get("data")
    except (OSError, ValueError, json.JSONDecodeError):
        return None


def current_index():
    index = -1
    for i, (t, _) in enumerate(lyrics):
        if position >= t + LYRIC_OFFSET:
            index = i
        else:
            break
    return index


def draw():
    global last_index

    width = shutil.get_terminal_size((70, 20)).columns
    height = shutil.get_terminal_size((70, 20)).lines
    idx = current_index()

    if not lyrics:
        return

    if idx >= len(lyrics) - 1 and position > lyrics[-1][0] + LYRIC_OFFSET + 8:
        os.system("clear")
        print("The Weeknd - Trust Issues\n\n\n@unfa7r")
        return

    lines = []

    if idx > 0:
        lines.append(
            (DIM + lyrics[idx - 1][1] + RESET, "dim")
        )

    if idx >= 0:
        lines.append(
            (BOLD + RED + lyrics[idx][1] + RESET, "active")
        )

    print("\033[2J\033[H\033[?25l", end="")

    t = time.time()

    offset_x = int(
        math.sin(t * 0.42) * 7 +
        math.sin(t * 0.19) * 4
    )

    offset_y = max(
        -2,
        min(2, int(math.sin(t * 0.31) * 2))
    )

    needed = sum(
        max(
            1,
            len(
                textwrap.wrap(
                    re.sub(r"\033\[[0-9;]*m", "", text),
                    max(20, width - 20)
                )
            )
        )
        for text, _ in lines
    ) + max(0, len(lines) - 1)

    start = max(
        0,
        min(
            max(0, height - needed),
            height // 2 - needed // 2 + offset_y
        )
    )

    print("\n" * start, end="")

    for text, kind in lines:
        plain = re.sub(
            r"\033\[[0-9;]*m",
            "",
            text
        )

        parts = textwrap.wrap(
            plain,
            max(20, width - 20)
        ) or [""]

        for part in parts:
            if kind == "active":
                styled = BOLD + RED + part + RESET
            else:
                styled = DIM + part + RESET

            print(
                (" " * max(0, offset_x) + styled).center(width)
            )

        if kind == "active":
            print()


def keyboard():
    global running

    old = termios.tcgetattr(sys.stdin)
    tty.setcbreak(sys.stdin.fileno())

    try:
        while running:
            ready, _, _ = select.select(
                [sys.stdin],
                [],
                [],
                0.15
            )

            if ready:
                key = sys.stdin.read(1).lower()

                if key == "p":
                    ipc(["cycle", "pause"])

                elif key == "q":
                    running = False
                    ipc(["quit"])

    finally:
        termios.tcsetattr(
            sys.stdin,
            termios.TCSADRAIN,
            old
        )


def main():
    global running, position

    load_lyrics()

    if not lyrics:
        print("Lyrics file not found:", LRC)
        print("Run the installer again or download synced lyrics manually.")
        return 1

    try:
        os.remove(SOCK)
    except FileNotFoundError:
        pass

    player = subprocess.Popen([
        "mpv",
        "--no-video",
        "--really-quiet",
        "--input-ipc-server=" + SOCK,
        "ytdl://ytsearch1:The Weeknd Trust Issues",
    ])

    for _ in range(100):
        if os.path.exists(SOCK):
            break
        time.sleep(0.1)

    threading.Thread(
        target=keyboard,
        daemon=True
    ).start()

    print(
        "\033[2J\033[H\033[?25l",
        end=""
    )

    try:
        while player.poll() is None and running:
            position = ipc(
                ["get_property", "playback-time"]
            ) or 0

            draw()

            try:
                time.sleep(0.12)
            except KeyboardInterrupt:
                running = False

    finally:
        running = False

        try:
            player.terminate()
        except OSError:
            pass

        try:
            player.wait(timeout=2)
        except Exception:
            try:
                player.kill()
            except OSError:
                pass

        try:
            os.remove(SOCK)
        except FileNotFoundError:
            pass

        print(
            "\033[?25h\033[2J\033[H",
            end=""
        )

        os.system("clear")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
