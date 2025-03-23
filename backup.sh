#!/bin/bash
# Function to stop Docker services if SERVICES_TO_STOP is set
stop_docker_services() {
  if [ -n "$SERVICES_TO_STOP" ]; then
    echo "Stopping Docker services: $SERVICES_TO_STOP"
    IFS=',' read -ra SERVICES <<<"$SERVICES_TO_STOP"
    for service in "${SERVICES[@]}"; do
      echo "Stopping $service"
      docker stop "$service"
    done
  fi
}

# Function to start Docker services if SERVICES_TO_STOP is set
start_docker_services() {
  if [ -n "$SERVICES_TO_STOP" ]; then
    echo "Starting Docker services: $SERVICES_TO_STOP"
    IFS=',' read -ra SERVICES <<<"$SERVICES_TO_STOP"
    for service in "${SERVICES[@]}"; do
      echo "Starting $service"
      docker start "$service"
    done
  fi
}
cleanup() {
  echo "Cleaning up"
  start_docker_services

}

source ./.env

# Run cleanup function on EXIT
trap cleanup EXIT
# CD to the directory of the script

cd "$(dirname "$0")" || exit

discord_url="$(cat ./discord-url.txt)"

# Define a function to send a message
send_discord_notification() {
  local message=$1

  # Construct payload using jq for proper JSON escaping
  local payload=$(jq -n --arg content "$message" '{"content": $content}')

  # Send POST request to Discord Webhook
  curl -H "Content-Type: application/json" -X POST -d "$payload" $discord_url
}

send_discord_notification "Starting $BACKUP_NAME backup"

systemctl stop jellyfin

URL="$(cat ./backup-url.txt)"
DUPLICATI_PASSPHRASE="$(cat ./duplicati-passphrase.txt)"

output=$(duplicati-cli backup "$URL" \
  $(
    IFS=','
    read -ra BACKUP_PATHS <<<"$PATHS_TO_BACKUP"
    for path in "${BACKUP_PATHS[@]}"; do echo -n "\"$path\" "; done
  ) \
  -- dblock-size=50mb \
  --backup-name="$BACKUP_NAME" \
  --passphrase="$DUPLICATI_PASSPHRASE" \
  --retention-policy="1W:1D,4W:1W,12M:1M" | tee /dev/tty | tail -n 10)

echo "Done: $output"
send_discord_notification "$output"
