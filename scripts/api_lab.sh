#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$ROOT_DIR/data"
LOG_FILE="$ROOT_DIR/logs/lab3.log"
JOKE_URL="https://icanhazdadjoke.com/"
DECK_CREATE_URL="https://deckofcardsapi.com/api/deck/new/shuffle/?deck_count=1"
mkdir -p "$DATA_DIR" "$(dirname "$LOG_FILE")"

log() { printf '[%s] %s\n' "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" "$1" | tee -a "$LOG_FILE"; }
cleanup() {
  status=$?
  if [[ "$status" -eq 0 ]]; then log 'LAB3_END'; else log "LAB3_FAILED exit=$status"; fi
}
trap cleanup EXIT

log 'LAB3_START'
for cmd in bash curl jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then log "MISSING_TOOL $cmd"; exit 1; fi
done
log 'BASH_OK'

fetch_json() {
  local url="$1" output="$2" status
  if ! status=$(curl -sS -L --retry 2 --connect-timeout 10 --max-time 30 -H 'Accept: application/json' -w '%{http_code}' -o "$output" "$url"); then
    return 1
  fi
  [[ "$status" == '200' ]] || { log "HTTP_ERROR $status $url"; return 1; }
  jq -e . "$output" >/dev/null
}

if ! fetch_json "$JOKE_URL" "$DATA_DIR/dad_joke.json"; then log 'CURL_JOKE_FAIL'; exit 1; fi
log 'CURL_JOKE_OK'
jq -er '.id, .joke | select(. != null and . != "")' "$DATA_DIR/dad_joke.json" > "$DATA_DIR/dad_joke.txt"
log 'JQ_JOKE_OK'

if ! fetch_json "$DECK_CREATE_URL" "$DATA_DIR/deck_create.json"; then log 'DECK_CREATE_FAIL'; exit 1; fi
log 'DECK_CREATE_OK'
deck_id=$(jq -er '.deck_id | select(type == "string" and length > 0)' "$DATA_DIR/deck_create.json")
if ! fetch_json "https://deckofcardsapi.com/api/deck/${deck_id}/draw/?count=2" "$DATA_DIR/deck_draw.json"; then log 'DECK_DRAW_FAIL'; exit 1; fi
log 'DECK_DRAW_OK'
jq -er '(.cards | length) == 2 and (.remaining | type == "number")' "$DATA_DIR/deck_draw.json" >/dev/null
{
  jq -r '.cards[] | "\(.value) of \(.suit)"' "$DATA_DIR/deck_draw.json"
  jq -r '"Remaining: \(.remaining)"' "$DATA_DIR/deck_draw.json"
} > "$DATA_DIR/deck_summary.txt"
log 'JQ_DECK_OK'
