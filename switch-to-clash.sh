#!/bin/bash

    port=7890
    nc -z 127.0.0.1 $port >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ 端口 $port 正在工作"
    else
        echo "❌ 端口 $port 未监听"
        exit 1
    fi

echo "Setting SOCKS5 proxy on Wi-Fi (127.0.0.1:7890)..."

echo "  ...  turn off WARP  ...  "
warp-cli disconnect
warp-cli status

# 可选：关闭自动代理（PAC），避免冲突
networksetup -setautoproxystate "Wi-Fi" off

# 设置 Wi-Fi 网络的 SOCKS5 代理
networksetup -setsocksfirewallproxy "Wi-Fi" 127.0.0.1 7890
networksetup -setsocksfirewallproxystate "Wi-Fi" on

echo "Testing proxy..."

# 测试 SOCKS5 代理是否生效
echo "Using curl with --socks5-hostname:"
curl --socks5-hostname 127.0.0.1:7890 https://api.ipify.org ; echo
curl --socks5-hostname 127.0.0.1:7890 https://httpbin.org/ip ; echo

# macOS networksetup 不支持 HTTP 代理直接用 SOCKS5 测试，这里仅演示 curl
echo "Done."