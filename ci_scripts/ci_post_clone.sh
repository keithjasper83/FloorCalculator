#!/bin/sh

# ci_post_clone.sh
# Xcode Cloud post-clone script.
# Verifies that Python 3 (used by ci_post_xcodebuild.sh for JSON encoding)
# is available and prints version information for diagnostic purposes.

set -e

log() { echo "[ci_post_clone] $*"; }

log "Repository cloned successfully."

if command -v python3 >/dev/null 2>&1; then
    log "python3 available: $(python3 --version 2>&1)"
else
    log "WARNING: python3 not found. MCP log ingestion requires Python 3."
fi

if command -v curl >/dev/null 2>&1; then
    log "curl available: $(curl --version | head -1)"
else
    log "WARNING: curl not found. MCP log ingestion requires curl."
fi

log "Environment check complete."
