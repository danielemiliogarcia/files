#!/bin/bash

# Variables
DEBUG=true  # Set to true for debugging mode
JSON_URL="https://raw.githubusercontent.com/danielemiliogarcia/clippass/pack/files/com.clippass.host.json"
SCRIPT_URL="https://raw.githubusercontent.com/danielemiliogarcia/clippass/pack/files/clippass_extension_decrypt_clipboard.sh"

HOST_NAME="com.clippass.host"
SCRIPT_DIR="$HOME/.clippass"

# log function
log() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $1"
    fi
}

# uninstall
if [ "$1" == "--uninstall" ]; then
    echo "Uninstalling Clippass Native Messaging Host..."
    rm -f "$TARGET_DIR/$HOST_NAME.json"
    rm -rf "$SCRIPT_DIR"
    echo "Clippass Native Messaging Host uninstalled."
    exit 0
fi


# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq is not installed. Please install jq and try again."
    echo "On Debian/Ubuntu: sudo apt install jq"
    echo "On macOS: brew install jq"
    exit 1
fi

# Check if wget is installed
if ! command -v wget &> /dev/null; then
    echo "ERROR: wget is not installed. Please install wget and try again."
    echo "On Debian/Ubuntu: sudo apt install wget"
    echo "On macOS: brew install wget"
    exit 1
fi


# Detect platform and set paths
case "$(uname -s)" in
    Linux*)
        TARGET_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
        EXTENSIONS_DIR="$HOME/.config/google-chrome/Default/Extensions"
        ;;
    Darwin*)
        TARGET_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"
        EXTENSIONS_DIR="$HOME/Library/Application Support/Google/Chrome/Default/Extensions"
        ;;
    CYGWIN*|MINGW32*|MSYS*|MINGW*)
        TARGET_DIR="$LOCALAPPDATA/Google/Chrome/User Data/NativeMessagingHosts"
        EXTENSIONS_DIR="$LOCALAPPDATA/Google/Chrome/User Data/Default/Extensions"
        ;;
    *)
        echo "ERROR: Unsupported platform."
        exit 1
        ;;
esac

log "Using target directory: $TARGET_DIR"
log "Using extensions directory: $EXTENSIONS_DIR"

# Check for the Clippass extension
if [ ! -d "$EXTENSIONS_DIR" ]; then
    echo "ERROR: Chrome Extensions directory not found. Is Chrome installed?"
    exit 1
fi

EXTENSION_ID="ighbfokohpejoemlghbjekndmobfgfih"
# for EXT_DIR in "$EXTENSIONS_DIR"/*; do
#     if [ -f "$EXT_DIR/manifest.json" ]; then
#         NAME=$(jq -r '.name' "$EXT_DIR/manifest.json")
#         if [ "$NAME" == "Clippass" ]; then
#             EXTENSION_ID=$(basename "$EXT_DIR")
#             break
#         fi
#     fi
# done

# if [ -z "$EXTENSION_ID" ]; then
#     echo "ERROR: Clippass extension not found in Chrome."
#     exit 1
# fi

log "Detected Extension ID: $EXTENSION_ID"

# create_directories
mkdir -p "$TARGET_DIR"
mkdir -p "$SCRIPT_DIR"

# Download the com.clippass.host.json file directly to the target directory
wget -O "$TARGET_DIR/$HOST_NAME.json" "$JSON_URL" || {
    echo "ERROR: Failed to download com.clippass.host.json"
    rm -f "$TARGET_DIR/$HOST_NAME.json"  # Cleanup on failure
    exit 1
}

# install_files
sed "s/@@EXTENSION_ID@@/$EXTENSION_ID/" com.clippass.host.json > "$TARGET_DIR/$HOST_NAME.json"

if ! jq empty "$TARGET_DIR/$HOST_NAME.json"; then
    echo "ERROR: Generated JSON file is invalid."
    exit 1
fi


# Download the clippass_extension_decrypt_clipboard.sh file directly to the script directory
wget -O "$SCRIPT_DIR/clippass_extension_decrypt_clipboard.sh" "$SCRIPT_URL" || {
    echo "ERROR: Failed to download clippass_extension_decrypt_clipboard.sh"
    rm -f "$SCRIPT_DIR/clippass_extension_decrypt_clipboard.sh"  # Cleanup on failure
    exit 1
}

# set_permissions
chmod +x "$SCRIPT_DIR/clippass_extension_decrypt_clipboard.sh"
chmod 600 "$TARGET_DIR/$HOST_NAME.json"
chmod 700 "$SCRIPT_DIR"


echo "Clippass Native Messaging Host installed successfully!"
