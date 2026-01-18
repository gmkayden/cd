#!/usr/bin/env bash
# ==================================================
# PTERODACTYL PANEL AUTO INSTALLER (V1.0 FINAL)
# UI: Clean / Theme: Cyan & Red / Log: /root/ptero-gui.log
# ==================================================

# ---------------- LOGGING SETUP ----------------
LOG_FILE="/root/ptero-gui.log"
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="./ptero-gui.log"

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

draw_box() {
    local str="$1"
    local width=60
    local len=${#str}
    local padding=$(( (width - len) / 2 )) 
    local extra=$(( (width - len) % 2 ))
    printf "${C_CYAN}║${C_RESET}%*s%s%*s${C_CYAN}║${C_RESET}\n" $padding "" "$str" $((padding + extra)) ""
}

execute() {
    local msg="$1"
    local cmd="$2"
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] STARTING: $msg" >> "$LOG_FILE"
    echo -ne "${C_BLUE}⏳ ${msg}...${C_RESET}"
    
    # Execute command, redirecting all output to the log file
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
        exit 1
    fi
}

banner(){
clear
echo -e "${C_CYAN}"
cat << "EOF"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ██████╗  █████╗ ███╗   ██╗███████╗██╗     
   ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     
   ██████╔╝███████║██╔██╗ ██║█████╗  ██║     
   ██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║     
   ██║     ██║  ██║██║ ╚████║███████╗███████╗
   ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝ 
          PANEL INSTALLATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
echo -e "${C_RESET}"
}

# ---------------- PRE-CHECKS ----------------
if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}Error: You must run this script as root.${C_RESET}"
   exit 1
fi

# ---------------- START ----------------
banner
read -p "🌐 Enter domain (e.g. panel.example.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    echo -e "${C_RED}Domain cannot be empty.${C_RESET}"
    exit 1
fi

PHP_VER="8.3"
DB_PASS=$(openssl rand -base64 14 | tr -dc 'a-zA-Z0-9')

step "Phase 1: Environment Setup"
execute "Installing Dependencies" "apt update && apt install -y curl gnupg2 ca-certificates lsb-release software-properties-common unzip git tar"

OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "ubuntu" ]]; then
    execute "Configuring PHP PPA" "add-apt-repository -y ppa:ondrej/php && apt update"
elif [[ "$OS" == "debian" ]]; then
    execute "Configuring SURY Repo" "curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg && echo 'deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main' | tee /etc/apt/sources.list.d/sury-php.list && apt update"
fi

execute "Installing PHP, Nginx & MariaDB" "apt install -y php${PHP_VER} php${PHP_VER}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server"
execute "Installing Composer" "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"

step "Phase 2: Panel Installation"
execute "Downloading Files" "mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl && curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz && tar -xzvf panel.tar.gz && chmod -R 755 storage/* bootstrap/cache/"
execute "Configuring Database" "mariadb -e \"CREATE DATABASE IF NOT EXISTS panel;\" && mariadb -e \"CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';\" && mariadb -e \"GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;\" && mariadb -e \"FLUSH PRIVILEGES;\""

cd /var/www/pterodactyl
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=pterodactyl|g" .env

execute "Composer Install" "COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader"
execute "Generating Encryption Key" "php artisan key:generate --force"
execute "Running Migrations" "php artisan migrate --seed --force"

step "Phase 3: Final Config"
execute "Setting Permissions" "chown -R www-data:www-data /var/www/pterodactyl/*"
execute "Setting up Cron" "apt install -y cron && systemctl enable --now cron && (crontab -l 2>/dev/null; echo '* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1') | crontab -"
execute "SSL Generation" "mkdir -p /etc/certs/panel && openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -subj '/C=NA/ST=NA/L=NA/O=NA/CN=Panel' -keyout /etc/certs/panel/privkey.pem -out /etc/certs/panel/fullchain.pem"

# Nginx Configuration
tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80; server_name ${DOMAIN}; return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2; server_name ${DOMAIN};
    root /var/www/pterodactyl/public; index index.php;
    ssl_certificate /etc/certs/panel/fullchain.pem; ssl_certificate_key /etc/certs/panel/privkey.pem;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php${PHP_VER}-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

execute "Starting Webserver" "ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf && systemctl restart nginx"

# Systemd Queue Worker
tee /etc/systemd/system/pteroq.service > /dev/null << EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
[Install]
WantedBy=multi-user.target
EOF

execute "Starting Services" "systemctl daemon-reload && systemctl enable --now redis-server pteroq.service"

# --- Admin User (Interactive) ---
clear
banner
step "Administrative User Creation"
echo -e "${C_YELLOW}Enter details for your admin account below:${C_RESET}"
php artisan p:user:make

# ---------------- FINAL SUMMARY ----------------
clear
banner
echo -e "${C_GREEN}╔══════════════════════════════════════════════════════════════╗${C_RESET}"
draw_box "🎉 INSTALLATION COMPLETED SUCCESSFULLY"
echo -e "${C_GREEN}╠══════════════════════════════════════════════════════════════╣${C_RESET}"
printf "${C_CYAN}║${C_RESET}  %-18s : ${C_WHITE}%-37s${C_CYAN}║${C_RESET}\n" "🌐 Panel URL" "https://${DOMAIN}"
printf "${C_CYAN}║${C_RESET}  %-18s : ${C_WHITE}%-37s${C_CYAN}║${C_RESET}\n" "🗄  DB User" "pterodactyl"
printf "${C_CYAN}║${C_RESET}  %-18s : ${C_WHITE}%-37s${C_CYAN}║${C_RESET}\n" "🔑 DB Password" "${DB_PASS}"
echo -e "${C_GREEN}╠══════════════════════════════════════════════════════════════╣${C_RESET}"
draw_box "🚀 Panel is live! Log in to get started."
echo -e "${C_GREEN}╚══════════════════════════════════════════════════════════════╝${C_RESET}"
echo -e "${C_GRAY}Detailed log saved at: $LOG_FILE${C_RESET}"
