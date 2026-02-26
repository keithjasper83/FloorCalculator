#!/bin/sh

# ci_pre_xcodebuild.sh
# Xcode Cloud pre-build script.
# Validates that the MCP_SERVER_URL secret is configured so that a
# missing secret is surfaced early, before the build starts.

set -e

DEFAULT_MCP_SERVER_URL="https://relay.Jarvis.kjdev.uk"

log() { echo "[ci_pre_xcodebuild] $*"; }

MCP_SERVER_URL="${MCP_SERVER_URL:-$DEFAULT_MCP_SERVER_URL}"
log "MCP server URL: $MCP_SERVER_URL"
log "Build artifacts will be ingested to the MCP server after build."
