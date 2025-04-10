#!/usr/bin/env sh

log() {
    echo "[$(date -u)] $1"
}

test_ip=$1

if [ -z "$test_ip" ]; then
  log "No test ip specified"
  exit 1
fi

restart_wifi() {
  # Turn WiFi off and on
  lipc-set-prop com.lab126.cmd wirelessEnable 0
  sleep 5
  log "WiFi turned off"
  lipc-set-prop com.lab126.cmd wirelessEnable 1
  sleep 5  # Give it time to reconnect
  log "WiFi turned on"
}

wait_for_wifi() {
  # Try 5 times, then restart WiFi, then try 5 more times
  counter=0

  ping -c 1 "$test_ip" >/dev/null 2>&1

  # shellcheck disable=SC2181
  while [ $? -ne 0 ]; do
    counter=$((counter + 1))

    if [ $counter -eq 5 ]; then
      log "Retry $counter, restarting WiFi"
      restart_wifi
    elif [ $counter -eq 10 ]; then
      log "Retry $counter, couldn't connect to Wi-Fi" && exit 1
    fi

    sleep 5
    ping -c 1 "$test_ip" >/dev/null 2>&1
  done
}

wait_for_wifi
log "Wi-Fi connected"
