import os
import sys
import subprocess
import asyncio
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical, Center
from textual.widgets import Header, Footer, ListView, ListItem, Label, ProgressBar, Static
from textual.binding import Binding
from textual.screen import Screen

TOOLS = {
    "AI Red Team Assistant": [
        ("Ollama Offline Oracle", "run_ai_assistant", "Local uncensored AI that analyzes your attack reports and suggests next moves. Runs 100% offline.")
    ],
    "Live Threat Intel": [
        ("CVE & Bounty Feed", "run_live_intel", "Tor-proxied OSINT feed pulling fresh CVE exploits and active bug bounties from GitHub/HackerOne.")
    ],
    "OSINT & Footprinting": [
        ("Amass", "run_amass", "OWASP Subdomain Mapping. Extracts hidden subdomains for corporate targets."),
        ("TheHarvester", "run_theharvester", "Corporate metadata footprinting. Gathers emails, names, subdomains, IPs."),
        ("PhoneInfoga", "run_phoneinfoga", "Mobile intelligence gathering. Retrieves active carrier and location data."),
        ("Sherlock", "run_sherlock", "Global username tracker scanning across 400+ social networks.")
    ],
    "Web Scanners": [
        ("SQLMap", "run_sqlmap", "Automated SQL injection payload delivery and database dumper."),
        ("Nuclei", "run_nuclei", "High-speed vulnerability template testing covering thousands of CVEs."),
        ("Nikto", "run_nikto", "Classic destructive web server auditing and misconfiguration scanner."),
        ("WPScan", "run_wpscan", "Automated attack on WordPress targets (Plugin/Theme enumeration).")
    ],
    "Bruteforce": [
        ("RustScan", "run_rustscan", "Ultra-fast port scanning. Maps 65k ports in 3 seconds before piping to Nmap."),
        ("THC-Hydra", "run_hydra", "Brute-force remote authentication protocols (SSH, FTP, HTTP-GET)."),
        ("Ffuf", "run_ffuf", "Fuzzing concealed web directories and parameters at extreme speeds.")
    ],
    "Post-Exploitation & C2": [
        ("NetExec", "run_netexec", "Active directory enumeration, SMB spraying, and lateral movement."),
        ("Sliver C2", "run_sliver", "Generate undetectable beacons for command & control over infected hosts."),
        ("Metasploit", "run_metasploit", "Full MSFConsole orchestration for remote shell injection.")
    ],
    "Privilege Escalation": [
        ("PEAS Remote Server", "run_peas_server", "Host a clandestine 8080 HTTP server to auto-deliver LinPEAS/WinPEAS to victims.")
    ],
    "Internal Network (AD)": [
        ("Responder", "run_responder", "Poison local LLMNR/NBT-NS protocols to intercept and steal NTLM Hashes from Windows hosts.")
    ],
    "Wireless & Physical": [
        ("Wifite2 (Radio Attack)", "run_wifite", "Takeover wireless cards to deauthenticate clients and capture WPA/PMKID handshakes.")
    ],
    "Password Cracking (GPU)": [
        ("Hashcat Offline Cracker", "run_hashcat", "Unleash GPU power to crush extracted hashes offline using global wordlists.")
    ],
    "Social Engineering": [
        ("Zphisher", "run_zphisher", "Deploy secure phishing portals with automatic Ngrok tunneling."),
        ("Camphish", "run_camphish", "WebCam interception via disguised links."),
        ("Seeker", "run_seeker", "Precise GPS location harvesting tricking target browsers."),
        ("Auto-Tor IP", "run_torproxy", "Rotate proxies dynamically across system layers.")
    ],
    "Core Config": [
        ("Install Requirements", "run_requisitos", "Bootstrap all Kali packages & libraries securely."),
        ("Purge Sandbox", "clean_tools_dir", "Delete the Tools directory and wipe installation traces.")
    ]
}

BOOT_PHASES = [
    ("Wiping bash_history traces", 10),
    ("Purging RAM caches", 20),
    ("Detecting network interface", 30),
    ("Spoofing MAC address", 50),
    ("Initializing Tor tunnel", 70),
    ("Loading User-Agent rotation", 85),
    ("Arming tactical dashboard", 95),
    ("OPSEC PROTOCOL ARMED", 100),
]

# ==========================================
# BOOT SCREEN (Loading / Splash)
# ==========================================
class BootScreen(Screen):
    CSS = """
    BootScreen {
        background: #000000;
        align: center middle;
    }
    #boot_container {
        width: 70;
        height: auto;
        padding: 2 4;
        border: solid #660000;
        background: #0a0a0a;
        align: center middle;
    }
    #boot_ascii {
        color: #ff3333;
        text-align: center;
        text-style: bold;
        padding-bottom: 1;
    }
    #boot_version {
        color: #555555;
        text-align: center;
        padding-bottom: 1;
    }
    #boot_status {
        color: #888888;
        text-align: center;
        padding: 1;
    }
    ProgressBar {
        padding: 0 4;
    }
    Bar > .bar--bar {
        color: #ff3333;
    }
    Bar > .bar--complete {
        color: #cc0000;
    }
    """

    def compose(self) -> ComposeResult:
        with Center():
            with Vertical(id="boot_container"):
                yield Static(
                    "  ____  _________    ____  _____ __  ______  ______\n"
                    " / __ \\/ ____/   |  / __ \\/ ___// / / / __ \\/_  __/\n"
                    "/ / / / __/ / /| | / / / /\\__ \\/ /_/ / / / / / /   \n"
                    "/ /_/ / /___/ ___ |/ /_/ /___/ / __  / /_/ / / /    \n"
                    "/_____/_____/_/  |_/_____//____/_/ /_/\\____/ /_/     ",
                    id="boot_ascii"
                )
                yield Static("[ D E A D S H O T   T O O L S   V 9 ]", id="boot_version")
                yield ProgressBar(total=100, show_eta=False, id="boot_progress")
                yield Static("[*] Initializing OPSEC protocols...", id="boot_status")

    async def on_mount(self) -> None:
        progress = self.query_one("#boot_progress", ProgressBar)
        status = self.query_one("#boot_status", Static)

        for phase_text, phase_pct in BOOT_PHASES:
            status.update(f"[*] {phase_text}...")
            progress.update(progress=phase_pct)
            await asyncio.sleep(0.6)

        status.update("[+] ALL SYSTEMS ARMED. ENTERING DASHBOARD...")
        await asyncio.sleep(0.8)
        self.app.pop_screen()


# ==========================================
# MAIN DASHBOARD
# ==========================================
class DeadshotUI(App):
    TITLE = "DEADSHOT TACTICAL O.S. (V9)"
    CSS = """
    Screen {
        background: #000000;
    }
    Header {
        background: #110000;
        color: #ff3333;
        text-style: bold;
    }
    #sidebar {
        width: 35;
        border-right: solid #660000;
        height: 100%;
        background: #0a0a0a;
    }
    #content_area {
        width: 1fr;
        padding: 1 2;
        background: #000000;
        align: center middle;
    }
    .category_title {
        color: #555555;
        padding-top: 1;
        padding-left: 2;
        text-style: bold;
    }
    ListView {
        background: #0a0a0a;
    }
    ListItem {
        padding: 1 2;
    }
    ListItem:focus {
        background: #440000;
    }
    .tool_title {
        color: #ff3333;
        text-style: bold;
        text-align: center;
        padding: 1;
    }
    .tool_desc {
        color: #888888;
        padding: 1;
        text-align: center;
    }
    """

    BINDINGS = [
        Binding("q", "quit", "Quit Framework"),
        Binding("escape", "back_to_menu", "Back to Phases")
    ]

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Horizontal():
            with Vertical(id="sidebar"):
                yield Label("TACTICAL PHASES", classes="category_title")
                yield ListView(id="categories")
            with Vertical(id="content_area"):
                yield Label("DEADSHOT TOOLS V9", classes="tool_title", id="current_tool_title")
                yield Label("Select an operation phase from the sidebar to arm tools.", classes="tool_desc", id="current_tool_desc")
                yield ListView(id="tool_list")
        yield Footer()

    def on_mount(self) -> None:
        self.install_screen(BootScreen(), name="boot")
        self.push_screen("boot")
        list_view = self.query_one("#categories", ListView)
        for cat in TOOLS.keys():
            item = ListItem(Label(cat))
            item.cat_name = cat
            list_view.append(item)

    def action_back_to_menu(self):
        self.query_one("#categories").focus()

    def on_list_view_selected(self, event: ListView.Selected):
        if event.list_view.id == "categories":
            cat_name = getattr(event.item, "cat_name", "")
            tool_list = self.query_one("#tool_list", ListView)
            tool_list.clear()

            self.query_one("#current_tool_title", Label).update(f"PHASE: {cat_name}")
            self.query_one("#current_tool_desc", Label).update("Select a specific cyber weapon to execute.")

            for tool_name, bash_cmd, desc in TOOLS.get(cat_name, []):
                item = ListItem(Label(tool_name))
                item.bash_cmd = bash_cmd
                item.desc = desc
                item.tool_name = tool_name
                tool_list.append(item)

            tool_list.focus()

        elif event.list_view.id == "tool_list":
            tool_name = getattr(event.item, "tool_name", "")
            bash_cmd = getattr(event.item, "bash_cmd", "")
            desc = getattr(event.item, "desc", "")

            self.query_one("#current_tool_title", Label).update(f"/// OP: {tool_name} ///")
            self.query_one("#current_tool_desc", Label).update(f"{desc}")

            # Suspend the cool UI to drop back to the standard bash hacker terminal
            with self.suspend():
                subprocess.run(["clear"], check=False)
                print(f"\033[31;40;1m[!] ARMING MODULE:\033[0m {tool_name}")
                try:
                    subprocess.run(["sudo", "./deadshot.sh", bash_cmd], check=True)
                except subprocess.CalledProcessError:
                    print(f"\033[1;30m[*] Tactic interrupted or failed.\033[0m")

            # Re-focus the menu when Bash returns
            self.query_one("#categories").focus()

if __name__ == "__main__":
    app = DeadshotUI()
    app.run()
