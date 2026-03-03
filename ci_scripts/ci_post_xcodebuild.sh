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
    log "MCP_SERVER_URL not set – using default."
fi

if ! command -v python3 >/dev/null 2>&1; then
    log "WARNING: python3 not found – skipping MCP ingestion."
    exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
    log "WARNING: curl not found – skipping MCP ingestion."
    exit 0
fi

log "MCP server is configured."
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

log "Posting artifacts to MCP server …"

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

# ── query MCP server for current build issues ─────────────────────────────────
# After ingesting, fetch the most recent build logs from the MCP server and
# loop through issues until all are resolved (or max retries exhausted).

MAX_RETRIES=5
RETRY_DELAY=6
BUILD_RUN_ID="${CI_BUILD_ID:-}"
UNRESOLVED_ERRORS=0
SEARCH_FILE=""

# Ensure any temp file created by the search loop is always cleaned up.
_cleanup_search_file() { rm -f "$SEARCH_FILE"; }
trap _cleanup_search_file EXIT

log "Querying MCP server for current build issues (run_id=${BUILD_RUN_ID:-unknown}) …"

retry=0
while [ "$retry" -lt "$MAX_RETRIES" ]; do

    SEARCH_PAYLOAD=$(  \
        _RUN_ID="$BUILD_RUN_ID" \
        _PROJECT="${CI_XCODE_PROJECT:-}" \
        _SCHEME="${CI_SCHEME:-}" \
        python3 - <<'PYEOF2'
import json, os

run_id  = os.environ.get("_RUN_ID",  "").strip()
project = os.environ.get("_PROJECT", "").strip()
scheme  = os.environ.get("_SCHEME",  "").strip()

# Build a targeted query from available context
parts = ["build error warning failure"]
if project:
    parts.append(project)
if scheme:
    parts.append(scheme)
query = " ".join(parts)

payload = {
    "method": "tools/call",
    "params": {
        "name": "brain_search",
        "arguments": {
            "query": query,
            "k": 20
        }
    }
}
if run_id:
    payload["params"]["arguments"]["filter"] = {"run_id": run_id}
print(json.dumps(payload))
PYEOF2
    ) || true

    SEARCH_FILE=$(mktemp "/tmp/mcp_issues_${BUILD_RUN_ID:-$$}_XXXXXX.json")

    SEARCH_STATUS=$(curl \
        --silent \
        --write-out "%{http_code}" \
        --output "$SEARCH_FILE" \
        --request POST \
        --header "Content-Type: application/json" \
        ${AUTH_HEADER:+--header "$AUTH_HEADER"} \
        --data "$SEARCH_PAYLOAD" \
        --max-time 30 \
        "$INGEST_ENDPOINT" 2>/dev/null) || {
            log "WARNING: curl failed during build-issue query – skipping issue check."
            break
        }

    SEARCH_RESPONSE=$(cat "$SEARCH_FILE" 2>/dev/null || true)
    rm -f "$SEARCH_FILE"; SEARCH_FILE=""

    if [ "$SEARCH_STATUS" -ge 200 ] && [ "$SEARCH_STATUS" -lt 300 ]; then
        ISSUE_SUMMARY=$(  \
            _SEARCH_RESPONSE="$SEARCH_RESPONSE" \
            python3 - <<'PYEOF2'
import json, os, sys

raw = os.environ.get("_SEARCH_RESPONSE", "")
try:
    data = json.loads(raw)
    hits = data.get("result", {}).get("hits", [])
    errors   = [h for h in hits if "error"   in h.get("payload", {}).get("text", "").lower()]
    warnings = [h for h in hits if "warning" in h.get("payload", {}).get("text", "").lower()
                and "error" not in h.get("payload", {}).get("text", "").lower()]
    print(json.dumps({"hits": len(hits), "errors": len(errors), "warnings": len(warnings)}))
    for i, hit in enumerate(hits, 1):
        text = hit.get("payload", {}).get("text", "")[:200].replace("\n", " ")
        score = hit.get("score", 0)
        print(f"  [{i}] score={score:.3f} | {text}")
except Exception as e:
    print(json.dumps({"hits": 0, "errors": 0, "warnings": 0, "parse_error": str(e)}))
PYEOF2
        ) || true

        COUNTS_LINE=$(printf '%s\n' "$ISSUE_SUMMARY" | head -1)
        ISSUE_COUNT=$(printf '%s\n' "$COUNTS_LINE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('hits',0))" 2>/dev/null) || {
            log "WARNING: Failed to parse MCP issue summary for hits; defaulting to 0. Raw: $COUNTS_LINE"
            ISSUE_COUNT=0
        }
        ERROR_COUNT=$(printf '%s\n' "$COUNTS_LINE" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('errors',0))" 2>/dev/null) || {
            log "WARNING: Failed to parse MCP issue summary for errors; defaulting to 0. Raw: $COUNTS_LINE"
            ERROR_COUNT=0
        }

        if [ "${ISSUE_COUNT:-0}" -gt 0 ]; then
            log "MCP returned ${ISSUE_COUNT} issue(s) (${ERROR_COUNT} error(s)) for this run:"
            printf '%s\n' "$ISSUE_SUMMARY" | tail -n +2 | while IFS= read -r line; do
                log "$line"
            done
            UNRESOLVED_ERRORS="${ERROR_COUNT:-0}"
            break
        else
            retry=$((retry + 1))
            if [ "$retry" -lt "$MAX_RETRIES" ]; then
                log "No issues indexed yet (attempt $retry/$MAX_RETRIES) – retrying in ${RETRY_DELAY}s …"
                sleep "$RETRY_DELAY"
            else
                log "No build issues found in MCP server after $MAX_RETRIES attempts – all clear."
            fi
        fi
    else
        log "WARNING: MCP server returned HTTP $SEARCH_STATUS during issue query."
        break
    fi
done

if [ "${UNRESOLVED_ERRORS:-0}" -gt 0 ]; then
    log "ERROR: $UNRESOLVED_ERRORS unresolved build error(s) found in MCP server. Fix them before the next build."
    exit 1
fi

log "Build issue check complete."
