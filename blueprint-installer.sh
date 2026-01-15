#!/usr/bin/env bash
# ==========================================
# Blueprint Installer + Auto Fix (tput colors)
# Made With ❤ By GMK
# ==========================================

set -e

LOG_FILE="./blueprint.log"
touch "$LOG_FILE"

# ─── Colors (tput) ─────────────────────────
if [ -t 1 ]; then
    RED=$(tput bold; tput setaf 1)
    GREEN=$(tput bold; tput setaf 2)
    YELLOW=$(tput bold; tput setaf 3)
    BLUE=$(tput bold; tput setaf 4)
    PURPLE=$(tput bold; tput setaf 5)
    CYAN=$(tput bold; tput setaf 6)
    NC=$(tput sgr0)
else
    # Non-TTY fallback
    RED=""; GREEN=""; YELLOW=""; BLUE=""; PURPLE=""; CYAN=""; NC=""
fi

# ─── Spinner ───────────────────────────────
spinner() {
    local pid=$1
    local spin='|/-\'
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        i=$(( (i + 1) % 4 ))
        printf "\r%sProcessing... %s%s" "$CYAN" "${spin:$i:1}" "$NC"
        sleep 0.1
    done
    printf "\r%s✔ Done%s\n" "$GREEN" "$NC"
}

# ─── Banner ───────────────────────────────
clear
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}██████╗ ██╗     ██╗   ██╗███████╗██████╗ ██████╗ ██╗███╗   ██╗████████╗${NC}"
echo -e "${YELLOW}██╔══██╗██║     ██║   ██║██╔════╝██╔══██╗██╔══██╗██║████╗  ██║╚══██╔══╝${NC}"
echo -e "${YELLOW}██████╔╝██║     ██║   ██║█████╗  ██████╔╝██████╔╝██║██╔██╗ ██║   ██║${NC}"
echo -e "${YELLOW}██╔══██╗██║     ██║   ██║██╔══╝  ██╔═══╝ ██╔══██╗██║██║╚██╗██║   ██║${NC}"
echo -e "${YELLOW}██████╔╝███████╗╚██████╔╝███████╗██║     ██║  ██║██║██║ ╚████║   ██║${NC}"
echo -e "${YELLOW}╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝   ╚═╝${NC}"
echo
echo -e "${CYAN}Blueprint Installer${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo

# ─── Set Pterodactyl Directory ─────────────
export PTERODACTYL_DIRECTORY=/var/www/pterodactyl

# ─── Dependencies ──────────────────────────
echo -e "${CYAN}Installing dependencies...${NC}"
sudo apt install -y curl wget unzip ca-certificates git gnupg zip &>>"$LOG_FILE" &
spinner $!

cd "$PTERODACTYL_DIRECTORY"

# ─── Download Blueprint ────────────────────
echo -e "${CYAN}Downloading Blueprint...${NC}"
wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)" \
-O release.zip &>>"$LOG_FILE" &
spinner $!

unzip -o release.zip &>>"$LOG_FILE"

# ─── Node.js 20 ────────────────────────────
echo -e "${CYAN}Installing Node.js 20...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" \
| sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null

sudo apt update &>>"$LOG_FILE"
sudo apt install -y nodejs &>>"$LOG_FILE" &
spinner $!

# ─── Yarn & Node Modules ───────────────────
echo -e "${CYAN}Installing Yarn & dependencies...${NC}"
npm i -g yarn &>>"$LOG_FILE"
yarn install &>>"$LOG_FILE" &
spinner $!

# ─── Blueprint Config ──────────────────────
echo -e "${CYAN}Configuring Blueprint...${NC}"
touch .blueprintrc
cat > .blueprintrc <<EOF
WEBUSER="www-data"
OWNERSHIP="www-data:www-data"
USERSHELL="/bin/bash"
EOF

chmod +x blueprint.sh

# ─── Run Blueprint Installer ───────────────
echo -e "${CYAN}Running Blueprint installer...${NC}"
bash blueprint.sh &>>"$LOG_FILE" || true
spinner $!

# ─── Blueprint FIX (503) ───────────────────
echo -e "${YELLOW}Applying Blueprint Fix...${NC}"
(
cd /var/www/pterodactyl || exit 1

for f in \
resources/scripts/components/server/files/FileNameModal.tsx \
resources/scripts/components/server/files/FileObjectRow.tsx \
resources/scripts/components/server/files/NewDirectoryButton.tsx \
resources/scripts/components/server/files/RenameFileModal.tsx
do
    sed -i "/import { join } from 'pathe';/d" "$f"
    grep -q "const join = (...paths" "$f" || \
    sed -i "1i const join = (...paths: string[]) => paths.filter(Boolean).join('/');" "$f"
done

sed -i "/@ts-expect-error todo: check on this/d" \
resources/scripts/components/elements/CopyOnClick.tsx

sed -i "s/import axios, { AxiosProgressEvent } from 'axios';/import axios from 'axios';/g" \
resources/scripts/components/server/files/UploadButton.tsx

sed -i "s/AxiosProgressEvent/ProgressEvent/g" \
resources/scripts/components/server/files/UploadButton.tsx

set +H
sed -i "/Assert::isInstanceOf/c\\\$server = \\\$request->route()?->parameter('server');\\n\\nif (is_string(\\\$server) || !(\\\$server instanceof Server)) {\\n return Limit::none();\\n}" \
app/Enum/ResourceLimit.php
set -H
) &>>"$LOG_FILE" &
spinner $!

# ─── Rerun Blueprint ───────────────────────
echo -e "${CYAN}Re-running Blueprint installer...${NC}"
blueprint -rerun-install &>>"$LOG_FILE" &
spinner $!

# ─── Done ──────────────────────────────────
echo
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Installation Completed!${NC}"
echo -e "${CYAN}Made With ❤ By GMK${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
