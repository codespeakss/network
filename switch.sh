#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INTERFACE="Wi-Fi"

MODE_FILE="${HOME}/.network/mode"

persist_mode() {
    local m="$1"
    if [ -n "${m:-}" ]; then
        printf "%s" "$m" > "$MODE_FILE"
    fi
}

apply_mode() {
    # Apply a mode without persisting it. Return non-zero on failure.
    local m="$1"
    case "$m" in
        clash)
            do_clash
            ;;
        pac)
            do_pac
            ;;
        warp)
            do_warp
            ;;
        none)
            echo "Disabling auto proxy (PAC) and SOCKS5 on ${INTERFACE}..."
            networksetup -setautoproxystate "${INTERFACE}" off || true
            networksetup -setsocksfirewallproxystate "${INTERFACE}" off || true
            echo "All proxies disabled (system default)."
            ;;
        *)
            echo "Unknown mode to apply: ${m}" >&2
            return 2
            ;;
    esac
}

switch_with_rollback() {
    local target="$1"
    local previous
    previous=$(read_persisted_mode)

    if [ "${target}" = "${previous}" ]; then
        echo "Already in mode: ${target}"
        return 0
    fi

    echo "Switching to ${target} (previous: ${previous})..."

    # Try to apply target mode and capture errors without exiting the script
    set +e
    apply_mode "${target}"
    local rc=$?
    set -e

    if [ $rc -ne 0 ]; then
        echo "Switch to ${target} failed (exit ${rc}). Attempting rollback to ${previous}..." >&2
        set +e
        apply_mode "${previous}"
        local rb_rc=$?
        set -e

        if [ $rb_rc -ne 0 ]; then
            echo "Rollback to ${previous} failed (exit ${rb_rc}). Manual recovery may be necessary." >&2
            return $rb_rc
        fi

        # Restore persisted mode file to previous
        persist_mode "${previous}"
        echo "Rollback to ${previous} succeeded."
        return $rc
    fi

    # Success: persist new mode
    persist_mode "${target}"
    echo "Switched to ${target} successfully."
    return 0
}

do_clash() {
    # Enable SOCKS5 proxy for Clash on ${INTERFACE}:7890
    local port=7890
    echo "Checking local Clash port ${port}..."
    if command -v nc >/dev/null 2>&1; then
        if nc -z 127.0.0.1 "$port" >/dev/null 2>&1; then
            echo "✅ 端口 ${port} 正在工作"
        else
            echo "❌ 端口 ${port} 未监听"
            return 1
        fi
    else
        echo "nc not found; cannot test port ${port}, continuing..."
    fi

    echo "Setting SOCKS5 proxy on ${INTERFACE} (127.0.0.1:${port})..."

    # turn off WARP if present
    if command -v warp-cli >/dev/null 2>&1; then
        warp-cli disconnect || true
        warp-cli status || true
    fi

    # Disable PAC to avoid conflicts
    networksetup -setautoproxystate "${INTERFACE}" off || true

    # Configure SOCKS5 proxy
    networksetup -setsocksfirewallproxy "${INTERFACE}" 127.0.0.1 "$port" || return 2
    networksetup -setsocksfirewallproxystate "${INTERFACE}" on || return 2

    echo "Testing proxy via curl (if available)..."
    if command -v curl >/dev/null 2>&1; then
        if curl --socks5-hostname 127.0.0.1:${port} https://api.ipify.org >/dev/null 2>&1; then
            echo "Clash SOCKS5 appears to work"
        else
            echo "Warning: curl test failed for SOCKS5 proxy"
            # still return success because networksetup succeeded
        fi
    fi
    return 0
}

do_pac() {
    # Enable auto proxy (PAC) pointing to http://127.0.0.1:2080/balance.pac.js
    local pac_url="http://127.0.0.1:2080/balance.pac.js"
    echo "Switching to PAC proxy on ${INTERFACE} -> ${pac_url}"

    # Disconnect WARP if present
    if command -v warp-cli >/dev/null 2>&1; then
        warp-cli disconnect || true
        warp-cli status || true
    fi

    echo "Change proxy config..."
    networksetup -setautoproxyurl "${INTERFACE}" "${pac_url}" || return 2
    networksetup -setautoproxystate "${INTERFACE}" off || true
    networksetup -setautoproxystate "${INTERFACE}" on || return 2

    # helper to check ports
    check_port() {
        local port=$1
        if command -v nc >/dev/null 2>&1; then
            nc -z 127.0.0.1 "$port" >/dev/null 2>&1
            return $?
        fi
        return 1
    }

    local ok=1
    echo "Testing 127.0.0.1:7880..."
    if check_port 7880; then
        ok=0
        if command -v curl >/dev/null 2>&1; then
            curl --socks5-hostname 127.0.0.1:7880 https://api.ipify.org || true
            echo
        fi
    else
        echo "跳过 7880 测试"
    fi

    echo "Testing 127.0.0.1:7890..."
    if check_port 7890; then
        ok=0
        if command -v curl >/dev/null 2>&1; then
            curl --socks5-hostname 127.0.0.1:7890 https://api.ipify.org || true
            echo
        fi
    else
        echo "跳过 7890 测试"
    fi

    if [ $ok -ne 0 ]; then
        echo "PAC configured but no backend ports appear to be listening"
        # still treat as success because system proxies were set, but return non-zero to allow rollback
        return 1
    fi
    echo "All PAC tests finished."
    return 0
}

do_warp() {
    # Disable proxies and connect Warp (warp-cli)
    echo "Disabling PAC and SOCKS and connecting to Warp on ${INTERFACE}..."

    networksetup -setautoproxystate "${INTERFACE}" off || true
    networksetup -setsocksfirewallproxystate "${INTERFACE}" off || true

    if ! command -v warp-cli >/dev/null 2>&1; then
        echo "warp-cli not found; cannot connect Warp" >&2
        return 2
    fi

    warp-cli connect || true

    local TIMEOUT=15
    local elapsed=0
    while true; do
        local status
        status=$(warp-cli status 2>/dev/null || true)
        echo "$status"

        if echo "$status" | grep -q "Connected"; then
            echo "Warp 已连接成功 ✅"
            # Play a system sound if available
            if command -v afplay >/dev/null 2>&1; then
                afplay /System/Library/Sounds/Glass.aiff || true
            elif command -v paplay >/dev/null 2>&1; then
                paplay /usr/share/sounds/freedesktop/stereo/complete.oga || true
            elif command -v aplay >/dev/null 2>&1; then
                aplay /usr/share/sounds/alsa/Front_Center.wav || true
            else
                echo "✅ WARP Connected! 🔔"
            fi
            return 0
        fi

        if [ "$elapsed" -ge "$TIMEOUT" ]; then
            echo "Warp 连接超时 ❌" >&2
            return 1
        fi

        sleep 1
        elapsed=$((elapsed + 1))
    done
}

show_status() {
    # Show current proxy states and test ports
    echo "Current interface: ${INTERFACE}"
    echo "PAC state:"
    networksetup -getautoproxystate "${INTERFACE}" 2>/dev/null || echo "(unable to query PAC state)"
    echo "SOCKS state:"
    networksetup -getsocksfirewallproxy "${INTERFACE}" 2>/dev/null || echo "(unable to query SOCKS state)"
    # Placeholder: extend with port checks or more detailed diagnostics
}

read_persisted_mode() {
    if [ -f "$MODE_FILE" ]; then
        cat "$MODE_FILE"
    else
        echo "none"
    fi
}

usage() {
    cat <<EOF
Usage: $(basename "$0") <mode>
Modes:
    clash   - enable SOCKS5 proxy on ${INTERFACE}:7890 (Clash)
    pac     - enable auto proxy (PAC) pointing to http://127.0.0.1:2080/balance.pac.js
    warp    - disable proxies and connect Warp (warp-cli)
    none    - disable all proxy settings (system default)
    mode    - show the last persisted mode
    status  - show current proxy states and test ports
    help    - show this message

Examples:
    $(basename "$0") clash
    $(basename "$0") pac
    $(basename "$0") warp
    $(basename "$0") none
    $(basename "$0") mode
EOF
}


main() {
    if [ $# -lt 1 ]; then
        usage
        exit 2
    fi

    case "$1" in
        clash)
            switch_with_rollback "clash"
            ;;
        pac)
            switch_with_rollback "pac"
            ;;
        warp)
            switch_with_rollback "warp"
            ;;
        none)
            # disable PAC and SOCKS -> system default, with rollback support
            switch_with_rollback "none"
            ;;
        mode)
            echo "Current persisted mode: $(read_persisted_mode)"
            ;;
        status)
            show_status
            ;;
        help|-h|--help)
            usage
            ;;
        *)
            echo "Unknown mode: $1" >&2
            usage
            exit 2
            ;;
    esac
}

main "$@"
