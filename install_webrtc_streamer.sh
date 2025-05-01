#!/bin/bash
set -e  # Остановить при ошибке
set -u  # Ошибка при использовании неопределённых переменных
set -o pipefail  # Учитывать ошибки в пайпах
APP_DIR="/opt/webrtc-streamer"
CONFIG_JSON='{
  "urls": {
    "CamHome1": {
      "video": "rtsp://admin:8521232vladus@192.168.0.33:554"
    }
  }
}'
echo "=== 1. Обновление системы ==="
apt update && apt upgrade -y
echo "=== 2. Установка зависимостей ==="
apt install -y wget curl ffmpeg v4l-utils git build-essential cmake libnsl2 libsm6 mc htop
echo "=== 3. Скачивание webrtc-streamer ==="
cd ~
wget https://github.com/mpromonet/webrtc-streamer/releases/download/v0.8.11/webrtc-streamer-v0.8.11-Linux-x86_64-Release.tar.gz
echo "=== 4. Распаковка архива ==="
tar -xvf webrtc-streamer-v0.8.11-Linux-x86_64-Release.tar.gz
mv webrtc-streamer-v0.8.11-Linux-x86_64-Release webrtc-streamer
echo "=== 5. Копирование файлов в $APP_DIR ==="
mkdir -p "$APP_DIR"
cp -r ~/webrtc-streamer/share/webrtc-streamer/* "$APP_DIR/"
cp ~/webrtc-streamer/bin/webrtc-streamer "$APP_DIR/"
echo "=== 6. Создание config.json ==="
cat > "$APP_DIR/config.json" <<EOF
{
    "urls": {
        "CamHome1": {
            "video": "rtsp://admin:8521232vladus@192.168.0.33:554"
        }
    }
}
EOF
chmod +x "$APP_DIR/webrtc-streamer"
echo "=== 8. Запуск webrtc-streamer ==="
"$APP_DIR/webrtc-streamer" -C "$APP_DIR/config.json" &
echo "=== 9. Создание systemd сервиса ==="
cat <<EOF > /etc/systemd/system/webrtc-streamer.service
[Unit]
Description=WebRTC Streamer Service
After=network.target
[Service]
ExecStart=$APP_DIR/webrtc-streamer -C $APP_DIR/config.json
WorkingDirectory=$APP_DIR
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
echo "=== 10. Включение автозапуска через systemd ==="
systemctl daemon-reexec
systemctl enable webrtc-streamer
systemctl start webrtc-streamer
echo "=== 11. Проверка статуса службы ==="
systemctl status webrtc-streamer --no-pager

# === Готово ===
echo "✅ Установка завершена!"
echo "Открой в браузере:"
echo "http://<IP_LXC>:8000/webrtcstreamer.html?video=CamHome1"
