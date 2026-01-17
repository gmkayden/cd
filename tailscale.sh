#!/usr/bin/env bash
set -e

# ================================
# Colors
# ================================
YELLOW="\e[33m"
GREEN="\e[32m"
RED="\e[31m"
RESET="\e[0m"

LOG_FILE="ptero-gui.log"

# ================================
# Spinner (CLEAN)
# ================================
spinner() {
  local pid=$1
  local spin='-\|/'
  local i=0

  tput civis
  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % 4 ))
    printf "\r${YELLOW}[%c] Working...${RESET}" "${spin:$i:1}"
    sleep 0.1
  done
  printf "\r${GREEN}[✔] Done${RESET}\n"
  tput cnorm
}

run_cmd() {
  bash -c "$1" >>"$LOG_FILE" 2>&1 &
  spinner $!
}

# ================================
# ASCII Banner
# ================================
clear
echo -e "${YELLOW}"
cat <<'EOF'
 ████████╗ █████╗ ██╗██╗ ███████╗ ██████╗ █████╗ ██╗ ███████╗
 ╚══██╔══╝██╔══██╗██║██║ ██╔════╝██╔════╝██╔══██╗██║ ██╔════╝
    ██║   ███████║██║██║ ███████╗██║     ███████║██║ █████╗
    ██║   ██╔══██║██║██║ ╚════██║██║     ██╔══██║██║ ██╔══╝
    ██║   ██║  ██║██║███████╗███████║╚██████╗██║  ██║███████╗
    ╚═╝   ╚═╝  ╚═╝╚═╝╚══════╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚══════╝
EOF
echo -e "${RESET}\n"

# ================================
# Root Check
# ================================
if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}✗ Please run this script as root${RESET}"
  exit 1
fi

# ================================
# Install Tailscale
# ================================
echo -e "${YELLOW}➤ Installing Tailscale...${RESET}"
run_cmd "curl -fsSL https://tailscale.com/install.sh | bash"

# ================================
# Enable & Start Service
# ================================
echo -e "${YELLOW}➤ Enabling Tailscale service...${RESET}"
run_cmd "systemctl enable --now tailscaled"

# ================================
# Bring Tailscale UP
# ================================
echo -e "${YELLOW}➤ Bringing Tailscale up...${RESET}"
run_cmd "tailscale up"

# ================================
# Final Status
# ================================
echo -e "\n${GREEN}✅ Tailscale is installed and running!${RESET}"
echo -e "${YELLOW}Authenticate using the browser link shown above.${RESET}"
echo -e "${YELLOW}Tailscale IP:${RESET} ${GREEN}$(tailscale ip -4 2>/dev/null || echo 'Pending auth')${RESET}"
