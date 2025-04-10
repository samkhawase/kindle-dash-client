#!/usr/bin/env sh

# Export environment variables here
export WIFI_TEST_IP=${WIFI_TEST_IP:-1.1.1.1}
# Fast update, every 2nd minute
export REFRESH_SCHEDULE_FAST=${REFRESH_SCHEDULE_FAST:-"*/2 * * * *"}
# Slow update, once every 55 minutes
export REFRESH_SCHEDULE_SLOW=${REFRESH_SCHEDULE_SLOW:-"*/55 * * * *"}

export TIMEZONE=${TIMEZONE:-"Europe/Berlin"}

# By default, partial screen updates are used to update the screen,
# to prevent the screen from flashing. After a few partial updates,
# the screen will start to look a bit distorted (due to e-ink ghosting).
# This number determines when a full refresh is triggered. By default it's
# triggered after 4 partial updates.
export FULL_DISPLAY_REFRESH_RATE=${FULL_DISPLAY_REFRESH_RATE:-4}

# When the time until the next wakeup is greater or equal to this number,
# the dashboard will not be refreshed anymore, but instead show a
# 'kindle is sleeping' screen. This can be useful if your schedule only runs
# during the day, for example.
# 3 hours
export SLEEP_SCREEN_INTERVAL=10800

export LOW_BATTERY_REPORTING=${LOW_BATTERY_REPORTING:-false}
export LOW_BATTERY_THRESHOLD_PERCENT=10
export ISKINDLE4NT=false
export IMAGE_URL=${IMAGE_URL:-"https://YOUR_DOMAIN/dash.png"}
# E.g. 
# IMAGE_URL=${IMAGE_URL:-"https://raw.githubusercontent.com/pascalw/kindle-dash/master/example/example.png"}
