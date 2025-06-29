#!/bin/bash

CONFIG_DIR="$HOME/.local/dtupdater"
CONFIG_FILE="$CONFIG_DIR/dtupdater.ini"

# 1. Set defaults
INPUT_DIR="$HOME/Downloads/toconvert"
OUTPUT_BASE="$HOME/Downloads/converted"
MAX_JOBS=4
WINEPREFIX="$HOME/.xlcore/wineprefix"
WINE_BINARY="$HOME/.xlcore/compatibilitytool/wine/unofficial-wine-xiv-staging-ntsync-10.10/bin/wine"
CONSOLE_TOOL="$HOME/bin/FFXIV_TexTools_v3.0.9.5/ConsoleTools.exe"

# 2. Load config if it exists
if [[ -f "$CONFIG_FILE" ]]; then
    echo "[DEBUG] Loading config from $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    echo "[DEBUG] Config not found. Creating default config at $CONFIG_FILE"
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" <<EOF
INPUT_DIR=$INPUT_DIR
OUTPUT_BASE=$OUTPUT_BASE
MAX_JOBS=$MAX_JOBS
WINEPREFIX=$WINEPREFIX
WINE_BINARY=$WINE_BINARY
CONSOLE_TOOL=$CONSOLE_TOOL
EOF
fi

# 3. Parse CLI args (override config)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --input-dir)      INPUT_DIR="$2"; shift 2 ;;
        --output-base)    OUTPUT_BASE="$2"; shift 2 ;;
        --max-jobs)       MAX_JOBS="$2"; shift 2 ;;
        --wineprefix)     WINEPREFIX="$2"; shift 2 ;;
        --wine-binary)    WINE_BINARY="$2"; shift 2 ;;
        --console-tool)   CONSOLE_TOOL="$2"; shift 2 ;;
        *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
    esac
done

echo "[DEBUG] INPUT_DIR=$INPUT_DIR"
echo "[DEBUG] OUTPUT_BASE=$OUTPUT_BASE"
echo "[DEBUG] MAX_JOBS=$MAX_JOBS"
echo "[DEBUG] WINEPREFIX=$WINEPREFIX"
echo "[DEBUG] WINE_BINARY=$WINE_BINARY"
echo "[DEBUG] CONSOLE_TOOL=$CONSOLE_TOOL"

# Convert UNIX path to Wine path
to_wine_path() {
    local abs_path
    abs_path=$(realpath "$1")
    echo "Z:\\${abs_path//\//\\}"
}

# The function executed by GNU Parallel
process_file() {
    local filepath="$1"
    local rel_path="${filepath#$INPUT_DIR/}"
    local filename=$(basename "$rel_path")
    local rel_dir=$(dirname "$rel_path")
    local output_dir="$OUTPUT_BASE/$rel_dir"
    local output_path="$output_dir/$filename"

    echo "[DEBUG] Checking file: $filepath"

    if [[ -f "$output_path" ]]; then
        echo "[DEBUG] Skipping $rel_path (already exists)"
        return 0
    fi

    echo "[INFO] Processing: $rel_path"
    mkdir -p "$output_dir"

    local input_win_path
    local output_win_path
    input_win_path=$(to_wine_path "$filepath")
    output_win_path=$(to_wine_path "$output_path")

    echo "[DEBUG] Wine input:  $input_win_path"
    echo "[DEBUG] Wine output: $output_win_path"

    WINEDEBUG=-all \
    WINEPREFIX="$WINEPREFIX" \
    "$WINE_BINARY" \
    "$CONSOLE_TOOL" \
    /upgrade "$input_win_path" "$output_win_path"

    local status=$?
    if [[ $status -ne 0 ]]; then
        echo "[ERROR] Wine failed with exit code $status for $rel_path"
    else
        echo "[INFO] Successfully processed: $rel_path"
    fi
}

# Export for GNU Parallel
export -f process_file
export -f to_wine_path
export INPUT_DIR OUTPUT_BASE WINEPREFIX WINE_BINARY CONSOLE_TOOL

echo "[DEBUG] Finding .pmp and .ttmp2 files in $INPUT_DIR..."

# Find files and run them in parallel
find "$INPUT_DIR" -type f \( -iname "*.pmp" -o -iname "*.ttmp2" \) -print0 | \
    parallel -0 -j "$MAX_JOBS" process_file {}

echo "[DEBUG] Processing complete."
