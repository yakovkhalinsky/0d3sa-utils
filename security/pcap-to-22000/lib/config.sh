#!/usr/bin/env bash
# ----------------------------------------------------------------------
# lib/config.sh
#
#   Global configuration variables for pcap-to-22000.sh
# ----------------------------------------------------------------------

# Output directory for per-file hashes
OUTDIR="hashes_22000"

# Combine mode: 0 = one file per capture, 1 = single combined file
COMBINE=0

# Directories supplied on the command line
DIRS=()

# Path to combined output file (when COMBINE=1)
COMBINED_FILE=""

# Auto-install missing dependencies: 1 = enabled, 0 = disabled
AUTO_INSTALL=1
