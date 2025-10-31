#!/bin/bash

echo " ...  关闭其他所有代理 ...  "
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
${SCRIPT_DIR}/switch-to-none.sh

echo "正在连接 Warp..."
warp-cli connect

TIMEOUT=15
elapsed=0

while true; do
    status=$(warp-cli status | grep "Status update")

    echo "$status"

    if echo "$status" | grep -q "Connected"; then
        echo "Warp 已连接成功 ✅"

        # 播放提示音（macOS）
        if command -v afplay >/dev/null 2>&1; then
            afplay /System/Library/Sounds/Glass.aiff
        # 播放提示音（Linux）
        elif command -v paplay >/dev/null 2>&1; then
            paplay /usr/share/sounds/freedesktop/stereo/complete.oga
        elif command -v aplay >/dev/null 2>&1; then
            aplay /usr/share/sounds/alsa/Front_Center.wav
        else
            echo "✅ WARP Connected! 🔔"
        fi
        break
    fi

    # 检查是否超时
    if [ "$elapsed" -ge "$TIMEOUT" ]; then
        echo "Warp 连接超时 ❌"
        echo "正在回退到 PAC 模式..."
        ~/.network/switch-to-pac.sh
        exit 1
    fi

    sleep 1
    ((elapsed++))
done
