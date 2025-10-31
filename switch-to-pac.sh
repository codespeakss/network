
echo " ...  关闭其他所有代理 ...  "
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
${SCRIPT_DIR}/switch-to-none.sh

# 设置代理配置
echo "Change proxy config..."
networksetup -setautoproxyurl "Wi-Fi" "http://127.0.0.1:2080/balance.pac.js"
networksetup -setautoproxystate "Wi-Fi" off
networksetup -setautoproxystate "Wi-Fi" on

# 定义一个函数检查端口是否在监听
check_port() {
    local port=$1
    nc -z 127.0.0.1 $port >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "✅ 端口 $port 正在工作"
        return 0
    else
        echo "❌ 端口 $port 未监听"
        return 1
    fi
}

# 测试端口 7880
echo "Testing 127.0.0.1:7880..."
if check_port 7880; then
    curl --socks5-hostname 127.0.0.1:7880 https://api.ipify.org ; echo
    curl -x http://127.0.0.1:7880 https://api.ipify.org ; echo
    curl --socks5-hostname 127.0.0.1:7880 https://httpbin.org/ip
    curl -x http://127.0.0.1:7880 https://httpbin.org/ip
else
    echo "跳过 7880 测试"
fi

# 测试端口 7890
echo "Testing 127.0.0.1:7890..."
if check_port 7890; then
    curl --socks5-hostname 127.0.0.1:7890 https://api.ipify.org ; echo
    curl -x http://127.0.0.1:7890 https://api.ipify.org ; echo
    curl --socks5-hostname 127.0.0.1:7890 https://httpbin.org/ip
    curl -x http://127.0.0.1:7890 https://httpbin.org/ip
else
    echo "跳过 7890 测试"
fi

echo "All tests finished."

