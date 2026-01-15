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

# ===== Bright Colors =====
BRIGHT_RED='\033[1;91m'
BRIGHT_GREEN='\033[1;92m'
BRIGHT_YELLOW='\033[1;93m'
BRIGHT_BLUE='\033[1;94m'
BRIGHT_PURPLE='\033[1;95m'
BRIGHT_CYAN='\033[1;96m'
NC='\033[0m'

# Spinner
spinner() {
    local pid="$1"
    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r${BRIGHT_CYAN}Working... %s${NC}" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r${BRIGHT_GREEN}✔ Done!${NC}\n"
}

# ASCII Logo (Bright Yellow)
ascii_logo() {
    clear
    echo -e "${BRIGHT_YELLOW}███████╗ █████╗ ███████╗████████╗███████╗███████╗████████╗ ██████╗██╗  ██╗${NC}"
    echo -e "${BRIGHT_YELLOW}██╔════╝██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔════╝╚══██╔══╝██╔════╝██║  ██║${NC}"
    echo -e "${BRIGHT_YELLOW}█████╗  ███████║███████╗   ██║   █████╗  █████╗     ██║   ██║     ███████║${NC}"
    echo -e "${BRIGHT_YELLOW}██╔══╝  ██╔══██║╚════██║   ██║   ██╔══╝  ██╔══╝     ██║   ██║     ██╔══██║${NC}"
    echo -e "${BRIGHT_YELLOW}██║     ██║  ██║███████║   ██║   ██║     ███████╗   ██║   ╚██████╗██║  ██║${NC}"
    echo -e "${BRIGHT_YELLOW}╚═╝     ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝     ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝${NC}"
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64) ARCH="amd64" ;;
        aarch64|arm64) ARCH="arm64" ;;
        *)
            echo -e "${BRIGHT_RED}Unsupported architecture${NC}" | tee -a "$LOG_FILE"
            exit 1
            ;;
    esac
}

# Download deb
download_deb() {
    detect_arch
    DEB_URL="$GITHUB_BASE/fastfetch-linux-$ARCH.deb"
    echo -e "${BRIGHT_CYAN}Downloading Fastfetch ($ARCH)...${NC}"
    wget -q "$DEB_URL" -O "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
}

# Install
install_fastfetch() {
    download_deb
    echo -e "${BRIGHT_GREEN}Installing Fastfetch...${NC}"
    sudo apt install -y "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
    rm -f "$TMP_DEB"

    if command -v fastfetch >/dev/null 2>&1; then
        echo -e "${BRIGHT_GREEN}✔ Fastfetch installed successfully!${NC}"
        echo -e "${BRIGHT_GREEN}Run : fastfetch to use FastFetch${NC}"
    else
        echo -e "${BRIGHT_RED}❌ Installation failed. Check fastfetch.log${NC}"
    fi
}

# Update
update_fastfetch() {
    download_deb
    echo -e "${BRIGHT_PURPLE}Updating Fastfetch...${NC}"
    sudo apt install -y "$TMP_DEB" >>"$LOG_FILE" 2>&1 &
    spinner $!
    rm -f "$TMP_DEB"

    if command -v fastfetch >/dev/null 2>&1; then
        echo -e "${BRIGHT_PURPLE}✔ Fastfetch updated successfully!${NC}"
        echo -e "${BRIGHT_PURPLE}Run : fastfetch to use FastFetch${NC}"
    else
        echo -e "${BRIGHT_RED}❌ Update failed. Check fastfetch.log${NC}"
    fi
}

# Uninstall
uninstall_fastfetch() {
    echo -e "${BRIGHT_RED}Uninstalling Fastfetch...${NC}"
    sudo dpkg -r fastfetch >>"$LOG_FILE" 2>&1 &
    spinner $!

    if ! command -v fastfetch >/dev/null 2>&1; then
        echo -e "${BRIGHT_RED}✔ Fastfetch removed successfully${NC}"
    else
        echo -e "${BRIGHT_RED}❌ Uninstall failed. Check fastfetch.log${NC}"
    fi
}

# Menu
menu() {
    echo -e "${BRIGHT_BLUE}1) Install FastFetch${NC}"
    echo -e "${BRIGHT_BLUE}2) Update FastFetch${NC}"
    echo -e "${BRIGHT_BLUE}3) Uninstall FastFetch${NC}"
    echo -e "${BRIGHT_BLUE}0) Exit${NC}"
    echo
    read -rp "Select an option: " choice

    case "$choice" in
        1) install_fastfetch ;;
        2) update_fastfetch ;;
        3) uninstall_fastfetch ;;
        0)
            echo
            echo -e "${BRIGHT_CYAN}Bye 👋${NC}"
            echo -e "${BRIGHT_CYAN}Made With ❤ By Eiro (eiro.tf)${NC}"
            exit 0
            ;;
        *)
            echo -e "${BRIGHT_RED}* Invalid Option! Please Try Again!${NC}"
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
