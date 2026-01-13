#!/usr/bin/env bash
# ----------------------------------------------------------------------
# lib/options.sh
#
#   Command-line option parsing functions
# ----------------------------------------------------------------------

# Parse command-line options and arguments
parse_options() {
    while (( $# )); do
        case "$1" in
            -c|--combine)           COMBINE=1; shift ;;
            --no-auto-install)     AUTO_INSTALL=0; shift ;;
            -h|--help)             usage ;;
            -*)                    echo "Unknown option: $1" >&2; usage ;;
            *)                     DIRS+=("$1"); shift ;;
        esac
    done
}
