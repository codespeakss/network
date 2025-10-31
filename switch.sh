#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

INTERFACE="Wi-Fi"

usage() {
    cat <<EOF
Usage: $(basename "$0") <mode>
Modes:
  clash   - enable SOCKS5 proxy on ${INTERFACE}:7890 (Clash)
  pac     - enable auto proxy (PAC) pointing to http://127.0.0.1:2080/balance.pac.js
  warp    - disable proxies and connect Warp (warp-cli)
  status  - show current proxy states and test ports
  help    - show this message

Examples:
  $(basename "$0") clash
  $(basename "$0") pac
  $(basename "$0") warp
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
            ;;
        pac)
            do_pac
            ;;
        warp)
            do_warp
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
