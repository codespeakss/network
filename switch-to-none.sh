#!/bin/bash
# 关闭所有代理设置（HTTP、HTTPS、FTP、SOCKS、PAC）

echo "正在检测网络服务..."
# 用 while-read 保留服务名中的空格
networksetup -listallnetworkservices | grep -v "An asterisk" | while read -r service; do
    # 跳过空行
    [ -z "$service" ] && continue
    echo "🔧 处理网络接口: \"$service\""

    # 关闭自动代理 (PAC)
    networksetup -setautoproxystate "$service" off 2>/dev/null

    # 关闭 Web 代理 (HTTP)
    networksetup -setwebproxystate "$service" off 2>/dev/null

    # 关闭安全 Web 代理 (HTTPS)
    networksetup -setsecurewebproxystate "$service" off 2>/dev/null

    # 关闭 FTP 代理
    networksetup -setftpproxystate "$service" off 2>/dev/null

    # 关闭 Gopher 代理
    networksetup -setgopherproxystate "$service" off 2>/dev/null

    # 关闭 SOCKS 代理
    networksetup -setsocksfirewallproxystate "$service" off 2>/dev/null

    echo "✅ 已关闭 \"$service\" 的所有代理设置"
done

echo "✅ 所有网络接口的所有类型代理已关闭。"




echo "  ...  turn off WARP  ing ...  "
warp-cli disconnect
warp-cli status

echo "  ...  turn off WARP  done ...  "
