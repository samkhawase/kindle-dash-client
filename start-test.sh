#!/usr/bin/env sh

# Script to display an image on Kindle for 20 seconds then return to normal UI
# Based on kindle-dash by Pascal Widdershoven

DEBUG=${DEBUG:-false}
ISKINDLE4NT=${ISKINDLE4NT:-false}
[ "$DEBUG" = true ] && set -x

DIR="$(dirname "$0")"
IMAGE_PNG="$DIR/temp_image.png"
IMAGE_URL=${IMAGE_URL:-"https://raw.githubusercontent.com/pascalw/kindle-dash/master/example/example.png"}

# Use the xh binary in the same directory
XH_CMD="$DIR/xh"

# Verify xh exists and is executable
if [ ! -x "$XH_CMD" ]; then
    echo "Error: xh binary not found or not executable at $XH_CMD"
    exit 1
fi

log() {
    echo "[$(date -u)] $1"
}

stop_kindle_ui() {
    log "Stopping Kindle UI temporarily..."
    
    if [ "$ISKINDLE4NT" = true ]; then
        /etc/init.d/framework stop #kindle NT4 code
    else
        # For Paperwhite 3 and other models
        stop framework >/dev/null 2>&1
        stop lab126_gui >/dev/null 2>&1
    fi
    
    initctl stop webreader >/dev/null 2>&1
    lipc-set-prop com.lab126.powerd preventScreenSaver 1
}

start_kindle_ui() {
    log "Restarting Kindle UI..."
    
    # Enable screensaver again
    lipc-set-prop com.lab126.powerd preventScreenSaver 0
    
    if [ "$ISKINDLE4NT" = true ]; then
        /etc/init.d/framework start #kindle NT4 code
    else
        # For Paperwhite 3 and other models
        start lab126_gui >/dev/null 2>&1
        start framework >/dev/null 2>&1
    fi
    
    initctl start webreader >/dev/null 2>&1
}

download_and_display_image() {
    log "Downloading image from $IMAGE_URL"
    
    # Wait for WiFi to be available
    "$DIR/wait-for-wifi.sh" 1.1.1.1 2>/dev/null || {
        log "WiFi not available. Using fallback if available."
        # If the image already exists, we'll use it as fallback
        if [ ! -f "$IMAGE_PNG" ]; then
            log "No fallback image available. Exiting."
            return 1
        fi
    }
    
    # Download the image if WiFi is available
    if ping -c 1 1.1.1.1 >/dev/null 2>&1; then
        # Using xh to download the file
        "$XH_CMD" --download "$IMAGE_URL" -o "$IMAGE_PNG"
        download_status=$?
        
        if [ "$download_status" -ne 0 ]; then
            log "Failed to download image (status $download_status)"
            # If the image already exists, we'll use it as fallback
            if [ ! -f "$IMAGE_PNG" ]; then
                log "No fallback image available. Exiting."
                return 1
            fi
        fi
    fi
    
    # Display the image with full refresh for best quality
    log "Displaying image for 20 seconds..."
    /usr/sbin/eips -f -g "$IMAGE_PNG"
    
    return 0
}

main() {
    log "Starting temporary image display"
    
    # Stop Kindle UI and display image
    stop_kindle_ui
    if download_and_display_image; then
        # Wait 20 seconds
        log "Image displayed. Waiting 20 seconds..."
        sleep 20
    else
        log "Failed to display image. Skipping wait."
    fi
    
    # Restart Kindle UI
    start_kindle_ui
    
    log "Process complete. Returning to normal Kindle operation."
}

# Run the main function
main