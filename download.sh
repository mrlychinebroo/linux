#!/bin/bash

# ==============================================================================
# MODERN PARALLEL DOWNLOAD MANAGER (v2.0)
# ==============================================================================

# Color & Style Definitions (Modern Palette)
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[38;5;39m"
GREEN="\033[38;5;78m"
RED="\033[38;5;203m"
YELLOW="\033[38;5;220m"
PURPLE="\033[38;5;135m"
BG_BAR="\033[48;5;236m"

# Utility: Draw Section Lines
draw_line() {
    echo -e "${DIM}${PURPLE}────────────────────────────────────────────────────────────${RESET}"
}

# Enter alternative screen buffer to protect user terminal history
trap 'echo -e "\033[?1049l"; exit' INT TERM EXIT
echo -e "\033[?1049h"

while true; do
    echo -e "\033[H\033[J" # Crisp clear
    echo -e "${BOLD}${PURPLE}┌──────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${PURPLE}│${RESET}  ${CYAN}🚀 MODERN MULTI-STREAM DOWNLOAD MANAGER v2.0${RESET}          ${BOLD}${PURPLE}│${RESET}"
    echo -e "${BOLD}${PURPLE}└──────────────────────────────────────────────────────────┘${RESET}\n"

    # Step 1: Dynamic Path Verification Loop
    echo -e "${BOLD}${CYAN}📁 Define Target Storage Directory${RESET}"
    echo -n -e "${DIM}👉 Path:${RESET} "
    read -r TARGET_DIR

    TARGET_DIR="${TARGET_DIR%/}"
    [ -z "$TARGET_DIR" ] && TARGET_DIR="."

    if [ -d "$TARGET_DIR" ]; then
        echo -e "\n${GREEN}✔ Directory Verified: ${BOLD}$TARGET_DIR${RESET}"
        sleep 1
        break
    else
        echo -e "\n${YELLOW}⚠ Directory does not exist.${RESET}"
        echo -n -e "👉 Create it now? (${GREEN}y${RESET}/${RED}n${RESET}): "
        read -r CREATE_CHOICE
        if [[ "$CREATE_CHOICE" =~ ^[Yy]$ ]]; then
            mkdir -p "$TARGET_DIR" 2>/dev/null
            if [ -d "$TARGET_DIR" ]; then
                echo -e "${GREEN}✔ Created successfully!${RESET}"
                sleep 1
                break
            else
                echo -e "${RED}❌ Permissions denied. Attempting with sudo...${RESET}"
                sudo mkdir -p "$TARGET_DIR" && sudo chmod 755 "$TARGET_DIR"
                break
            fi
        fi
    fi
done

# Step 2: Collect Links Loop
URLS=()
COUNTER=1

while true; do
    echo -e "\033[H\033[J"
    echo -e "${BOLD}${PURPLE}┌──────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${PURPLE}│${RESET}  ${CYAN}📥 BUILD YOUR DOWNLOAD QUEUE${RESET}                            ${BOLD}${PURPLE}│${RESET}"
    echo -e "${BOLD}${PURPLE}└──────────────────────────────────────────────────────────┘${RESET}"
    echo -e "${DIM}Type ${GREEN}'g'${DIM} to execute downloads | Total queued: ${BOLD}${YELLOW}${#URLS[@]}${RESET}\n"

    if [ ${#URLS[@]} -gt 0 ]; then
        echo -e "${BOLD}Current Queue:${RESET}"
        for url in "${URLS[@]}"; do
            echo -e "  ${DIM}- ${RESET}${url:0:60}..."
        done
        draw_line
    fi

    echo -e "${BOLD}${CYAN}[Link #$COUNTER]${RESET} Paste URL below:"
    echo -n -e "${DIM}👉 URL:${RESET} "
    read -r USER_INPUT

    if [[ "$USER_INPUT" =~ ^[Gg]$ ]]; then
        if [ ${#URLS[@]} -eq 0 ]; then
            echo -e "${RED}⚠ Your queue is empty! Add a link first.${RESET}"
            sleep 1.5
            continue
        fi
        break
    fi

    if [ -z "$USER_INPUT" ]; then
        continue
    fi

    URLS+=("$USER_INPUT")
    ((COUNTER++))
done

# Step 3: Initialize Background Engines
PIDS=()
LOG_FILES=()
FILENAMES=()

for i in "${!URLS[@]}"; do
    URL="${URLS[$i]}"
    FILENAME=$(basename "$URL" | cut -d? -f1)
    [ -z "$FILENAME" ] && FILENAME="stream_download_$(($i+1))"
    FILENAMES+=("$FILENAME")
    
    LOG_FILE="/tmp/curl_dl_$(($i+1)).log"
    LOG_FILES+=("$LOG_FILE")
    
    # Utilizing curl's text progress bar (#) for seamless shell scraping
    curl -L -o "$TARGET_DIR/$FILENAME" "$URL" -# > "$LOG_FILE" 2>&1 &
    PIDS+=($!)
done

# Step 4: Flickless Ultra-Monitor Engine
while true; do
    all_done=true
    # Reset cursor to top-left instead of wiping terminal (prevents flickering)
    echo -e "\033[H" 
    
    echo -e "${BOLD}${PURPLE}┌──────────────────────────────────────────────────────────┐${RESET}"
    echo -e "${BOLD}${PURPLE}│${RESET}  ${YELLOW}⚡ LIVE PARALLEL STREAM MONITOR${RESET}                         ${BOLD}${PURPLE}│${RESET}"
    echo -e "${BOLD}${PURPLE}└──────────────────────────────────────────────────────────┘${RESET}"
    echo -e "${DIM}Saving To:${RESET} $TARGET_DIR\n"

    for i in "${!PIDS[@]}"; do
        PID="${PIDS[$i]}"
        LOG_FILE="${LOG_FILES[$i]}"
        FILENAME="${FILENAMES[$i]}"

        # Truncate overly long file names neatly for the UI layout
        if [ ${#FILENAME} -gt 22 ]; then
            DISP_NAME="${FILENAME:0:19}..."
        else
            DISP_NAME=$(printf "%-22s" "$FILENAME")
        fi

        if ps -p $PID > /dev/null; then
            all_done=false
            
            # Scrape progress from curl's layout
            if [ -f "$LOG_FILE" ]; then
                RAW_PCT=$(tr '\r' '\n' < "$LOG_FILE" | grep -oE '[0-9.]+' | tail -n 1)
                PCT=${RAW_PCT%.*}
                [ -z "$PCT" ] && PCT=0
            else
                PCT=0
            fi

            # Build a smooth dynamic visual progress bar
            BAR_WIDTH=15
            FILLED_CHARS=$(( PCT * BAR_WIDTH / 100 ))
            EMPTY_CHARS=$(( BAR_WIDTH - FILLED_CHARS ))
            
            BAR=""
            for ((j=0; j<FILLED_CHARS; j++)); do BAR="${BAR}█"; done
            for ((j=0; j<EMPTY_CHARS; j++)); do BAR="${BAR}░"; done

            printf "${CYAN}%-22s${RESET} [${GREEN}%s${RESET}] ${BOLD}%3d%%${RESET} Processing...\n" "$DISP_NAME" "$BAR" "$PCT"
        else
            wait $PID 2>/dev/null
            STATUS=$?
            if [ $STATUS -eq 0 ]; then
                printf "${CYAN}%-22s${RESET} [███████████████] ${GREEN}✅ SUCCESS${RESET}       \n" "$DISP_NAME"
            else
                printf "${CYAN}%-22s${RESET} [███████████████] ${RED}❌ FAILED (${STATUS})${RESET}\n" "$DISP_NAME"
            fi
        fi
    done
    draw_line
    
    if $all_done; then
        break
    fi
    
    sleep 0.8
done

# Cleanup
rm -f /tmp/curl_dl_*.log

echo -e "\n${BOLD}${GREEN}🎉 ALL TRACKED JOBS COMPLETED!${RESET}"
echo -e "${DIM}Press [ENTER] to return to host terminal...${RESET}"
read -r

# Leave alternative buffer and restore original screen
echo -e "\033[?1049l"
