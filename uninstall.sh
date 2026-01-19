#!/usr/bin/env bash
# ==================================================
# PTERODACTYL FULL NUKE (Wipe Everything)
# UI: Clean / Theme: Cyan & Red / Feature: Total Removal
# ==================================================

# ---------------- LOGGING SETUP ----------------
LOG_FILE="/root/ptero-gui.log"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="./ptero_nuke.log"

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
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] NUKING: $msg" >> "$LOG_FILE"
    echo -ne "${C_BLUE}⏳ ${msg}...${C_RESET}"
    
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    tput civis
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 9); do
            echo -ne "${C_RED}${spin:$i:1}${C_RESET}\b"
            sleep 0.1
        done
    done
    tput cnorm
    
    wait $pid
    echo -e "\r${C_GREEN}✔ ${msg} Removed!${C_RESET}"
}

banner(){
clear
echo -e "${C_RED}"
cat << "EOF"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
███╗   ██╗██╗   ██╗██╗  ██╗███████╗
████╗  ██║██║   ██║██║ ██╔╝██╔════╝
██╔██╗ ██║██║   ██║█████╔╝ █████╗  
██║╚██╗██║██║   ██║██╔═██╗ ██╔══╝  
██║ ╚████║╚██████╔╝██║  ██╗███████╗
╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
           UNINSTALLATION PROCESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
echo -e "${C_RESET}"
}

# ---------------- PRE-CHECKS ----------------
if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}Error: You must be root to nuke the system.${C_RESET}"
   exit 1
fi

banner
warn "THIS WILL PERMANENTLY DELETE ALL DATABASES, FILES, AND USERS."
echo -e "${C_WHITE}This includes: Panel, Wings, MariaDB, PHP, Redis, and Nginx.${C_RESET}"
line
read -p "Type 'NUKE' to confirm destruction: " CONFIRM

if [[ "$CONFIRM" != "NUKE" ]]; then
    echo -e "${C_GREEN}Nuke aborted. System remains intact.${C_RESET}"
    exit 0
fi

# ---------------- THE NUKE PROCESS ----------------
step "Phase 1: Killing Services"
execute "Stopping Pterodactyl Services" "systemctl stop pteroq wings 2>/dev/null"
execute "Stopping Web & DB Services" "systemctl stop nginx mariadb mysql redis-server 2>/dev/null"

step "Phase 2: Removing Files"
execute "Deleting Panel & Wings Files" "rm -rf /var/www/pterodactyl /etc/pterodactyl /var/lib/pterodactyl"
execute "Deleting Configs & SSL" "rm -rf /etc/certs/panel /etc/certs/wing /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf"

step "Phase 3: Purging Packages (The Heavy Part)"
# This part removes the actual software from the OS
execute "Uninstalling MariaDB & MySQL" "apt-get purge -y mariadb-server mariadb-client mysql-server mysql-client mysql-common && rm -rf /var/lib/mysql /etc/mysql"
execute "Uninstalling PHP & Extensions" "apt-get purge -y php8.* && apt-get autoremove -y"
execute "Uninstalling Redis & Nginx" "apt-get purge -y redis-server nginx && rm -rf /etc/nginx /var/lib/redis"

step "Phase 4: Cleanup"
execute "Removing Systemd Services" "rm -f /etc/systemd/system/pteroq.service /etc/systemd/system/wings.service && systemctl daemon-reload"
execute "Clearing Cronjobs" "crontab -r 2>/dev/null"



line
echo -e "${C_GREEN}✅ THE SYSTEM HAS BEEN COMPLETELY PURGED.${C_RESET}"
echo -e "${C_WHITE}Your VPS is now clean. Ready for a fresh install.${C_RESET}"
line
