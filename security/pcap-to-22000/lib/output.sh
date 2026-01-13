#!/usr/bin/env bash
# ----------------------------------------------------------------------
# lib/output.sh
#
#   Output management functions
# ----------------------------------------------------------------------

# Setup output directory or combined file based on mode
setup_output() {
    if (( COMBINE == 0 )); then
        mkdir -p "$OUTDIR"
    else
        COMBINED_FILE="${OUTDIR}.22000"
        rm -f "$COMBINED_FILE"
        echo "Combined hash file will be: $COMBINED_FILE"
    fi
}

# Print final summary of processing results
print_summary() {
    echo
    if (( COMBINE == 1 )); then
        if [[ -s "$COMBINED_FILE" ]]; then
            local N
            N=$(grep -c '^WPA\*' "$COMBINED_FILE")
            echo "✅  Finished – $COMBINED_FILE contains $N hash(es)."
        else
            echo "⚠️  No hashes were extracted – $COMBINED_FILE is empty."
            rm -f "$COMBINED_FILE"
        fi
    else
        local TOTAL
        TOTAL=$(find "$OUTDIR" -type f -name '*.22000' | wc -l)
        echo "✅  Finished – $TOTAL .22000 file(s) written to \"$OUTDIR\"."
        echo "   Empty/‑no‑hash captures were automatically removed."
    fi
}
