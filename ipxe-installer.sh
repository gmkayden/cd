#!/bin/bash
set -e

# --- Dark & Bold Color Definitions ---
DARK_BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- Gist URLs ---
DEBIAN_SCRIPT="https://gist.githubusercontent.com/eclipseprotocoll/e7d44c2e3438bd3345eca714e5945ae3/raw/59f6a90179a889ecb3024092a36201d6612ad9cb/gistfile1.txt"
UBUNTU_SCRIPT="https://gist.githubusercontent.com/eclipseprotocoll/fc84d6ebe10923b60b2426a83cd4480d/raw/62d5a7b29be6489350d2e68826780b761747f63e/gistfile1.txt"
RHEL_SCRIPT="https://gist.githubusercontent.com/eclipseprotocoll/fe61af03051183fe9363d6b374e8d34a/raw/8f67908d61d98e4a63b55487c04f665055af88a8/rhel.sh"
DOCKER_SCRIPT="https://gist.githubusercontent.com/eclipseprotocoll/b05cda026e23999a5cd243ab1000f495/raw/f4145237c0bba68272f19c46256396f982dcc862/gistfile1.txt"

# --- UI Engine ---
execute() {
    local MSG="$1"
    local CMD="$2"

    echo -e "${DARK_BLUE}*${NC} ${YELLOW}${MSG}${NC}..."

    (
        set +e
        eval "$CMD"
    ) >> /var/log/proxmox-install.log 2>&1 &

    local pid=$!
    local spin='-\|/'
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r${DARK_BLUE}*${NC} ${YELLOW}${MSG}${NC} (${DARK_BLUE}${spin:$i:1}${NC}) "
        sleep 0.1
    done

    wait "$pid"
    local status=$?

    if [ "$status" -eq 0 ]; then
        printf "\r${DARK_BLUE}*${NC} ${YELLOW}${MSG}${NC} ${GREEN}Done!${NC}\n"
    else
        printf "\r${DARK_BLUE}*${NC} ${YELLOW}${MSG}${NC} ${RED}Failed!${NC}\n"
        exit 1
    fi
}

# --- Pre-Setup Fixes ---
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

show_menu() {
    clear
    echo -e "${DARK_BLUE}"
    echo " ██████╗ ███╗   ███╗██╗  ██╗"
    echo "██╔════╝ ████╗ ████║██║ ██╔╝"
    echo "██║  ███╗██╔████╔██║█████╔╝ "
    echo "██║   ██║██║╚██╔╝██║██╔═██╗ "
    echo "╚██████╔╝██║ ╚═╝ ██║██║  ██╗"
    echo " ╚═════╝ ╚═╝     ╚═╝╚═╝  ╚═╝"
    echo -e "${NC}"

    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "              ${YELLOW}PROXMOX INSTALLATION${NC}             "
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e " ${DARK_BLUE}1)${NC} ${YELLOW}Ubuntu 22.04${NC}"
    echo -e " ${DARK_BLUE}2)${NC} ${YELLOW}Ubuntu 24.04${NC}"
    echo -e " ${DARK_BLUE}3)${NC} ${YELLOW}Debian 11${NC}"
    echo -e " ${DARK_BLUE}4)${NC} ${YELLOW}Debian 12${NC}"
    echo -e " ${DARK_BLUE}5)${NC} ${YELLOW}Debian 13${NC}"
    echo -e " ${DARK_BLUE}6)${NC} ${YELLOW}AlmaLinux 9${NC}"
    echo -e " ${DARK_BLUE}7)${NC} ${YELLOW}Rocky Linux 9${NC}"
    echo -e " ${DARK_BLUE}8)${NC} ${YELLOW}Docker${NC}"
    echo -e " ${DARK_BLUE}0)${NC} ${YELLOW}Exit${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -ne "\n${YELLOW}Select an option:${NC} "
    read -r OPT
}

# --- Main Logic ---
[ "$EUID" -ne 0 ] && { echo -e "${RED}Run as root!${NC}"; exit 1; }

touch /var/log/proxmox-install.log

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
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option.${NC}"
        sleep 2
        exec "$0"
        ;;
esac
