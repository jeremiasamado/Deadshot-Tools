#!/bin/bash

# ==========================================
# DEADSHOT SHIELD (Blue Team Active Defense)
# Developer: NE0SYNC
# ==========================================

RED='\033[31;40;1m'
DARK_GRAY='\033[1;30m'
NC='\033[0m'

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SHIELD_LOG="$SCRIPT_DIR/Reports/Shield_Blocked_IPs.txt"
HONEYPOT_PORT="8888"
SSH_FAIL_THRESHOLD=5

mkdir -p "$SCRIPT_DIR/Reports"

# ==========================================
# HONEYPOT TAUNT PAGE (The Middle Finger)
# ==========================================
start_honeypot() {
    echo -e "${RED}[!] Deploying Honeypot Taunt Server on port $HONEYPOT_PORT...${NC}"

    python3 -c "
import http.server
import socketserver

TAUNT_PAGE = '''HTTP/1.1 200 OK
Content-Type: text/html

<html>
<head><title>ACCESS DENIED</title></head>
<body style=\"background:#000;color:#ff3333;font-family:monospace;display:flex;align-items:center;justify-content:center;height:100vh;margin:0;\">
<pre style=\"font-size:16px;text-align:center;\">

 ____  _________    ____  _____ __  ______  ______ 
/ __ \/ ____/   |  / __ \/ ___// / / / __ \/_  __/ 
/ / / / __/ / /| | / / / /\__ \/ /_/ / / / / / /    
/ /_/ / /___/ ___ |/ /_/ /___/ / __  / /_/ / / /     
/_____/_____/_/  |_/_____//____/_/ /_/\____/ /_/      


+==========================================+
|                                          |
|    YOUR IP HAS BEEN LOGGED, REPORTED     |
|    AND PERMANENTLY BLACKLISTED.          |
|                                          |
|           ┌∩┐(◣_◢)┌∩┐                   |
|                                          |
|    NICE TRY, SCRIPT KIDDY.              |
|    GO HOME.                              |
|                                          |
|    -- DEADSHOT O.S. // NE0SYNC --        |
+==========================================+

</pre>
</body></html>
'''

class TauntHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-type', 'text/html')
        self.end_headers()
        self.wfile.write(TAUNT_PAGE.encode())
        print(f'[HONEYPOT] Intruder browsed from: {self.client_address[0]}')
    def log_message(self, format, *args):
        pass

with socketserver.TCPServer(('', $HONEYPOT_PORT), TauntHandler) as httpd:
    print(f'Honeypot active on port $HONEYPOT_PORT')
    httpd.serve_forever()
" &
    HONEYPOT_PID=$!
    echo -e "${DARK_GRAY}[+] Honeypot PID: $HONEYPOT_PID${NC}"
}

# ==========================================
# WATCHDOG: SSH Brute-Force Detection
# ==========================================
run_watchdog() {
    clear
    echo -e "${RED}"
    echo '  ____  _   _ ___ _____ _     ____  '
    echo ' / ___|| | | |_ _| ____| |   |  _ \ '
    echo ' \___ \| |_| || ||  _| | |   | | | |'
    echo '  ___) |  _  || || |___| |___| |_| |'
    echo ' |____/|_| |_|___|_____|_____|____/ '
    echo ""
    echo -e "${NC}"
    echo -e "${RED}[!] DEADSHOT SHIELD: ACTIVE DEFENSE MODE${NC}"
    echo -e "${DARK_GRAY}[*] Monitoring SSH brute-force attempts...${NC}"
    echo -e "${DARK_GRAY}[*] Threshold: $SSH_FAIL_THRESHOLD failed attempts = AUTO-BLOCK${NC}"
    echo -e "${DARK_GRAY}[*] Honeypot taunt page deploying on port $HONEYPOT_PORT...${NC}"
    echo -e "${DARK_GRAY}[*] Press Ctrl+C to deactivate shield.${NC}"
    echo ""

    # Deploy the honeypot in background
    start_honeypot

    # Track which IPs we already blocked
    declare -A BLOCKED_IPS

    # Monitor auth.log in real-time
    tail -Fn0 /var/log/auth.log 2>/dev/null | while read -r line; do

        # Detect SSH failed password
        if echo "$line" | grep -qi "Failed password"; then
            ATTACKER_IP=$(echo "$line" | grep -oP '(\d{1,3}\.){3}\d{1,3}' | tail -1)

            if [ -z "$ATTACKER_IP" ]; then continue; fi
            if [ "${BLOCKED_IPS[$ATTACKER_IP]}" == "1" ]; then continue; fi

            # Count total failures from this IP
            FAIL_COUNT=$(grep -c "Failed password.*$ATTACKER_IP" /var/log/auth.log 2>/dev/null)

            echo -e "${RED}[!] INTRUSION ATTEMPT from $ATTACKER_IP (Failures: $FAIL_COUNT/$SSH_FAIL_THRESHOLD)${NC}"

            if [ "$FAIL_COUNT" -ge "$SSH_FAIL_THRESHOLD" ]; then
                echo -e "${RED}[!!!] THRESHOLD BREACHED! NEUTRALIZING $ATTACKER_IP${NC}"

                # BLOCK with iptables
                sudo iptables -A INPUT -s "$ATTACKER_IP" -j DROP 2>/dev/null
                BLOCKED_IPS[$ATTACKER_IP]=1

                # Log to report
                echo "[$(date)] BLOCKED: $ATTACKER_IP after $FAIL_COUNT failed SSH attempts" >> "$SHIELD_LOG"
                echo -e "${DARK_GRAY}[+] $ATTACKER_IP permanently blacklisted via iptables.${NC}"
                echo -e "${DARK_GRAY}[+] Logged to: Reports/Shield_Blocked_IPs.txt${NC}"

                # AI tactical analysis (if Ollama is running)
                if pgrep -x "ollama" >/dev/null 2>&1; then
                    echo -e "${DARK_GRAY}[*] Requesting AI threat assessment...${NC}"
                    AI_RESPONSE=$(echo "An attacker from IP $ATTACKER_IP just tried to brute-force my SSH $FAIL_COUNT times. I blocked them with iptables. What else should I check? What attack might follow next? Be brief and tactical." | ollama run dolphin-phi 2>/dev/null | head -20)
                    echo -e "${RED}[AI THREAT INTEL]:${NC}"
                    echo -e "${DARK_GRAY}$AI_RESPONSE${NC}"
                    echo ""
                fi
            fi
        fi

        # Detect port scanning patterns  
        if echo "$line" | grep -qi "refused connect\|invalid user\|Bad protocol"; then
            SCAN_IP=$(echo "$line" | grep -oP '(\d{1,3}\.){3}\d{1,3}' | tail -1)
            if [ -n "$SCAN_IP" ] && [ "${BLOCKED_IPS[$SCAN_IP]}" != "1" ]; then
                echo -e "${RED}[!] POSSIBLE PORT SCAN detected from $SCAN_IP${NC}"
            fi
        fi

    done
}

# ==========================================
# SHIELD CLEANUP
# ==========================================
shield_cleanup() {
    echo -e "\n${DARK_GRAY}[*] Deactivating Shield...${NC}"
    # Kill honeypot
    pkill -f "TauntHandler" 2>/dev/null
    echo -e "${DARK_GRAY}[+] Honeypot server terminated.${NC}"
    echo -e "${DARK_GRAY}[+] Blocked IPs remain in iptables until system reboot.${NC}"
    echo -e "${DARK_GRAY}[+] Shield deactivated. Returning to framework.${NC}"
}

trap shield_cleanup EXIT

# Main execution
if [ "$1" == "watchdog" ]; then
    run_watchdog
else
    run_watchdog
fi
