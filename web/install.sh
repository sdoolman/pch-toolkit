#!/usr/bin/env bash
# Popcorn Hour 1-Line Modernization Installer (macOS / Linux)
set -e

PCH_IP="${1:-192.168.1.4}"

echo -e "\033[1;36m🍿 Popcorn Hour Modernization Installer\033[0m"
echo -e "\033[1;33mConnecting to Popcorn Hour at ${PCH_IP}...\033[0m"

TEMP_DIR=$(mktemp -d)
RELEASE_URL="https://github.com/stavdoo/pch-toolkit/releases/latest/download/pch-toolkit-mipsel.tar.gz"

echo "Fetching latest MIPSEL binaries..."
if curl -sSL -f "$RELEASE_URL" -o "$TEMP_DIR/pch-toolkit-mipsel.tar.gz"; then
    tar -xzf "$TEMP_DIR/pch-toolkit-mipsel.tar.gz" -C "$TEMP_DIR"
fi

echo "Uploading files via FTP..."
curl -s -u nmt:1234 -T "$TEMP_DIR/start_app.sh" "ftp://${PCH_IP}/USB_DRIVE/start_app.sh" || true
if [ -f "$TEMP_DIR/pch_daemon" ]; then
    curl -s -u nmt:1234 -T "$TEMP_DIR/pch_daemon" "ftp://${PCH_IP}/USB_DRIVE/pch_daemon" || true
fi

echo "Bootstrapping modern daemon & Dropbear SSH..."
(
  echo "sh /share/start_app.sh"
  sleep 2
) | nc -w 3 "$PCH_IP" 23 || true

echo -e "\n\033[1;32m🎉 Popcorn Hour Successfully Modernized!\033[0m"
echo -e "📱 Web Remote:    \033[1;36mhttp://${PCH_IP}:7000/remote\033[0m"
echo -e "🍿 Stremio Addon:  \033[1;36mhttp://${PCH_IP}:7000/manifest.json\033[0m"
echo -e "🔑 Modern SSH:     \033[1;33mssh root@${PCH_IP}\033[0m\n"
