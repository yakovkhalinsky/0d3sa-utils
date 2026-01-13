#!/usr/bin/env bash
# ----------------------------------------------------------------------
# lib/processing.sh
#
#   File processing functions
# ----------------------------------------------------------------------

# Process a single capture file
# Arguments:
#   $1 - path to capture file
process_capture_file() {
    local CAPFILE="$1"
    local BASENAME TMPFILE OUTFILE NAME_NOEXT

    # Prepare output names
    BASENAME=$(basename "$CAPFILE")
    NAME_NOEXT="${BASENAME%.*}"                 # strip only the last extension

    if (( COMBINE == 0 )); then
        OUTFILE="${OUTDIR}/${NAME_NOEXT}.22000"
        TMPFILE="${OUTFILE}.tmp"
    else
        TMPFILE=$(mktemp)                        # temporary file for this capture
    fi

    # Run hcxpcapngtool
    # --all : try to extract both PMKID and full 4‑way handshake
    # -o   : write a WPA‑22000 hash (or nothing)
    # 2>/dev/null hides the "no handshake" warning that hcxpcapngtool prints
    if hcxpcapngtool --all -o "$TMPFILE" "$CAPFILE" 2>/dev/null; then
        # Did we actually get a WPA line?
        if [[ -s "$TMPFILE" ]] && grep -q '^WPA\*' "$TMPFILE"; then
            if (( COMBINE == 0 )); then
                mv "$TMPFILE" "$OUTFILE"
                echo "✔  $CAPFILE  →  $OUTFILE"
            else
                cat "$TMPFILE" >> "$COMBINED_FILE"
                rm -f "$TMPFILE"
                echo "✔  $CAPFILE  appended to $COMBINED_FILE"
            fi
        else
            # No usable hash – discard temp file
            rm -f "$TMPFILE"
            echo "✖  $CAPFILE  – no WPA/WPA2 hash found"
        fi
    else
        # hcxpcapngtool failed (corrupt file, permission, …)
        rm -f "$TMPFILE"
        echo "⚠  $CAPFILE  – hcxpcapngtool failed"
    fi
}

# Process all capture files in a directory
# Arguments:
#   $1 - path to directory
process_directory() {
    local DIR="$1"
    local CAPFILE

    if [[ ! -d "$DIR" ]]; then
        echo "Warning: $DIR is not a directory – skipping." >&2
        return 1
    fi

    # Find every *.pcap* or *.pcapng* (case‑insensitive)
    while IFS= read -r -d '' CAPFILE; do
        process_capture_file "$CAPFILE"
    done < <(find "$DIR" -type f \( -iname '*.pcap' -o -iname '*.pcapng' \) -print0)
}
