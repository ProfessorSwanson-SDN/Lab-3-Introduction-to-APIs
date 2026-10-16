#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'


ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DATA_DIR="${ROOT_DIR}/data"
LOG_DIR="${ROOT_DIR}/logs"
LOG_FILE="${LOG_DIR}/lab3.log"

JOKE_URL="https://icanhazdadjoke.com/"
DECK_URL="https://deckofcardsapi.com/api/deck"
JOKE_FILE="${DATA_DIR}/dad_joke.json"

mkdir -p "${DATA_DIR}" "${LOG_DIR}"

log() {
    printf '[%s] %s\n' "$1" "$(date -Is)" >> "$LOG_FILE"    
}

cleanup() {
    local exit_code=$?
    if (( exit_code != 0 )); then
        log "LAB3_ERROR"
    fi
    log "LAB3_END"
}

trap cleanup EXIT

log "LAB3_START"

for tool in curl jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        log "MISSING_$tool"
        printf 'Required tool is missing: %s\n' "$tool" >&2
        exit 1
    fi
done

log "BASH_OK"
echo "Prerequisite checks passed."


fetch_json() {
    local url="$1"
    local output_file="$2"
    local status

    status=$(curl -sS \
        -H "Accept: application/json" \
        -w "%{http_code}" \
        -o "$output_file" \
        "$url") || {
        echo "Request failed: $url" >&2
        return 1
    }

    printf '%s\n' "$status"
} 

if ! joke_status=$(fetch_json "$JOKE_URL" "$JOKE_FILE"); then
    log "CURL_JOKE_FAIL"
    exit 1
fi


if [[ "$joke_status" != "200" ]]; then
    log "CURL_JOKE_FAIL"
    echo "Dad Jokes request returned HTTP $joke_status" >&2
    exit 1
fi

log "CURL_JOKE_OK"


jq -r '.id, .joke' "$JOKE_FILE" > "$DATA_DIR/dad_joke.txt"

if [[ ! -s "$JOKE_FILE" || ! -s "$DATA_DIR/dad_joke.txt" ]]; then
    echo "A dad joke output file is empty." >&2
    exit 1
fi

log "JQ_JOKE_OK"
echo "Dad joke saved successfully."


if ! deck_status=$(fetch_json \
    "$DECK_URL/new/shuffle/?deck_count=1" \
    "$DATA_DIR/deck_create.json"); then
    log "CURL_DECK_FAIL"
    exit 1
fi

if [[ "$deck_status" != "200" ]]; then
    log "CURL_DECK_FAIL"
    echo "Deck creation request returned HTTP $deck_status" >&2
    exit 1
fi

jq -e '.success == true' "$DATA_DIR/deck_create.json" >/dev/null
deck_id=$(jq -er '.deck_id | strings | select(length > 0)' \
    "$DATA_DIR/deck_create.json")

log "DECK_CREATE_OK"


if ! draw_status=$(fetch_json \
    "$DECK_URL/$deck_id/draw/?count=2" \
    "$DATA_DIR/deck_draw.json"); then
    log "DECK_DRAW_FAIL"
    exit 1
fi

if [[ "$draw_status" != "200" ]]; then
    log "$DECK_DRAW_FAIL"
    echo "Card draw returned HTTP $draw_status" >&2
    exit 1
fi

jq -e '.success == true and (.cards | length) == 2' \
    "$DATA_DIR/deck_draw.json" >/dev/null

log "DECK_DRAW_OK"

jq -r '
    (.cards[] | "\(.value) of \(.suit)"),
    "Remaining cards: \(.remaining)"
' "$DATA_DIR/deck_draw.json" > "$DATA_DIR/deck_summary.txt"

log "JQ_DECK_OK"
echo "Two cards drawn and summary saved."
