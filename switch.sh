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

do_clash() {
    # Enable SOCKS5 proxy for Clash on ${INTERFACE}:7890
    echo "Enabling Clash (SOCKS5) on ${INTERFACE}:7890..."
    # Placeholder: implement networksetup calls or other logic here
}

do_pac() {
    # Enable auto proxy (PAC) pointing to http://127.0.0.1:2080/balance.pac.js
    echo "Enabling PAC proxy for ${INTERFACE} -> http://127.0.0.1:2080/balance.pac.js..."
    # Placeholder: implement networksetup calls or other logic here
}

do_warp() {
    # Disable proxies and connect Warp (warp-cli)
    echo "Connecting to Warp and disabling system proxies on ${INTERFACE}..."
    # Placeholder: implement warp-cli calls and networksetup adjustments here
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
            do_clash
            persist_mode "clash"
            ;;
        pac)
            do_pac
            persist_mode "pac"
            ;;
        warp)
            do_warp
            persist_mode "warp"
            ;;
        none)
            # disable PAC and SOCKS -> system default
            echo "Disabling auto proxy (PAC) and SOCKS5 on ${INTERFACE}..."
            networksetup -setautoproxystate "${INTERFACE}" off || true
            networksetup -setsocksfirewallproxystate "${INTERFACE}" off || true
            echo "All proxies disabled (system default)."
            persist_mode "none"
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
