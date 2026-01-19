#!/usr/bin/env bash
# ==================================================
# PTERODACTYL UPDATE MASTER (Panel & Wings)
# UI: Clean / Theme: Cyan & Red / Feature: Safe Logging
# ==================================================

# ---------------- LOGGING SETUP ----------------
LOG_FILE="/root/ptero_update.log"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="./ptero_update.log"

# ---------------- UI THEME ----------------
C_RESET="\e[0m"
C_RED="\e[1;31m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_PURPLE="\e[1;35m"
C_CYAN="\e[1;36m"
C_WHITE="\e[1;37m"
C_GRAY="\e[1;90m"

line(){ echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }
step(){ echo -e "${C_BLUE}➜ $1${C_RESET}"; }
ok(){ echo -e "${C_GREEN}✔ $1${C_RESET}"; }
warn(){ echo -e "${C_YELLOW}⚠ $1${C_RESET}"; }

execute() {
    local msg="$1"
    local cmd="$2"
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STARTING: $msg" >> "$LOG_FILE"
    echo -ne "${C_BLUE}⏳ ${msg}...${C_RESET}"
    
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    tput civis
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 9); do
            echo -ne "${C_CYAN}${spin:$i:1}${C_RESET}\b"
            sleep 0.1
        done
    done
    tput cnorm
    
    wait $pid
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS: $msg" >> "$LOG_FILE"
        echo -e "\r${C_GREEN}✔ ${msg} Finished!${C_RESET}"
    else
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] FAILED: $msg (Exit: $status)" >> "$LOG_FILE"
        echo -e "\r${C_RED}✘ ${msg} Failed! Check $LOG_FILE${C_RESET}"
        return 1
    fi
}

banner(){
clear
echo -e "${C_CYAN}"
cat << "EOF"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗
██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  
██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  
╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗
 ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
               UPDATE PANEL + WINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
echo -e "${C_RESET}"
}

# ---------------- PANEL UPDATE ----------------
update_panel() {
    banner
    step "Initiating Panel Update"
    
    if [ ! -d "/var/www/pterodactyl" ]; then
        warn "Panel directory not found at /var/www/pterodactyl"
        sleep 2; return
    fi

    cd /var/www/pterodactyl
    execute "Entering Maintenance Mode" "php artisan down"
    execute "Downloading Latest Files" "curl -L https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz | tar -xzv"
    execute "Setting Permissions" "chmod -R 755 storage/* bootstrap/cache"
    execute "Updating Dependencies" "COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader"
    execute "Running Database Migrations" "php artisan migrate --seed --force"
    execute "Clearing Cache & Views" "php artisan view:clear && php artisan config:clear"
    execute "Finalizing Permissions" "chown -R www-data:www-data /var/www/pterodactyl/*"
    execute "Restarting Background Workers" "systemctl restart pteroq"
    execute "Exiting Maintenance Mode" "php artisan up"

    ok "Pterodactyl Panel updated successfully!"
    sleep 2
}

# ---------------- WINGS UPDATE ----------------
update_wings() {
    banner
    step "Initiating Wings Update"
    
    if [ ! -f "/usr/local/bin/wings" ]; then
        warn "Wings binary not found at /usr/local/bin/wings"
        sleep 2; return
    fi

    ARCH=$(uname -m)
    [ "$ARCH" == "x86_64" ] && W_ARCH="amd64" || W_ARCH="arm64"

    execute "Stopping Wings Daemon" "systemctl stop wings"
    execute "Downloading Wings ($W_ARCH)" "curl -L -o /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$W_ARCH"
    execute "Fixing Binary Permissions" "chmod u+x /usr/local/bin/wings"
    execute "Restarting Wings Daemon" "systemctl start wings"

    ok "Pterodactyl Wings updated successfully!"
    sleep 2
}

# ---------------- MAIN MENU ----------------
while true; do
    banner
    echo -e "${C_WHITE}1)${C_RESET} ${C_CYAN}Update Pterodactyl Panel${C_RESET}"
    echo -e "${C_WHITE}2)${C_RESET} ${C_CYAN}Update Pterodactyl Wings${C_RESET}"
    echo -e "${C_WHITE}3)${C_RESET} ${C_CYAN}Update Full System (Both)${C_RESET}"
    echo -e "${C_WHITE}0)${C_RESET} ${C_RED}Exit Update Master${C_RESET}"
    line
    read -p "Select an option: " OPT
    case $OPT in
        1) update_panel ;;
        2) update_wings ;;
        3) update_panel; update_wings ;;
        0) exit 0 ;;
        *) warn "Invalid Option" ; sleep 1 ;;
    esac
done
