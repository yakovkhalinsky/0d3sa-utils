#!/usr/bin/env bash
# ----------------------------------------------------------------------
# lib/validation.sh
#
#   Input validation functions
# ----------------------------------------------------------------------

# Validate that required inputs are provided
validate_inputs() {
    if (( ${#DIRS[@]} == 0 )); then
        echo "Error: no directory supplied." >&2
        usage
    fi
}
