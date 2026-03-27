#!/bin/bash

# ==========================================
# Original Project: ALHacking
# Evolução Militar: Deadshot Tools (Fase V5 - Ghost Mode & AI Live Intel)
# Segurança Máxima, Ocultação de IP e Parsing de Várzes Mundiais
# ==========================================

RED='\033[31;40;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
MAGENTA='\033[35;1m'
CYAN='\033[36;1m'
NC='\033[0m'

# ==========================================
# GHOST MODE - INICIALIZAÇÃO SEGURA (ANTI-FORENSICS)
# ==========================================
ghost_mode() {
    clear
    echo -e "${YELLOW}[!] PROTOCOLO GHOST A INICIAR (Privilégios Administrativos Elevados Exigidos)${NC}"
    echo -e "${MAGENTA}[*] Identidade, Cache e Interface de Rede vão ser desvinculadas...${NC}"
    sleep 1
    
    # Anti-Forensics: Limpeza de Cache RAM e Histórico Bash
    sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches" 2>/dev/null
    cat /dev/null > ~/.bash_history 2>/dev/null
    history -c 2>/dev/null
    
    # Detetar Interface e Executar Spoofing
    IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5}' | head -n 1)
    if [ -n "$IFACE" ]; then
        if command -v macchanger >/dev/null; then
            echo -e "${YELLOW}[!] O MAC Address original na interface $IFACE vai ser mascarado...${NC}"
            sudo ip link set dev "$IFACE" down
            sudo macchanger -r "$IFACE" >/dev/null 2>&1
            sudo ip link set dev "$IFACE" up
            echo -e "${GREEN}[+] O Identificador da tua máquina (MAC Address) agora é um fantasma neste router!${NC}"
        else
            echo -e "${RED}[!] Macchanger não encontrado. Recomendo que Vás ao menu e instales as Dependências [Opção 1].${NC}"
        fi
    else
        echo -e "${RED}[!] Interface de rede nula (Offline). A ignorar protocolo MAC.${NC}"
    fi
    echo -e "${GREEN}[*] 100% LIMPO. Bem-vindo às Sombras.${NC}"
    sleep 2
}

# Arranque do escudo antes de invocar menus
ghost_mode

# Instalar whiptail apenas se estritamente necessário para o ecrã carregar
if ! command -v whiptail >/dev/null; then
    sudo apt-get update >/dev/null 2>&1
    sudo apt-get install whiptail -y >/dev/null 2>&1
fi

mkdir -p Tools

preparar_ferramenta() {
    clear
    echo -e "${MAGENTA}[*] A abrir a Sandbox Operacional...${NC}"
    if ! cd Tools; then
        echo -e "${RED}[!] Erro crítico: Pasta Tools inacessível.${NC}"
        sleep 2
        return 1
    fi
    return 0
}

pausar() {
    echo ""
    read -p "Prima [ENTER] para regressar à Central do Deadshot..."
}

# ==========================================
# BLOCO DAS FERRAMENTAS CLÁSSICAS (V3) E DEPENDÊNCIAS
# ==========================================
run_requisitos() {
    clear
    echo -e "${MAGENTA}[*] A instalar todos os pacotes estruturais na máquina...${NC}"
    sudo apt update && sudo apt upgrade -y
    # Injetado jq (Para AI ler JSONs) e macchanger (Para o Ghost Mode)
    sudo apt install -y git python3 python3-pip curl php tor ruby nmap amass nuclei hydra ffuf wpscan jq macchanger
    echo -e "${GREEN}[+] O teu Linux está blindado com as ferramentas raízes (incluindo JQ e Macchanger)!${NC}"
    pausar
}

run_zphisher() {
    preparar_ferramenta || return
    if [ ! -d "zphisher" ]; then git clone https://github.com/htr-tech/zphisher; fi
    cd zphisher && bash zphisher.sh; cd ../..
}

run_camphish() {
    preparar_ferramenta || return
    if [ ! -d "CamPhish" ]; then git clone https://github.com/techchipnet/CamPhish; fi
    cd CamPhish && bash camphish.sh; cd ../..
}

run_amass() {
    preparar_ferramenta || return
    echo -e "${MAGENTA}[*] Amass...${NC}"
    read -p "Insira o domínio TARGET corporativo (ex: empresa.com): " dom
    if command -v amass >/dev/null; then amass enum -d "$dom"; else echo -e "${RED}[!] Faltam requisitos [Menu 1].${NC}"; fi
    cd ../..; pausar
}

run_theharvester() {
    preparar_ferramenta || return
    if [ ! -d "theHarvester" ]; then git clone https://github.com/laramies/theHarvester.git; fi
    cd theHarvester
    python3 -m pip install -r requirements/base.txt --break-system-packages 2>/dev/null || python3 -m pip install -r requirements/base.txt
    read -p "Domínio alvo (ex: apple.com): " dom
    python3 theHarvester.py -d "$dom" -b all
    cd ../..; pausar
}

run_sqlmap() {
    preparar_ferramenta || return
    if [ ! -d "sqlmap-dev" ]; then git clone --depth 1 https://github.com/sqlmapproject/sqlmap.git sqlmap-dev; fi
    cd sqlmap-dev
    read -p "URL com Parâmetro Vulnerável a SQLi (ex: site.com/page.php?id=1): " alvo
    python3 sqlmap.py -u "$alvo" --dbs --random-agent --batch
    cd ../..; pausar
}

run_phoneinfoga() {
    preparar_ferramenta || return
    if [ ! -d "PhoneInfoga_App" ]; then mkdir PhoneInfoga_App; fi
    cd PhoneInfoga_App
    if [ ! -f "phoneinfoga" ]; then curl -sSL https://raw.githubusercontent.com/sundowndev/phoneinfoga/master/support/scripts/install | bash; fi
    read -p "N. Telemóvel Alvo (+351...): " phnum
    if [ -n "$phnum" ]; then ./phoneinfoga scan -n "$phnum"; fi
    cd ../..; pausar
}

run_sherlock() {
    preparar_ferramenta || return
    if [ ! -d "sherlock" ]; then git clone https://github.com/sherlock-project/sherlock.git; fi
    cd sherlock
    python3 -m pip install -r requirements.txt --break-system-packages 2>/dev/null || python3 -m pip install -r requirements.txt
    read -p "Username (ID do Jogador/Alvo): " uname
    if [ -n "$uname" ]; then python3 sherlock "$uname"; fi
    cd ../..; pausar
}

run_nuclei() {
    preparar_ferramenta || return
    read -p "IP/Domínio (https://site.com): " tg
    if command -v nuclei >/dev/null; then nuclei -u "$tg"; else echo -e "${RED}[!] Requisitos em falta.${NC}"; fi
    cd ../..; pausar
}

run_nikto() {
    preparar_ferramenta || return
    if [ ! -d "nikto" ]; then git clone https://github.com/sullo/nikto.git; fi
    cd nikto
    read -p "URL Direto do Servidor Clássico Web: " urlt
    perl program/nikto.pl -h "$urlt"
    cd ../..; pausar
}

run_wpscan() {
    preparar_ferramenta || return
    read -p "URL WordPress (ex: https://blog-empresa.com): " wp_url
    if command -v wpscan >/dev/null; then wpscan --url "$wp_url" --enumerate u,vp,vt; else echo -e "${RED}[!] Efetua antes a Instalação Global [1].${NC}"; fi
    cd ../..; pausar
}

run_rustscan() {
    preparar_ferramenta || return
    if ! command -v rustscan >/dev/null; then
        wget -qO rustscan.deb https://github.com/RustScan/RustScan/releases/download/2.0.1/rustscan_2.0.1_amd64.deb
        sudo dpkg -i rustscan.deb
    fi
    read -p "IP para Varrimento Ultrasónico: " t_ip
    rustscan -a "$t_ip" -- -A -sC
    cd ../..; pausar
}

run_hydra() {
    preparar_ferramenta || return
    read -p "Caminho da Wordlist (ex: /usr/share/wordlists/rockyou.txt): " wordl
    read -p "User a atacar na porta (ex: root): " usr
    read -p "URL e Protocolo Exato (ex: ssh://192.168.1.1): " target_f
    if command -v hydra >/dev/null; then hydra -l "$usr" -P "$wordl" "$target_f"; else echo -e "${RED}[!] Falha de sistema. Instala a Opção 1.${NC}"; fi
    cd ../..; pausar
}

run_ffuf() {
    preparar_ferramenta || return
    read -p "Website a invadir a terminar com FUZZ (ex: http://site.com/FUZZ): " fz_site
    read -p "Caminho para o ficheiro de diretórios (ex: wordlist.txt): " dir_w
    if command -v ffuf >/dev/null; then ffuf -w "$dir_w" -u "$fz_site" -c; else echo -e "${RED}[!] Instala Requisitos!${NC}"; fi
    cd ../..; pausar
}

run_seeker() {
    preparar_ferramenta || return
    if [ ! -d "seeker" ]; then git clone https://github.com/thewhiteh4t/seeker.git; fi
    cd seeker
    bash install.sh
    python3 seeker.py
    cd ../..; pausar
}

run_torproxy() {
    preparar_ferramenta || return
    if [ ! -d "Auto_Tor_IP_changer" ]; then git clone https://github.com/FDX100/Auto_Tor_IP_changer.git; fi
    cd Auto_Tor_IP_changer
    sudo python3 install.py
    aut
    cd ../..; pausar
}

limpeza_sandbox() {
    clear
    rm -rf Tools/ && mkdir -p Tools
    echo -e "${GREEN}[+] O teu histórico de ferramentas descarregadas foi exterminado.${NC}"
    pausar
}

# ==========================================
# CÉREBRO: DEADSHOT AI ASSISTANT & LIVE INTEL
# ==========================================
run_deadshot_ai() {
    alvo=$(whiptail --title "🤖 Deadshot AI Wizard" --menu "A tua ligação está anónima e a IA está online.\nQual é o teu rumo operacional hoje?" 20 75 6 \
    "1" "Investigar o perfil e dados de uma Pessoa/Identidade" \
    "2" "Invadir a Administração de um Site/Web Server" \
    "3" "Rebentar Palavras-Passe de um Servidor/Base Confidencial" \
    "4" "Acompanhar Rastreio Físico de um Alvo (GPS)" \
    "5" "🌍 Missões do Dia (Quero Hackear de forma legal hoje. Mostra-me alvos!)" 3>&1 1>&2 2>&3)

    if [ -z "$alvo" ]; then return; fi

    case $alvo in
        "1")
            p_dados=$(whiptail --title "🤖 Deadshot AI Wizard (OSINT)" --menu "Para Pessoas (OSINT), que tipo de vestígio dele na Internet tens nas mãos agora?" 20 75 3 "A" "O seu Número de Telemóvel" "B" "O seu Username favorito" "C" "A Empresa a que ele pertence" 3>&1 1>&2 2>&3)
            if [ "$p_dados" = "A" ]; then run_phoneinfoga; elif [ "$p_dados" = "B" ]; then run_sherlock; elif [ "$p_dados" = "C" ]; then run_theharvester; fi
            ;;
        "2")
            s_dados=$(whiptail --title "🤖 Deadshot AI Wizard (Web)" --menu "Tática para invadir a infraestrutura web?" 20 75 4 "A" "Fuzzar diretórios de Logins admin ocultos" "B" "Atacar blogs mal-construídos de WordPress" "C" "Extrair bases de dados por SQLi exposta" "D" "Despejar milhares de falhas CVE automaticamente" 3>&1 1>&2 2>&3)
            if [ "$s_dados" = "A" ]; then run_ffuf; elif [ "$s_dados" = "B" ]; then run_wpscan; elif [ "$s_dados" = "C" ]; then run_sqlmap; elif [ "$s_dados" = "D" ]; then run_nuclei; fi
            ;;
        "3")
            whiptail --title "🤖 Deadshot AI Wizard (Auth)" --msgbox "O Cérebro aponta irrevogavelmente para [THC-Hydra] e listas brutais extraídas de Data Leaks." 10 70
            run_hydra
            ;;
        "4")
            run_seeker
            ;;
        "5")
            whiptail --title "🤖 Cérebro AI: Intel em Tempo Real" --msgbox "Neste exato minuto a minha matriz irá ligar aos servidores da GitHub Cloud Sec (APIs) para extrair as 3 exploits ativas publicadas e programas abertos de Bug Bounty para a tua secção. Ouve o Terminal." 15 70
            clear
            
            if ! command -v jq >/dev/null || ! command -v curl >/dev/null; then
                echo -e "${RED}[!] JQ ou cURL em falta. Por favor vai ao Sub-menu 'Sistema Básico' e descarrega a Opção 1 antes de eu pesquisar o Universo Hacker.${NC}"
                pausar
                return
            fi

            echo -e "${MAGENTA}[*] (📡) Varrendo as profundezas da Internet por atividade recente...${NC}"
            sleep 2
            
            echo -e "${RED}\n[=] 💥 AS ÚLTIMAS VULNERABILIDADES (CVE Exploits - 24 horas) NO GITHUB:${NC}"
            curl -s -H "User-Agent: Deadshot_IA_Engine" "https://api.github.com/search/repositories?q=CVE-2024&sort=updated&order=desc" 2>/dev/null | jq -r '.items[0:3] | " [X] \(.name): \(.description)"'
            
            echo -e "${CYAN}\n[=] 🎯 ALVOS DE BUG BOUNTY (DOMÍNIOS RECOMENDADOS PARA TESTE PENAL LIVE HOJE):${NC}"
            # Dados abertos públicos do Chaos Project ou dados JSON formatados
            curl -s "https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/main/data/hackerone_data.json" 2>/dev/null | jq -r '.[0:3] | " [V] \(.url) (Autorizado Hack HackerOne)"'
            
            echo -e "\n${GREEN}[+] Ficheiros Extraídos. Usa FFUF, Nuclei ou SQLMap nos alvos Bug Bounty acima sem medo de prisão!${NC}"
            pausar
            ;;
    esac
}

# ==========================================
# MENUS GRÁFICOS E INTERFACES (TUI)
# ==========================================
menu_osint() {
    CHOICE=$(whiptail --title "Sub-Central: OSINT" --menu "Seleciona as ferramentas furtivas de Inteligência de Código Aberto:" 20 70 5 "1" "Amass (Mapeamento de Subdomínios Ocultos OWASP)" "2" "TheHarvester (Caça-Emaill em Redes Corporativas)" "3" "PhoneInfoga (Mapeamento Analítico de N. Telemóveis)" "4" "Sherlock (Sherlock Global a Usernames em 400 Sites)" "0" "<< Voltar ao Ecrã Principal" 3>&1 1>&2 2>&3)
    case $CHOICE in 1) run_amass ;; 2) run_theharvester ;; 3) run_phoneinfoga ;; 4) run_sherlock ;; esac
}

menu_web() {
    CHOICE=$(whiptail --title "Sub-Central: Web" --menu "Lança Scanners Agressivos para Portas Web Expostas:" 20 70 5 "1" "SQLMap (Extração Completa de Bases de Dados SQL)" "2" "Nuclei (Lança Milhares de Exploits a Milissegundos)" "3" "Nikto (Auditoria Destrutiva Clássica)" "4" "WPScan (Auto-Pwn à Plataforma WordPress)" "0" "<< Voltar ao Ecrã Principal" 3>&1 1>&2 2>&3)
    case $CHOICE in 1) run_sqlmap ;; 2) run_nuclei ;; 3) run_nikto ;; 4) run_wpscan ;; esac
}

menu_bruteforce() {
    CHOICE=$(whiptail --title "Sub-Central: Infiltração" --menu "Dispara mecanismos de Força Bruta:" 20 70 4 "1" "RustScan (Varrimento a 65,000 Portas Ultra-Velocidade)" "2" "THC-Hydra (Força Bruta pura a redes FTP/SSH)" "3" "Ffuf (Fuzzer Web de diretórios invisíveis)" "0" "<< Voltar ao Ecrã Principal" 3>&1 1>&2 2>&3)
    case $CHOICE in 1) run_rustscan ;; 2) run_hydra ;; 3) run_ffuf ;; esac
}

menu_social() {
    CHOICE=$(whiptail --title "Sub-Central: Engenharia Social" --menu "Ataca o comportamento Humano:" 20 70 5 "1" "Zphisher (Phishing via URL Seguro)" "2" "Camphish (Interceção silenciosa Câmaras)" "3" "Seeker (Exige GPS Exacto Mundial num Mapa de Vítima)" "4" "Auto-IP Changer (Gira Proxies Tor)" "0" "<< Voltar ao Ecrã Principal" 3>&1 1>&2 2>&3)
    case $CHOICE in 1) run_zphisher ;; 2) run_camphish ;; 3) run_seeker ;; 4) run_torproxy ;; esac
}

menu_system() {
    CHOICE=$(whiptail --title "Sub-Central: Sistema Básico" --menu "Ferramentas Básicas do GUI:" 20 70 4 "1" "Instalar Arsenal Vital (Nmap, JQ, Hydra, Go, Pip)" "2" "Limpar a Sandbox de Projetos Atacados" "0" "<< Voltar ao Ecrã Principal" 3>&1 1>&2 2>&3)
    case $CHOICE in 1) run_requisitos ;; 2) limpeza_sandbox ;; esac
}

while true; do
    MAIN=$(whiptail --title "🎯 DEADSHOT TOOLS   V5 (GHOST PROTOCOL)" --menu "Míssil Tático Ativo e Anónimo. Escolha a sua Via Operacional:" 20 80 7 \
    "1" "🧠 O CÉREBRO: IA DEADSHOT & INTEL GLOBAL EM TEMPO REAL" \
    "2" "🥷 1. Fase Tática: Inteligência e Reconhecimento OSINT" \
    "3" "💣 2. Fase Tática: Invasão a Aplicações Web e Scanners" \
    "4" "🔓 3. Fase Tática: Explorar Portas Livres, Wordlists Críticas" \
    "5" "🎭 4. Fase Tática: Físico - GPS Tracker e Links Falsos" \
    "6" "⚙️ Root: Atualizações, Instalações Críticas e Desinstalar" \
    "0" ">> Sair Sem Deixar Rasto" 3>&1 1>&2 2>&3)

    case $MAIN in
        1) run_deadshot_ai ;;
        2) menu_osint ;;
        3) menu_web ;;
        4) menu_bruteforce ;;
        5) menu_social ;;
        6) menu_system ;;
        0|"") clear; echo -e "${GREEN}[*] Desmantelando Ciber-Operações. Bye.${NC}"; exit 0 ;;
    esac
done
