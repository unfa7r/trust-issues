
Termux

pkg update -y

pkg install -y python ffmpeg mpv git

pip install -U yt-dlp syncedlyrics

git clone https://github.com/unfa7r/trust-issues.git

cd trust-issues

chmod +x trust-issues

cp trust-issues $PREFIX/bin/trust

trust issues

Linux

sudo apt update

sudo apt install -y python3 python3-pip mpv ffmpeg git

python3 -m pip install --user -U yt-dlp syncedlyrics

git clone https://github.com/unfa7r/trust-issues.git

cd trust-issues

chmod +x trust-issues

./trust-issues
