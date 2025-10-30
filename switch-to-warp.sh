#!/bin/bash

# 关闭 PAC 和 SOCKS5
echo "正在关闭 PAC 和 SOCKS5 ..."
echo " ...   set autoproxy state  off   "
networksetup -setautoproxystate "Wi-Fi" off;
echo " ...   set socks firewallproxystate  off   "
networksetup -setsocksfirewallproxystate "Wi-Fi" off



# 尝试连接 warp
echo "正在连接 Warp..."
warp-cli connect

# 设置超时时间（秒）
TIMEOUT=15
elapsed=0

# 每秒检查状态
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
