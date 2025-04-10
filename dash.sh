#!/usr/bin/env sh

#####
## This is a slightly modified version of the original dash.sh script in https://github.com/pascalw/kindle-dash
## Permalink: https://github.com/pascalw/kindle-dash/blob/main/src/dash.sh
## It was originally written by Pascal Widdershoven (https://github.com/pascalw)
#####

DEBUG=${DEBUG:-false}
ISKINDLE4NT=${ISKINDLE4NT:-false}
[ "$DEBUG" = true ] && set -x

DIR="$(dirname "$0")"
DASH_PNG="$DIR/dash.png"

num_refresh=0

log() {
    echo "[$(date -u)] $1"
}

init() {
  if [ -z "$TIMEZONE" ] || [ -z "$REFRESH_SCHEDULE" ]; then
    log "Missing required configuration."
    log "Timezone: ${TIMEZONE:-(not set)}."
    log "Schedule: ${REFRESH_SCHEDULE:-(not set)}."
    exit 1
  fi

  log "Starting dashboard with $REFRESH_SCHEDULE refresh..."

  #stop framework
  if [ "$ISKINDLE4NT" = true ]; then
      /etc/init.d/framework stop #kindle NT4 code
  else
      stop framework
      stop lab126_gui #code for kindle paperwhite3
  fi

  initctl stop webreader >/dev/null 2>&1
  echo powersave >/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
  lipc-set-prop com.lab126.powerd preventScreenSaver 1
}

refresh_dashboard() {
  log "Refreshing dashboard"
  "$DIR/wait-for-wifi.sh" "$WIFI_TEST_IP"

  # Using curl to download the file because xh didn't work for my kindle in background mode.
  battery_level=$(gasgauge-info -c)

  # TODO: Report battery mAh to backend
  # battery_mah=$(gasgauge-info -m)

  log "curl -s -L -o "${DASH_PNG}" "${IMAGE_URL}" -H 'X-Battery-Level: "${battery_level}"'"

  curl -s -L -o "$DASH_PNG" "$IMAGE_URL" -H "X-Battery-Level: $battery_level"
  download_status=$?
  
  if [ "$download_status" -ne 0 ]; then
      log "Failed to download image (status $download_status)"
      # If the image already exists, we'll use it as fallback
      if [ ! -f "$DASH_PNG" ]; then
          log "No fallback image available. Exiting."
          return 1
      fi
  fi

  if [ "$num_refresh" -eq "$FULL_DISPLAY_REFRESH_RATE" ]; then
    num_refresh=0

    # trigger a full refresh once in every 4 refreshes, to keep the screen clean
    log "Full screen refresh"
    /usr/sbin/eips -f -g "$DASH_PNG"
  else
    log "Partial screen refresh"
    /usr/sbin/eips -g "$DASH_PNG"
  fi

  num_refresh=$((num_refresh + 1))
}

rtc_sleep() {
  duration=$1
  # Note: You can use sleep(10) instead of rtcwake in DEBUG mode
  # I prefer rtcwake because it gives consistent DEBUGGING experience in both modes
  rtcwake -d /dev/rtc1 -m mem -s "$duration"
}

main_loop() {
  while true; do
    log "Woke up, refreshing dashboard"

    local current_hour=$(date +%H)
    local current_minute=$(date +%M)
    
    # Refresh the dashboard according to the time of the day.
    if [[ "$current_hour" -eq 6 && "$current_minute" -ge 45 ]] || [[ "$current_hour" -eq 7 && "$current_minute" -lt 45 ]]; then   
        next_wakeup_secs=$("$DIR/next-wakeup" --schedule="$REFRESH_SCHEDULE_FAST" --timezone="$TIMEZONE")
        log "REFRESH_SCHEDULE_FAST"
    else
       next_wakeup_secs=$("$DIR/next-wakeup" --schedule="$REFRESH_SCHEDULE_SLOW" --timezone="$TIMEZONE")	
       log "REFRESH_SCHEDULE_SLOW"    
    fi
    
    refresh_dashboard

    # Display the screen for a minute before going to sleep
    sleep 60

    # Set intensity to 15
    lipc-set-prop com.lab126.powerd flIntensity 15

    log "Going to sleep, next wakeup in ${next_wakeup_secs}s"
    rtc_sleep "$next_wakeup_secs"
  done
}

init
main_loop