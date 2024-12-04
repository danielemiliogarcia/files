#!/bin/bash

# exec 2>>/tmp/clippass_native_host_debug.log  # Log errors to a file for debugging
set -x                             # Print each command before executing it

# Get the password (decrypt from clipboard using gpg)
PASSWORD=$(xclip -selection clipboard -o | gpg --decrypt --batch --quiet)

# Construct the JSON message
MESSAGE="{\"password\": \"$PASSWORD\"}"

# Calculate the length of the message (number of bytes in the JSON string)
LENGTH=$(echo -n "$MESSAGE" | wc -c)

# Send the 4-byte little-endian length header followed by the JSON message
# Avoid wrapping the JSON in parentheses or any other extraneous characters
printf "$(printf '\\x%02x' $((LENGTH & 0xFF)))$(printf '\\x%02x' $(((LENGTH >> 8) & 0xFF)))$(printf '\\x%02x' $(((LENGTH >> 16) & 0xFF)))$(printf '\\x%02x' $(((LENGTH >> 24) & 0xFF)))" | cat - <(echo -n "$MESSAGE")
