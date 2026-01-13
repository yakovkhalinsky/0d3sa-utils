#!/usr/bin/env bash
# ----------------------------------------------------------------------
# lib/usage.sh
#
#   Usage and help functions
# ----------------------------------------------------------------------

# Display usage information and exit
usage() {
    cat <<EOF
Usage: $(basename "$0") [options] <dir1> [dir2 ...]
   -c | --combine          write all found hashes to ONE file named combined.22000
   --no-auto-install       skip automatic installation of missing dependencies
   -h | --help             this help

If no directory is supplied the script exits.

The script will automatically check for and attempt to install missing dependencies
(like hcxtools) unless --no-auto-install is specified.
EOF
    exit 1
}
