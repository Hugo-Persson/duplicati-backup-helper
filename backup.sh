#!/bin/bash
# CD to the directory of the script
cd "$(dirname "$0")" || exit
source ./.env
set -e
cleanup() {
  echo "Cleaning up"
  # Run post-backup command if defined
  if [[ -n "$POST_RUN" ]]; then
    echo "Running post-backup command: $POST_RUN"
    eval "$POST_RUN"
  fi
  cd -
}

# Run cleanup function on EXIT
trap cleanup EXIT

# Run pre-backup command if defined
if [[ -n "$PRE_RUN" ]]; then
  echo "Running pre-backup command: $PRE_RUN"
  eval "$PRE_RUN"
fi

# Define a function to send a message
send_discord_notification() {
  local message=$1
  local is_status=${2:-false}

  if [ "$is_status" == "true" ]; then
    # Format backup results as a Discord embed with proper formatting
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Extract key metrics from the output using grep and sed
    local remote_files=$(echo "$message" | grep "Remote files:" | sed 's/Remote files: //')
    local remote_size=$(echo "$message" | grep "Remote size:" | sed 's/Remote size: //')
    local files_added=$(echo "$message" | grep "Files added:" | sed 's/Files added: //')
    local files_deleted=$(echo "$message" | grep "Files deleted:" | sed 's/Files deleted: //')
    local files_changed=$(echo "$message" | grep "Files changed:" | sed 's/Files changed: //')
    local data_uploaded=$(echo "$message" | grep "Data uploaded:" | sed 's/Data uploaded: //')
    local data_downloaded=$(echo "$message" | grep "Data downloaded:" | sed 's/Data downloaded: //')

    # Construct a prettier payload with Discord embeds
    local payload=$(jq -n \
      --arg title "Backup Complete: $BACKUP_NAME" \
      --arg color "3066993" \
      --arg timestamp "$timestamp" \
      --arg files_added "$files_added" \
      --arg files_deleted "$files_deleted" \
      --arg files_changed "$files_changed" \
      --arg remote_files "$remote_files" \
      --arg remote_size "$remote_size" \
      --arg data_uploaded "$data_uploaded" \
      --arg data_downloaded "$data_downloaded" \
      '{
        "embeds": [{
          "title": $title,
          "color": $color|tonumber,
          "timestamp": $timestamp,
          "fields": [
            {"name": "📊 Stats", "value": ""},
            {"name": "Remote Files", "value": $remote_files, "inline": true},
            {"name": "Remote Size", "value": $remote_size, "inline": true},
            {"name": "📝 Changes", "value": ""},
            {"name": "Files Added", "value": $files_added, "inline": true},
            {"name": "Files Deleted", "value": $files_deleted, "inline": true},
            {"name": "Files Changed", "value": $files_changed, "inline": true},
            {"name": "📤 Transfer", "value": ""},
            {"name": "Data Uploaded", "value": $data_uploaded, "inline": true},
            {"name": "Data Downloaded", "value": $data_downloaded, "inline": true}
          ]
        }]
      }')
  else
    # For regular messages, use a simpler format
    local payload=$(jq -n \
      --arg content "🔄 **$BACKUP_NAME**: $message" \
      '{"content": $content}')
  fi

  # Send POST request to Discord Webhook
  curl -s -H "Content-Type: application/json" -X POST -d "$payload" $DISCORD_URL
}
# Create a formatted list of directories to backup
formatted_directories=$(echo "$PATHS_TO_BACKUP" | tr ' ' '\n' | grep -v '^-' | awk '{print "• " $0}' | paste -sd '\n' -)

# Create a start backup embed message
local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
backup_payload=$(jq -n \
  --arg title "Backup Started: $BACKUP_NAME" \
  --arg color "16750848" \
  --arg timestamp "$timestamp" \
  --arg directories "$formatted_directories" \
  '{
    "embeds": [{
      "title": $title,
      "color": $color|tonumber,
      "timestamp": $timestamp,
      "fields": [
        {"name": "📂 Directories", "value": $directories},
        {"name": "Status", "value": "⏳ Backup in progress..."}
      ]
    }]
  }')

# Send the notification using the raw payload
curl -s -H "Content-Type: application/json" -X POST -d "$backup_payload" $DISCORD_URL


output=$(duplicati-cli backup "$DUPLICATI_URL" \
  $PATHS_TO_BACKUP \
  --dblock-size=50mb \
  --backup-name="$BACKUP_NAME" \
  --passphrase="$DUPLICATI_PASSPHRASE" \
  --retention-policy="1W:1D,4W:1W,12M:1M" | tee /dev/tty | tail -n 10)

echo "Done: $output"
send_discord_notification "$output" true