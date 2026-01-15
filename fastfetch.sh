#!/usr/bin/env bash

# ================================
# Fastfetch GUI Installer (.deb)
# Made With ❤ By Eiro (eiro.tf)
# ================================

LOG_FILE="./fastfetch.log"
TMP_DEB="/tmp/fastfetch.deb"
GITHUB_BASE="https://github.com/fastfetch-cli/fastfetch/releases/latest/download"

# Create log file
touch "$LOG_FILE"

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
LIME='\033[1;92m'
PURPLE='\033[1;35m'
CYAN='\033[1;36m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Spinner
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

# ASCII Logo (Yellow)
ascii_logo() {
    clear
    echo -e "${YELLOW}███████╗ █████╗ ███████╗████████╗███████╗███████╗████████╗ ██████╗██╗  ██╗${NC}"
    echo -e "${YELLOW}██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║${NC}"
    echo -e "${YELLOW}█████╗  ███████║███████╗   ██║   █████╗  █████╗     ██║   ██║     ███████║${NC}"
    echo -e "${YELLOW}██╔══╝  ██╔══██║╚════██║   ██║   ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║${NC}"
    echo -e "${YELLOW}██║     ██║  ██║███████║   ██║   ██║     ███████╗   ██║   ╚██████╗██║  ██║${NC}"
    echo -e "${YELLOW}╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝${NC}"
}

# Detect architecture
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

# Download .deb
download_deb() {
    detect_arch
    DEB_URL="$GITHUB_BASE/fastfetch-linux-$ARCH.deb"
    echo -e "${CYAN}Downloading Fastfetch ($ARCH)...${NC}"
    wget -q "$DEB_URL" -O "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
}

# Install
install_fastfetch() {
    download_deb
    echo -e "${LIME}Installing Fastfetch...${NC}"
    sudo apt install -y "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
    rm -f "$TMP_DEB"

    if command -v fastfetch >/dev/null 2>&1; then
        echo -e "${LIME}✔ Fastfetch installed successfully!${NC}"
    else
        echo -e "${RED}❌ Installation failed. Check fastfetch.log${NC}"
    fi
}

# Update
update_fastfetch() {
    download_deb
    echo -e "${PURPLE}Updating Fastfetch...${NC}"
    sudo apt install -y "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
    rm -f "$TMP_DEB"

    if command -v fastfetch >/dev/null 2>&1; then
        echo -e "${PURPLE}✔ Fastfetch updated successfully!${NC}"
    else
        echo -e "${RED}❌ Update failed. Check fastfetch.log${NC}"
    fi
}

# Uninstall
uninstall_fastfetch() {
    echo -e "${RED}Uninstalling Fastfetch...${NC}"
    sudo dpkg -r fastfetch >>"$LOG_FILE" 2>&1 &
    spinner $!

    if ! command -v fastfetch >/dev/null 2>&1; then
        echo -e "${RED}✔ Fastfetch removed successfully${NC}"
    else
        echo -e "${RED}❌ Uninstall failed. Check fastfetch.log${NC}"
    fi
}

# Menu
menu() {
    echo -e "${BLUE}1) Install FastFetch${NC}"
    echo -e "${BLUE}2) Update FastFetch${NC}"
    echo -e "${BLUE}3) Uninstall FastFetch${NC}"
    echo -e "${BLUE}0) Exit${NC}"
    echo
    read -rp "Select an option: " choice

    case "$choice" in
        1) install_fastfetch ;;
        2) update_fastfetch ;;
        3) uninstall_fastfetch ;;
        0)
            echo
            echo "Bye 👋"
            echo "Made With ❤ By Eiro (eiro.tf)"
            exit 0
            ;;
        *)
            echo -e "${RED}* Invalid Option! Please Try Again!${NC}"
            sleep 1
            ;;
    esac
}

# Main loop
while true; do
    ascii_logo
    menu
    echo
    read -rp "Press Enter to continue..."
done
