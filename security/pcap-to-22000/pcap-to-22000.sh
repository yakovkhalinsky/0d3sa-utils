#!/usr/bin/env bash
# ----------------------------------------------------------------------
# pcap-to-22000.sh
#
#   Recursively scan one or more directories, convert every
#   *.pcap* / *.pcapng* file that contains a WPA/WPA2 handshake
#   into a Hashcat‑compatible .22000 file.
#
#   Requirements:
#       • hcxtools (hcxpcapngtool)
#       • Bash (tested on 4.x+)
#
#   Author:  ChatGPT (2024‑01‑11)
#   License: MIT
# ----------------------------------------------------------------------

set -euo pipefail                     # safety: abort on errors / unset vars

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# ---------- Load Modules ----------
# Source all function modules in dependency order
source "${LIB_DIR}/config.sh"        # Global variables
source "${LIB_DIR}/usage.sh"          # Usage/help functions
source "${LIB_DIR}/options.sh"        # Option parsing (depends on usage)
source "${LIB_DIR}/validation.sh"     # Input validation (depends on usage)
source "${LIB_DIR}/dependencies.sh"   # Dependency checking and installation
source "${LIB_DIR}/output.sh"          # Output management
source "${LIB_DIR}/processing.sh"     # File processing

# ---------- Main Entry Point ----------

# Main entry point
main() {
    parse_options "$@"
    
    # Check dependencies before proceeding
    if ! check_dependencies "$AUTO_INSTALL"; then
        echo "Error: Missing required dependencies. Exiting." >&2
        exit 1
    fi
    
    validate_inputs
    setup_output

    # Process each directory
    for DIR in "${DIRS[@]}"; do
        process_directory "$DIR"
    done

    print_summary
}

# Execute main function
main "$@"
