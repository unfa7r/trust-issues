# Trust Issues Terminal Player

A minimalist terminal music player for **The Weeknd — Trust Issues** using `mpv`, `yt-dlp`, synced LRC lyrics, and a red animated terminal UI.

## Install

### Termux

```bash
git clone <YOUR-REPOSITORY-URL>
cd trust-issues-player
bash install.sh
```

### Linux

```bash
git clone <YOUR-REPOSITORY-URL>
cd trust-issues-player
bash install.sh
```

Then run:

```bash
trust issues
```

## Controls

- `p` — pause/resume
- `q` — quit

The player downloads synchronized lyrics during installation rather than storing copyrighted lyrics in the repository.

## Requirements

- Python 3
- mpv
- ffmpeg
- yt-dlp
- syncedlyrics
- Unix-like terminal with `termios` support

Windows PowerShell is not supported by this version.
