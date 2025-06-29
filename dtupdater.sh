#!/bin/bash

CONFIG_DIR="$HOME/.local/dtupdater"
CONFIG_FILE="$CONFIG_DIR/dtupdater.ini"

DEBUG=false

# 1. Set defaults
INPUT_DIR="$HOME/Downloads/toconvert"
OUTPUT_BASE="$HOME/Downloads/converted"
MAX_JOBS=4
WINEPREFIX="$HOME/.xlcore/wineprefix"
WINE_BINARY="$HOME/.xlcore/compatibilitytool/wine/unofficial-wine-xiv-staging-ntsync-10.10/bin/wine"
CONSOLE_TOOL="$HOME/bin/FFXIV_TexTools/ConsoleTools.exe"

debug() {
    [[ "$DEBUG" == true ]] && echo "[DEBUG] $*"
}

# 2. Parse CLI args (will override config)
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)          CLI_DEBUG=true; shift ;;
        --input-dir)      CLI_INPUT_DIR="$2"; shift 2 ;;
        --output-base)    CLI_OUTPUT_BASE="$2"; shift 2 ;;
        --max-jobs)       CLI_MAX_JOBS="$2"; shift 2 ;;
        --wineprefix)     CLI_WINEPREFIX="$2"; shift 2 ;;
        --wine-binary)    CLI_WINE_BINARY="$2"; shift 2 ;;
        --console-tool)   CLI_CONSOLE_TOOL="$2"; shift 2 ;;
        *) echo "[ERROR] Unknown option: $1"; exit 1 ;;
    esac
done
# 2. Load config if it exists
if [[ -f "$CONFIG_FILE" ]]; then
    debug "Loading config from $CONFIG_FILE"
    source "$CONFIG_FILE"
else
    # Override defaults with CLI variables if they are set
    [[ -n "$CLI_INPUT_DIR" ]]     && INPUT_DIR="$CLI_INPUT_DIR"
    [[ -n "$CLI_OUTPUT_BASE" ]]   && OUTPUT_BASE="$CLI_OUTPUT_BASE"
    [[ -n "$CLI_MAX_JOBS" ]]      && MAX_JOBS="$CLI_MAX_JOBS"
    [[ -n "$CLI_WINEPREFIX" ]]    && WINEPREFIX="$CLI_WINEPREFIX"
    [[ -n "$CLI_WINE_BINARY" ]]   && WINE_BINARY="$CLI_WINE_BINARY"
    [[ -n "$CLI_CONSOLE_TOOL" ]]  && CONSOLE_TOOL="$CLI_CONSOLE_TOOL"
    debug "Config not found. Creating default config at $CONFIG_FILE"
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


# Override config with CLI variables if they are set
[[ -n "$CLI_INPUT_DIR" ]]     && INPUT_DIR="$CLI_INPUT_DIR"
[[ -n "$CLI_OUTPUT_BASE" ]]   && OUTPUT_BASE="$CLI_OUTPUT_BASE"
[[ -n "$CLI_MAX_JOBS" ]]      && MAX_JOBS="$CLI_MAX_JOBS"
[[ -n "$CLI_WINEPREFIX" ]]    && WINEPREFIX="$CLI_WINEPREFIX"
[[ -n "$CLI_WINE_BINARY" ]]   && WINE_BINARY="$CLI_WINE_BINARY"
[[ -n "$CLI_CONSOLE_TOOL" ]]  && CONSOLE_TOOL="$CLI_CONSOLE_TOOL"

debug "INPUT_DIR=$INPUT_DIR"
debug "OUTPUT_BASE=$OUTPUT_BASE"
debug "MAX_JOBS=$MAX_JOBS"
debug "WINEPREFIX=$WINEPREFIX"
debug "WINE_BINARY=$WINE_BINARY"
debug "CONSOLE_TOOL=$CONSOLE_TOOL"

# Convert UNIX path to Wine path
to_wine_path() {
    local abs_path
    abs_path=$(realpath "$1")
    echo "Z:\\${abs_path//\//\\}"
}

# The function executed by GNU Parallel
process_file() {
    debug() {
        [[ "$DEBUG" == true ]] && echo "[DEBUG] $*"
    }

    local filepath="$1"
    local rel_path="${filepath#$INPUT_DIR/}"
    local filename=$(basename "$rel_path")
    local rel_dir=$(dirname "$rel_path")
    local output_dir="$OUTPUT_BASE/$rel_dir"
    local output_path="$output_dir/$filename"

    debug "Checking file: $filepath"

    if [[ -f "$output_path" ]]; then
        debug "Skipping $rel_path (already exists)"
        return 0
    fi

    echo "[INFO] Processing: $rel_path"
    mkdir -p "$output_dir"

    local input_win_path
    local output_win_path
    input_win_path=$(to_wine_path "$filepath")
    output_win_path=$(to_wine_path "$output_path")

    debug "Wine input:  $input_win_path"
    debug "Wine output: $output_win_path"

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

debug "Finding .pmp and .ttmp2 files in $INPUT_DIR..."
file_count=$(find "$INPUT_DIR" -type f \( -iname "*.pmp" -o -iname "*.ttmp2" \) | wc -l)
debug "Found $file_count files to process."

# Find files and run them in parallel
find "$INPUT_DIR" -type f \( -iname "*.pmp" -o -iname "*.ttmp2" \) -print0 | \
    parallel -0 -j "$MAX_JOBS" --tag --line-buffer --bar process_file {}

echo "[INFO] Processing complete."