#!/usr/bin/env bash
# ==================================================
# PTERODACTYL DATABASE MANAGER (REMOTE ACCESS)
# UI: Clean / Theme: Cyan & Red / Feature: Spinners
# ==================================================

# ---------------- LOGGING SETUP ----------------
LOG_FILE="/root/ptero-gui.log"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="./ptero_db.log"

# ---------------- UI COLORS ----------------
C_RESET="\e[0m"
C_RED="\e[1;31m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_PURPLE="\e[1;35m"
C_CYAN="\e[1;36m"
C_WHITE="\e[1;37m"
C_GRAY="\e[1;90m"

# ---------------- UI FUNCTIONS ----------------
line(){ echo -e "${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }
step(){ echo -e "${C_BLUE}➜ $1${C_RESET}"; }
ok(){ echo -e "${C_GREEN}✔ $1${C_RESET}"; }
warn(){ echo -e "${C_YELLOW}⚠ $1${C_RESET}"; }

banner_db(){
clear
echo -e "${C_RED}"
cat << "EOF"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
██████╗  █████╗ ████████╗ █████╗ ██████╗  █████╗ ███████╗███████╗
██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝
██║  ██║███████║   ██║   ███████║██████╔╝███████║███████╗█████╗  
██║  ██║██╔══██║   ██║   ██╔══██║██╔══██╗██╔══██║╚════██║██╔══╝  
██████╔╝██║  ██║   ██║   ██║  ██║██████╔╝██║  ██║███████║███████╗
╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
               DATABASE REMOTE SETUP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
echo -e "${C_RESET}"
}

# ---------------- SPINNER LOGIC ----------------
execute() {
    local msg="$1"
    local cmd="$2"
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STARTING: $msg" >> "$LOG_FILE"
    echo -ne "${C_BLUE}⏳ ${msg}...${C_RESET}"
    
    eval "$cmd" >> "$LOG_FILE" 2>&1 &
    local pid=$!
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    tput civis # Hide cursor
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 9); do
            echo -ne "${C_CYAN}${spin:$i:1}${C_RESET}\b"
            sleep 0.1
        done
    done
    tput cnorm # Show cursor
    
    wait $pid
    local status=$?
    
    if [ $status -eq 0 ]; then
        echo -e "\r${C_GREEN}✔ ${msg} Finished!${C_RESET}"
    else
        echo -e "\r${C_RED}✘ ${msg} Failed! Check $LOG_FILE${C_RESET}"
        exit 1
    fi
}

# ---------------- MAIN LOGIC ----------------

# Check root
if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}Error: This script must be run as root.${C_RESET}"
   exit 1
fi

banner_db
step "Database Configuration Gathering"
read -p "Enter new database username: " DB_USER
read -sp "Enter password for $DB_USER: " DB_PASS
echo -e "\n"

# Step 1: SQL User Creation
execute "Creating database user '$DB_USER'" "mysql -u root <<MYSQL_SCRIPT
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
MYSQL_SCRIPT"

# Step 2: Bind-Address modification

CONF_FILE="/etc/mysql/mariadb.conf.d/50-server.cnf"
if [ -f "$CONF_FILE" ]; then
    execute "Updating bind-address in $CONF_FILE" "sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' $CONF_FILE"
else
    warn "Config file not found: $CONF_FILE"
    # Check for standard MySQL path if MariaDB path fails
    ALT_CONF="/etc/mysql/my.cnf"
    if [ -f "$ALT_CONF" ]; then
        execute "Updating bind-address in $ALT_CONF" "sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' $ALT_CONF"
    fi
fi

# Step 3: Service Restart
execute "Restarting Database Services" "systemctl restart mysql 2>/dev/null; systemctl restart mariadb 2>/dev/null"

# Step 4: Firewall Setup
if command -v ufw &>/dev/null; then
    execute "Opening port 3306 for remote connections" "ufw allow 3306/tcp"
fi

line
ok "Database user '$DB_USER' created and remote access enabled!"
echo -e "${C_WHITE}IP Address: $(curl -s https://ifconfig.me)${C_RESET}"
echo -e "${C_WHITE}Port: 3306${C_RESET}"
line

echo -e ""
read -p "Press Enter to continue..." -n 1
