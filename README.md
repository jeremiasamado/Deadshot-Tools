# Deadshot Tools

An optimized, refactored, and highly stable hub for essential cybersecurity tools on Kali Linux. From phishing and OSINT data gathering to mass testing frameworks, I organized everything securely in a single command-line interface.

## Why I created Deadshot Tools
This project is an evolution of standard hacking tool installers. I took the base concept of the ALHacking script and decided to rewrite the engine to fix critical structural flaws, adding features the original creator didn't think to implement:

- **Zero Directory Pollution:** I created a safe sandboxing system that ensures tools only clone inside an isolated `Tools/` folder, never polluting your main directory.

- **Improved Performance:** I added intelligent caching checks that prevent re-downloading existing repositories, saving massive time and internet bandwidth.

- **Refactored Engine:** I abandoned the old, fragile `if/elif` spaghetti loops in favor of a clean, crash-resistant core `case` structure.

## System Requirements
I rigorously tailored and tested the environment for:
* Linux (Debian Based Systems, specifically **Kali Linux**)
* Unix
* Termux (For Android mobile pentesting)

## How to Install and Run
Getting started is simple. Open your terminal and run:

1. `cd NE0SYNC`
2. Make the core script executable (first time only): 
   `chmod +x deadshot.sh`
3. Launch the dashboard: 
   `./deadshot.sh`

---

# Deadshot Tools (Versão Português - PT)

Este projeto é um hub otimizado e altamente estável que criei para agrupar as ferramentas reais de cibersegurança no Kali Linux. Desde phishing e recolha de inteligência (OSINT) a frameworks de ataque, organizei tudo de forma segura numa única interface de linha de comandos.

## Porque criei o Deadshot Tools
Peguei no conceito base de scripts de instalação passados (como o ALHacking) e decidi reescrever o motor para corrigir falhas estruturais críticas, melhorando imensas coisas em que o criador original não pensou:

- **Zero Poluição de Diretórios:** Criei um sistema de isolamento que garante que as ferramentas são clonadas apenas dentro de uma pasta `Tools/`, sem nunca sujar o teu diretório de raiz.

- **Performance Melhorada:** Implementei verificações inteligentes de cache que impedem o script de descarregar novamente repositórios que já existam na máquina, o que poupa tempo massivo e largura de banda.

- **Motor Refatorado:** Eliminei os ciclos antigos e frágeis de `if/elif` em favor de uma estrutura core limpa baseada em `case`, totalmente resistente a quebras.

## Requisitos do Sistema
O ambiente foi rigorosamente testado e talhado para:
* Linux (Sistemas baseados em Debian, especialmente **Kali Linux**)
* Unix
* Termux (Para pentesting em Android)

## Como Instalar e Executar
É simples começar. Abre o teu terminal e executa os seguintes comandos:

1. `cd NE0SYNC`
2. Atribui permissão de execução ao script (apenas na primeira vez): 
   `chmod +x deadshot.sh`
3. Lança o painel de controlo: 
   `./deadshot.sh`
