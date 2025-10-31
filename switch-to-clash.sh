#!/bin/bash

    port=7890
    nc -z 127.0.0.1 $port >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ 端口 $port 正在工作"
    else
        echo "❌ 端口 $port 未监听"
        exit 1
    fi

echo " ...  关闭其他所有代理 ...  "
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
${SCRIPT_DIR}/switch-to-none.sh

echo " ...  设置 Wi-Fi 网络的 SOCKS5 代理 ...  "
networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 7890
networksetup -setsocksfirewallproxystate "Wi-Fi" on

echo "Testing proxy..."

# 测试 SOCKS5 代理是否生效
echo "Using curl with --socks5-hostname:"
curl --socks5-hostname 127.0.0.1:7890 https://api.ipify.org ; echo
curl --socks5-hostname 127.0.0.1:7890 https://httpbin.org/ip ; echo

echo "Done."