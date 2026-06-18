#!/bin/bash

# Color Definitions
RESET="\033[0m"
BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
MAGENTA="\033[35m"
BLUE="\033[34m"

clear
echo -e "${BOLD}${MAGENTA}==================================================${RESET}"
echo -e "${BOLD}${CYAN}       DYNAMIC MULTI-LINK DOWNLOAD MANAGER        ${RESET}"
echo -e "${BOLD}${MAGENTA}==================================================${RESET}\n"

# Step 1: Dynamic Path Verification Loop
while true; do
    echo -e "${BOLD}${CYAN}📁 Enter Target Storage Path:${RESET}"
    echo -n "👉 Path: "
    read -r TARGET_DIR

    # Clean up trailing slashes
    TARGET_DIR="${TARGET_DIR%/}"

    if [ -z "$TARGET_DIR" ]; then
        echo -e "${RED}⚠️ Path cannot be empty. Please try again.${RESET}\n"
        continue
    fi

    # Check if directory exists
    if [ -d "$TARGET_DIR" ]; then
        echo -e "${BOLD}${GREEN}✅ Path Found! ($TARGET_DIR)${RESET}\n"
        break
    else
        echo -e "${BOLD}${RED}❌ Path Not Found!${RESET} Directory does not exist."
        echo -n -e "${YELLOW}Would you like to try to create it? (y/n): ${RESET}"
        read -r CREATE_CHOICE
        if [[ "$CREATE_CHOICE" == "y" || "$CREATE_CHOICE" == "Y" ]]; then
            sudo mkdir -p "$TARGET_DIR" && sudo chmod 755 "$TARGET_DIR"
            if [ -d "$TARGET_DIR" ]; then
                echo -e "${BOLD}${GREEN}✅ Path Successfully Created!${RESET}\n"
                break
            fi
        fi
        echo -e "${BLUE}Please enter a valid, existing path.${RESET}\n"
    fi
done

echo -e "${BOLD}${MAGENTA}==================================================${RESET}"
echo -e "${BLUE}Instructions: Enter links one by one. Type '${GREEN}y${BLUE}' when done to start.${RESET}"
echo -e "${BOLD}${MAGENTA}==================================================${RESET}\n"

# Array to store URLs
URLS=()
COUNTER=1

# Step 2: Collect Links Loop
while true; do
    echo -e "${BOLD}${CYAN}${COUNTER}: URL (or type '${GREEN}y${CYAN}' to start downloading)${RESET}"
    echo -n "👉 Input: "
    read -r USER_INPUT

    # Check if user wants to start the download queue
    if [[ "$USER_INPUT" == "y" || "$USER_INPUT" == "Y" ]]; then
        if [ ${#URLS[@]} -eq 0 ]; then
            echo -e "${RED}⚠️ No URLs added yet! Please add at least one link.${RESET}\n"
            continue
        fi
        break
    fi

    # Basic check to make sure they didn't just press enter
    if [ -z "$USER_INPUT" ]; then
        echo -e "${RED}⚠️ URL cannot be empty.${RESET}\n"
        continue
    fi

    # Add URL to queue
    URLS+=("$USER_INPUT")
    echo -e "${GREEN}✓ Added to queue!${RESET}\n"
    ((COUNTER++))
done

clear
echo -e "${BOLD}${MAGENTA}==================================================${RESET}"
echo -e "${BOLD}${YELLOW}🚀 STARTING PARALLEL DOWNLOADS...                 ${RESET}"
echo -e "${BOLD}${MAGENTA}==================================================${RESET}\n"

# Step 3: Start all downloads in the background simultaneously
PIDS=()
LOG_FILES=()

for i in "${!URLS[@]}"; do
    URL="${URLS[$i]}"
    FILENAME=$(basename "$URL" | cut -d? -f1) # Pull clean filename from URL
    [ -z "$FILENAME" ] && FILENAME="download_$(($i+1))"
    
    LOG_FILE="/tmp/wget_dl_$(($i+1)).log"
    LOG_FILES+=("$LOG_FILE")
    
    echo -e "${BLUE}[Queue $(($i+1))]${RESET} Starting background stream for: ${BOLD}$FILENAME${RESET}"
    
    # Run wget in the background, logging progress, speed, and ETA to a temp file
    sudo wget -P "$TARGET_DIR" "$URL" > "$LOG_FILE" 2>&1 &
    PIDS+=($!)
done

echo -e "\n${BOLD}${CYAN}------------------- LIVE STREAM MONITOR -------------------${RESET}"

# Step 4: Live Monitor Loop
while true; do
    all_done=true
    clear
    echo -e "${BOLD}${CYAN}------------------- LIVE STREAM MONITOR -------------------${RESET}"
    echo -e "${YELLOW}Saving to:${RESET} $TARGET_DIR\n"
    
    for i in "${!PIDS[@]}"; do
        PID="${PIDS[$i]}"
        LOG_FILE="${LOG_FILES[$i]}"
        URL="${URLS[$i]}"
        FILENAME=$(basename "$URL" | cut -d? -f1)
        [ -z "$FILENAME" ] && FILENAME="download_$(($i+1))"

        # Check if the process is still running
        if ps -p $PID > /dev/null; then
            all_done=false
            
            # Extract the last progress update from the wget log file
            STATS=$(tail -n 5 "$LOG_FILE" | grep -E -o "[0-9]+%|[0-9.]+[KMGT]?B/s|[0-9hms]+s" | tr '\n' ' ')
            
            if [ -z "$STATS" ]; then
                STATS="Connecting / Initializing..."
            fi
            
            echo -e "${YELLOW}• $FILENAME:${RESET}\n  👉 [${CYAN}$STATS${RESET}]"
        else
            # Check the exit status code of the background process
            wait $PID 2>/dev/null
            STATUS=$?
            if [ $STATUS -eq 0 ]; then
                echo -e "${GREEN}✓ $FILENAME: ✅ SUCCESS${RESET}"
            else
                echo -e "${RED}✗ $FILENAME: ❌ NOT SUCCESS (Error Code: $STATUS)${RESET}"
            fi
        fi
    done
    echo -e "${BOLD}${CYAN}-----------------------------------------------------------${RESET}"
    
    if $all_done; then
        break
    fi
    
    sleep 1.5
done

# Clean up temp log files from /tmp
rm -f /tmp/wget_dl_*.log

echo -e "\n${BOLD}${MAGENTA}==================================================${RESET}"
echo -e "${BOLD}${GREEN}🎉 ALL TARGET JOBS PROCESSED!${RESET}"
echo -e "${BOLD}${MAGENTA}==================================================${RESET}\n"

# Final interactive exit step
echo -e "${YELLOW}Press [ENTER] to clean up and exit...${RESET}"
read -r

# Wipe screen clean on exit
clear
