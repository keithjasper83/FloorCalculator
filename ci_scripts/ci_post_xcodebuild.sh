#!/bin/sh

# ci_post_xcodebuild.sh
# Xcode Cloud post-build script that ingests build logs and xcresult
# artifacts into the MCP Brain server for diagnosis and analysis.
#
# Required Xcode Cloud secret:
#   MCP_SERVER_URL  – Base URL of the MCP Brain server
#                     e.g. https://your-mcp-server.example.com
#
# Optional Xcode Cloud secret:
#   MCP_API_KEY     – Bearer token for authenticated MCP servers
#
# Xcode Cloud environment variables used automatically:
#   CI_XCODE_PROJECT       Project / workspace name
#   CI_SCHEME              Scheme that was built
#   CI_CONFIGURATION       Build configuration (Debug / Release)
#   CI_BUILD_ID            Unique build identifier (used as run_id)
#   CI_XCODEBUILD_ACTION   xcodebuild action (build, test, archive …)
#   CI_PRODUCT_PLATFORM    Target platform (iOS, macOS …)
#   CI_RESULT_BUNDLE_PATH  Path to the .xcresult bundle
#   CI_LOG_DIR             Directory containing build logs

set -e

# ── helpers ──────────────────────────────────────────────────────────────────

log() { echo "[ci_post_xcodebuild] $*"; }

# ── guards: required tools and MCP_SERVER_URL must be configured ─────────────

if [ -z "${MCP_SERVER_URL:-}" ]; then
    MCP_SERVER_URL="https://relay.Jarvis.kjdev.uk"
    log "MCP_SERVER_URL not set – using default: $MCP_SERVER_URL"
fi

if ! command -v python3 >/dev/null 2>&1; then
    log "WARNING: python3 not found – skipping MCP ingestion."
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    log "WARNING: curl not found – skipping MCP ingestion."
    exit 0
fi

log "MCP server: $MCP_SERVER_URL"
log "Project   : ${CI_XCODE_PROJECT:-unknown}"
log "Scheme    : ${CI_SCHEME:-unknown}"
log "Config    : ${CI_CONFIGURATION:-unknown}"
log "Run ID    : ${CI_BUILD_ID:-unknown}"

# ── collect raw build log ─────────────────────────────────────────────────────

RAW_LOG=""
if [ -n "$CI_LOG_DIR" ] && [ -d "$CI_LOG_DIR" ]; then
    # Use the most recently modified log file; tail all others and prepend
    LOG_FILES=$(find "$CI_LOG_DIR" -name "*.log" -type f 2>/dev/null \
        | xargs ls -t 2>/dev/null)
    if [ -n "$LOG_FILES" ]; then
        # Concatenate all logs then tail to a reasonable payload size
        RAW_LOG=$(echo "$LOG_FILES" | xargs cat 2>/dev/null | tail -2000 || true)
        LOG_COUNT=$(echo "$LOG_FILES" | wc -l | tr -d ' ')
        log "Collected $LOG_COUNT log file(s) from $CI_LOG_DIR ($(echo "$RAW_LOG" | wc -l | tr -d ' ') lines)"
    fi
fi

# ── collect xcresult JSON ─────────────────────────────────────────────────────

XCRESULT_JSON=""
if [ -n "$CI_RESULT_BUNDLE_PATH" ] && [ -d "$CI_RESULT_BUNDLE_PATH" ]; then
    if command -v xcrun >/dev/null 2>&1; then
        XCRESULT_JSON=$(xcrun xcresulttool get \
            --path "$CI_RESULT_BUNDLE_PATH" \
            --format json 2>/dev/null || true)
        log "Collected xcresult JSON (${#XCRESULT_JSON} bytes)"
    fi
fi

# ── collect build settings ────────────────────────────────────────────────────

BUILD_SETTINGS_JSON=""
if command -v xcodebuild >/dev/null 2>&1 && [ -n "$CI_SCHEME" ]; then
    BUILD_SETTINGS_JSON=$(xcodebuild \
        -scheme "$CI_SCHEME" \
        -showBuildSettings \
        -json 2>/dev/null || true)
    log "Collected build settings JSON (${#BUILD_SETTINGS_JSON} bytes)"
fi

# ── derive destination string ─────────────────────────────────────────────────

DESTINATION=""
case "${CI_PRODUCT_PLATFORM:-}" in
    iOS)         DESTINATION="platform=iOS Simulator,name=iPhone 15" ;;
    macOS)       DESTINATION="platform=macOS" ;;
    tvOS)        DESTINATION="platform=tvOS Simulator,name=Apple TV" ;;
    watchOS)     DESTINATION="platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)" ;;
    visionOS)    DESTINATION="platform=visionOS Simulator,name=Apple Vision Pro" ;;
    *)           DESTINATION="${CI_PRODUCT_PLATFORM:-}" ;;
esac

# ── build JSON payload ────────────────────────────────────────────────────────
# Variables are passed via environment so that no content can break out of
# the Python string context (avoids shell injection through log content).

PAYLOAD=$(  \
    _PROJECT="${CI_XCODE_PROJECT:-}" \
    _SCHEME="${CI_SCHEME:-}" \
    _CONFIGURATION="${CI_CONFIGURATION:-}" \
    _DESTINATION="$DESTINATION" \
    _RUN_ID="${CI_BUILD_ID:-}" \
    _RAW_LOG="$RAW_LOG" \
    _XCRESULT_JSON="$XCRESULT_JSON" \
    _BUILD_SETTINGS_JSON="$BUILD_SETTINGS_JSON" \
    python3 - <<'PYEOF'
import json, os

def env(key):
    val = os.environ.get(key, "")
    return val if val.strip() else None

payload = {
    "method": "tools/call",
    "params": {
        "name": "brain_ingest_artifacts",
        "arguments": {
            "project":       env("_PROJECT"),
            "scheme":        env("_SCHEME"),
            "configuration": env("_CONFIGURATION"),
            "destination":   env("_DESTINATION"),
            "run_id":        env("_RUN_ID"),
        }
    }
}

# Remove None-valued keys
payload["params"]["arguments"] = {
    k: v for k, v in payload["params"]["arguments"].items() if v is not None
}

raw_log = os.environ.get("_RAW_LOG", "")
if raw_log.strip():
    payload["params"]["arguments"]["raw_log"] = raw_log

xcresult_raw = os.environ.get("_XCRESULT_JSON", "")
if xcresult_raw.strip():
    try:
        payload["params"]["arguments"]["xcresult_json"] = json.loads(xcresult_raw)
    except Exception:
        pass

build_settings_raw = os.environ.get("_BUILD_SETTINGS_JSON", "")
if build_settings_raw.strip():
    try:
        payload["params"]["arguments"]["build_settings"] = json.loads(build_settings_raw)
    except Exception:
        pass

print(json.dumps(payload))
PYEOF
)

# ── POST to MCP server ────────────────────────────────────────────────────────

INGEST_ENDPOINT="${MCP_SERVER_URL%/}/mcp"

AUTH_HEADER=""
if [ -n "${MCP_API_KEY:-}" ]; then
    AUTH_HEADER="Authorization: Bearer $MCP_API_KEY"
fi

log "Posting artifacts to $INGEST_ENDPOINT …"

RESPONSE_FILE=$(mktemp "/tmp/mcp_ingest_${CI_BUILD_ID:-$$}_XXXXXX.json")

HTTP_STATUS=$(curl \
    --silent \
    --write-out "%{http_code}" \
    --output "$RESPONSE_FILE" \
    --request POST \
    --header "Content-Type: application/json" \
    ${AUTH_HEADER:+--header "$AUTH_HEADER"} \
    --data "$PAYLOAD" \
    --max-time 60 \
    "$INGEST_ENDPOINT" 2>/dev/null) || {
        log "WARNING: curl failed – MCP ingestion skipped."
        rm -f "$RESPONSE_FILE"
        exit 0
    }

RESPONSE=$(cat "$RESPONSE_FILE" 2>/dev/null || true)
rm -f "$RESPONSE_FILE"

if [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 300 ]; then
    log "Ingestion succeeded (HTTP $HTTP_STATUS)."
    log "Response: $RESPONSE"
else
    log "WARNING: MCP server returned HTTP $HTTP_STATUS – ingestion may have failed."
    log "Response: $RESPONSE"
fi
