#!/usr/bin/env bash
# shellcheck disable=SC2154
set -euo pipefail

# User defined variables for pushover
PUSHOVER_USER_KEY="${PUSHOVER_USER_KEY:-required}"
PUSHOVER_TOKEN="${PUSHOVER_TOKEN:-required}"
PUSHOVER_PRIORITY="${PUSHOVER_PRIORITY:-"-2"}"

if [[ "${whisparr_eventtype:-}" == "Test" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE \
        "Test Notification"
    printf -v PUSHOVER_MESSAGE \
        "Howdy this is a test notification from %s" \
            "${whisparr_instancename:-Whisparr}"
    printf -v PUSHOVER_URL \
        "%s" \
            "${whisparr_applicationurl:-localhost}"
    printf -v PUSHOVER_URL_TITLE \
        "Open %s" \
            "${whisparr_instancename:-Whisparr}"
fi

if [[ "${whisparr_eventtype:-}" == "Download" ]]; then
    printf -v PUSHOVER_TITLE \
        "Movie %s" \
            "$( [[ "${whisparr_isupgrade}" == "True" ]] && echo "Upgraded" || echo "Downloaded" )"
    printf -v PUSHOVER_MESSAGE \
        "<b>%s (%s)</b><small>\n%s</small><small>\n\n<b>Client:</b> %s</small><small>\n<b>Quality:</b> %s</small><small>\n<b>Size:</b> %s</small>" \
            "${whisparr_movie_title}" \
            "${whisparr_movie_year}" \
            "${whisparr_movie_overview}" \
            "${whisparr_download_client:-Unknown}" \
            "${whisparr_moviefile_quality:-Unknown}" \
            "$(numfmt --to iec --format "%8.2f" "${whisparr_release_size:-0}")"
    printf -v PUSHOVER_URL \
        "%s/movie/%s" \
            "${whisparr_applicationurl:-localhost}" "${whisparr_movie_tmdbid}"
    printf -v PUSHOVER_URL_TITLE \
        "View movie in %s" \
            "${whisparr_instancename:-Whisparr}"
fi

if [[ "${whisparr_eventtype:-}" == "ManualInteractionRequired" ]]; then
    PUSHOVER_PRIORITY="1"
    printf -v PUSHOVER_TITLE \
        "Movie import requires intervention"
    printf -v PUSHOVER_MESSAGE \
        "<b>%s (%s)</b><small>\n<b>Client:</b> %s</small>" \
            "${whisparr_movie_title}" \
            "${whisparr_movie_year}" \
            "${whisparr_download_client:-Unknown}"
    printf -v PUSHOVER_URL \
        "%s/activity/queue" \
            "${whisparr_applicationurl:-localhost}"
    printf -v PUSHOVER_URL_TITLE \
        "View queue in %s" \
            "${whisparr_instancename:-Whisparr}"
fi

json_data=$(jo \
    token="${PUSHOVER_TOKEN}" \
    user="${PUSHOVER_USER_KEY}" \
    title="${PUSHOVER_TITLE}" \
    message="${PUSHOVER_MESSAGE}" \
    url="${PUSHOVER_URL}" \
    url_title="${PUSHOVER_URL_TITLE}" \
    priority="${PUSHOVER_PRIORITY}" \
    html="1"
)

status_code=$(curl \
    --silent \
    --write-out "%{http_code}" \
    --output /dev/null \
    --request POST  \
    --header "Content-Type: application/json" \
    --data-binary "${json_data}" \
    "https://api.pushover.net/1/messages.json" \
)

printf "pushover notification returned with HTTP status code %s and payload: %s\n" \
    "${status_code}" \
    "$(echo "${json_data}" | jq --compact-output)" >&2
