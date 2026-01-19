#!/usr/bin/env bash
# ====================================================
#      PTERODACTYL INSTALL / USER / UPDATE / REMOVE
# ====================================================

GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
CYAN="\033[1;36m"
NC="\033[0m"

# ================== INSTALL FUNCTION ==================
install_ptero() {
    clear
    echo -e "${CYAN}"
    echo "┌──────────────────────────────────────────────┐"
    echo "│        🚀 Pterodactyl Installation            │"
    echo "└──────────────────────────────────────────────┘${NC}"
    bash <(curl -s https://raw.githubusercontent.com/gmkayden/cd/refs/heads/main/ptero.sh)
    echo -e "${GREEN}✔ Installation Complete${NC}"
    read -p "Press Enter to return..."
}

# ================== CREATE USER ==================
create_user() {
    clear
    echo -e "${CYAN}"
    echo "┌──────────────────────────────────────────────┐"
    echo "│        👤 Create Pterodactyl User             │"
    echo "└──────────────────────────────────────────────┘${NC}"

    if [ ! -d /var/www/pterodactyl ]; then
        echo -e "${RED}❌ Panel not installed!${NC}"
        read -p "Press Enter to return..."
        return
    fi

    cd /var/www/pterodactyl || exit
    php artisan p:user:make

    echo -e "${GREEN}✔ User created successfully${NC}"
    read -p "Press Enter to return..."
}

# ===================== MENU =====================
while true; do
clear
echo -e "${YELLOW}"
echo "╔═══════════════════════════════════════════════╗"
echo "║        🐲 PTERODACTYL CONTROL CENTER           ║"
echo "╠═══════════════════════════════════════════════╣"
echo -e "║ ${GREEN}1) Install Panel${NC}"
echo -e "║ ${CYAN}2) Create Panel User${NC}"
echo -e "║ 0) Exit"
echo "╚═══════════════════════════════════════════════╝"
echo -ne "${CYAN}Select Option → ${NC}"
read choice

case $choice in
    1) install_ptero ;;
    2) create_user ;;
    0) clear; exit ;;
    *) echo -e "${RED}Invalid Option!${NC}"; sleep 1 ;;
esac
done
