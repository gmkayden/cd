#!/usr/bin/env bash

# ================================
# Fastfetch GUI Installer (.deb)
# ================================

LOG_FILE="./fastfetch.log"
TMP_DEB="/tmp/fastfetch.deb"
GITHUB_BASE="https://github.com/fastfetch-cli/fastfetch/releases/latest/download"

touch "$LOG_FILE"

# ===== TRUE BRIGHT COLORS (256-color) =====
YELLOW='\033[38;5;226m'   # Bright yellow
BLUE='\033[38;5;39m'      # Bright blue
GREEN='\033[38;5;82m'     # Lime green
PURPLE='\033[38;5;201m'   # Bright purple
RED='\033[38;5;196m'      # Bright red
CYAN='\033[38;5;51m'      # Bright cyan
NC='\033[0m'

spinner() {
    local pid="$1"
    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r${CYAN}Working... %s${NC}" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r${GREEN}✔ Done!${NC}\n"
}

ascii_logo() {
    clear
    echo -e "${YELLOW}███████╗ █████╗ ███████╗████████╗███████╗███████╗████████╗ ██████╗██╗  ██╗${NC}"
    echo -e "${YELLOW}██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║${NC}"
    echo -e "${YELLOW}█████╗  ███████║███████╗   ██║   █████╗  █████╗     ██║   ██║     ███████║${NC}"
    echo -e "${YELLOW}██╔══╝  ██╔══██║╚════██║   ██║   ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║${NC}"
    echo -e "${YELLOW}██║     ██║  ██║███████║   ██║   ██║     ███████╗   ██║   ╚██████╗██║  ██║${NC}"
    echo -e "${YELLOW}╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝${NC}"
}

detect_arch() {
    case "$(uname -m)" in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *)
            echo -e "${RED}Unsupported architecture${NC}" | tee -a "$LOG_FILE"
            exit 1
            ;;
    esac
}

download_deb() {
    detect_arch
    DEB_URL="$GITHUB_BASE/fastfetch-linux-$ARCH.deb"
    echo -e "${CYAN}Downloading Fastfetch ($ARCH)...${NC}"
    wget -q "$DEB_URL" -O "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
}

install_fastfetch() {
    download_deb
    echo -e "${GREEN}Installing Fastfetch...${NC}"
    sudo apt install -y "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
    rm -f "$TMP_DEB"
    echo -e "${GREEN}Run : fastfetch to use FastFetch${NC}"
}

update_fastfetch() {
    download_deb
    echo -e "${PURPLE}Updating Fastfetch...${NC}"
    sudo apt install -y "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
    rm -f "$TMP_DEB"
    echo -e "${PURPLE}Run : fastfetch to use FastFetch${NC}"
}

uninstall_fastfetch() {
    echo -e "${RED}Uninstalling Fastfetch...${NC}"
    sudo dpkg -r fastfetch >>"$LOG_FILE" 2>&1 &
    spinner $!
}

menu() {
    echo -e "${BLUE}1) Install FastFetch${NC}"
    echo -e "${BLUE}2) Update FastFetch${NC}"
    echo -e "${BLUE}3) Uninstall FastFetch${NC}"
    echo -e "${BLUE}0) Exit${NC}"
    read -rp "Select an option: " choice

    case "$choice" in
        1) install_fastfetch ;;
        2) update_fastfetch ;;
        3) uninstall_fastfetch ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid option${NC}" ;;
    esac
}

while true; do
    ascii_logo
    menu
    echo
    read -rp "Press Enter to continue..."
done
