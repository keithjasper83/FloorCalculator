#!/bin/sh

# ci_pre_xcodebuild.sh
# Xcode Cloud pre-build script.
# Validates that the MCP_SERVER_URL secret is configured so that a
# missing secret is surfaced early, before the build starts.

set -e

log() { echo "[ci_pre_xcodebuild] $*"; }

if [ -z "${MCP_SERVER_URL:-}" ]; then
    log "WARNING: MCP_SERVER_URL secret is not set."
    log "         Build logs will NOT be posted to the MCP server."
    log "         Add MCP_SERVER_URL in Xcode Cloud → Workflow → Environment."
else
    log "MCP_SERVER_URL is configured – build artifacts will be ingested after build."
fi
