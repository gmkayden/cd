#!/usr/bin/env bash

# ================================
# Colors
# ================================
YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

LOG_FILE="ptero-gui.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# ================================
# Spinner Functions
# ================================
spinner() {
    local pid=$1
    local spin='-\|/'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i+1) %4 ))
        printf "\r${YELLOW}[%c] Working...${RESET}" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r${GREEN}[✔] Done${RESET}\n"
}

run_cmd() {
    bash -c "$1" &
    spinner $!
}

# ================================
# ASCII Banner (Yellow)
# ================================
clear
echo -e "${YELLOW}"
echo " ██████╗██╗      ██████╗ ██╗   ██╗██████╗ ███████╗██╗      █████╗ ██████╗ ███████╗"
echo " ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗██╔════╝██║     ██╔══██╗██╔══██╗██╔════╝"
echo " ██║     ██║     ██║   ██║██║   ██║██║  ██║█████╗  ██║     ███████║██████╔╝█████╗  "
echo " ██║     ██║     ██║   ██║██║   ██║██║  ██║██╔══╝  ██║     ██╔══██║██╔══██╗██╔══╝  "
echo " ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝██║     ███████╗██║  ██║██║  ██║███████╗"
echo "  ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝"
echo -e "${RESET}\n"

# ================================
# Root Check
# ================================
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}✗ Please run this script as root${RESET}"
    exit 1
fi

# ================================
# Install Cloudflared
# ================================
echo -e "${YELLOW}➤ Installing Cloudflare Tunnel (cloudflared)...${RESET}\n"

run_cmd "mkdir -p /usr/share/keyrings"

run_cmd "curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg \
| tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null"

run_cmd "echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' \
> /etc/apt/sources.list.d/cloudflared.list"

run_cmd "apt-get update -y"
run_cmd "apt-get install -y cloudflared"

# ================================
# Done
# ================================
echo -e "\n${GREEN}✅ Cloudflared installed successfully!${RESET}"
echo -e "${YELLOW}Next steps:${RESET}"
echo -e "  ${GREEN}Cloudflare Dashboard → Zero Trust → Tunnels → Create Tunnel${RESET}"
echo -e "\n${YELLOW}Binary:${RESET} ${GREEN}$(command -v cloudflared)${RESET}"
