#!/usr/bin/env bash
set -e

# --- Bright Color Definitions ---
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
PURPLE='\033[1;35m'
NC='\033[0m'

# --- Gist URLs ---
DEBIAN_SCRIPT="https://gist.githubusercontent.com/gmkayden/1dc1a786a0e0bc57c1841c39713c01ab/raw/dbac8c0e9cce71cace13b9d74cbd75327f5a25b1/debian-proxmox.sh"
UBUNTU_SCRIPT="https://gist.githubusercontent.com/gmkayden/cfbc10200dab105c2d1c1597551d5326/raw/199df7e01792ce1dca4380a35c589cf3e7f61a6a/ubuntu-proxmox.sh"
RHEL_SCRIPT="https://gist.githubusercontent.com/gmkayden/d1072fdaa3f29bab7dc62a7a48e4cd54/raw/48f74e856963c5eb2fea490e4a1d783fda1d4438/rhel-proxmox.sh"
DOCKER_SCRIPT="https://gist.githubusercontent.com/gmkayden/606f463146d60d12c523894459fd256c/raw/3d057c2c20ae4afdd13bb0f43fa63a3cd3c5fe54/docker-proxmox.sh"

# --- Root Check ---
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Run as root!${NC}"
    exit 1
fi

touch /var/log/proxmox-install.log

# --- Spinner Executor ---
execute() {
    local MSG="$1"
    local CMD="$2"

    echo -e "${BLUE}*${NC} ${YELLOW}${MSG}${NC}..."

    (
        set +e
        eval "$CMD"
    ) >> /var/log/proxmox-install.log 2>&1 &

    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 10 ))
        printf "\r${BLUE}*${NC} ${YELLOW}${MSG}${NC} ${BLUE}${spin:$i:1}${NC}"
        sleep 0.1
    done

    wait "$pid"
    local status=$?

    if [ "$status" -eq 0 ]; then
        printf "\r${BLUE}*${NC} ${YELLOW}${MSG}${NC} ${GREEN}Done!${NC}\n"
    else
        printf "\r${BLUE}*${NC} ${YELLOW}${MSG}${NC} ${RED}Failed!${NC}\n"
        exit 1
    fi
}

# --- Pre Setup (GRUB fix) ---
pre_setup_fix() {
    if [ -f /etc/debian_version ] || [ -f /etc/lsb-release ]; then
        execute "Pre-seeding GRUB Configuration" '
        export DEBIAN_FRONTEND=noninteractive
        export DEBCONF_NONINTERACTIVE_SEEN=true
        BOOT_DISK=$(find /dev/disk/by-id/ -type l | head -n 1)
        echo "grub-pc grub-pc/install_devices_empty boolean false" | debconf-set-selections
        echo "grub-pc grub-pc/install_devices multiselect $BOOT_DISK" | debconf-set-selections
        dpkg --configure -a || true
        '
    fi
}

# --- Animated Exit ---
animated_exit() {
    clear
    MSG1="Bye!"
    MSG2="Made With ❤ By Eiro & GMK"

    for ((i=1; i<=${#MSG1}; i++)); do
        echo -ne "${GREEN}${MSG1:0:i}${NC}\r"
        sleep 0.08
    done
    echo
    sleep 0.3

    for ((i=1; i<=${#MSG2}; i++)); do
        echo -ne "${PURPLE}${MSG2:0:i}${NC}\r"
        sleep 0.05
    done
    echo
    sleep 0.5
    exit 0
}

# --- Menu ---
show_menu() {
    clear
    echo -e "${YELLOW}"
    echo "██████╗ ██████╗  ██████╗ ██╗  ██╗███╗   ███╗ ██████╗ ██╗  ██╗"
    echo "██╔══██╗██╔══██╗██╔═══██╗╚██╗██╔╝████╗ ████║██╔═══██╗╚██╗██╔╝"
    echo "██████╔╝██████╔╝██║   ██║ ╚███╔╝ ██╔████╔██║██║   ██║ ╚███╔╝"
    echo "██╔═══╝ ██╔══██╗██║   ██║ ██╔██╗ ██║╚██╔╝██║██║   ██║ ██╔██╗"
    echo "██║     ██║  ██║╚██████╔╝██╔╝ ██╗██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗"
    echo "╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
    echo -e "${NC}"

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "              ${YELLOW}PROXMOX INSTALLATION${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${BLUE}1)${NC} ${YELLOW}Ubuntu 22.04${NC}"
    echo -e " ${BLUE}2)${NC} ${YELLOW}Ubuntu 24.04${NC}"
    echo -e " ${BLUE}3)${NC} ${YELLOW}Debian 11${NC}"
    echo -e " ${BLUE}4)${NC} ${YELLOW}Debian 12${NC}"
    echo -e " ${BLUE}5)${NC} ${YELLOW}Debian 13${NC}"
    echo -e " ${BLUE}6)${NC} ${YELLOW}AlmaLinux 9${NC}"
    echo -e " ${BLUE}7)${NC} ${YELLOW}RockyLinux 9${NC}"
    echo -e " ${BLUE}8)${NC} ${YELLOW}Docker${NC}"
    echo -e " ${BLUE}0)${NC} ${YELLOW}Exit${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -ne "\n${YELLOW}Select an option:${NC} "
    read -r OPT
}

# --- Main ---
show_menu

case "$OPT" in
    1|2)
        pre_setup_fix
        bash <(curl -fsSL "$UBUNTU_SCRIPT")
        ;;
    3|4|5)
        pre_setup_fix
        bash <(curl -fsSL "$DEBIAN_SCRIPT")
        ;;
    6|7)
        bash <(curl -fsSL "$RHEL_SCRIPT")
        ;;
    8)
        bash <(curl -fsSL "$DOCKER_SCRIPT")
        ;;
    0)
        animated_exit
        ;;
    *)
        echo -e "${RED}Invalid option!${NC}"
        sleep 1.5
        exec "$0"
        ;;
esac
