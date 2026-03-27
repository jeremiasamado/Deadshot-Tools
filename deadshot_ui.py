import os
import sys
from textual.app import App, ComposeResult
from textual.containers import Horizontal, Vertical
from textual.widgets import Header, Footer, ListView, ListItem, Label
from textual.binding import Binding

TOOLS = {
    "AI Assistant & Intel": [
        ("Ollama Offline Oracle", "run_ai_assistant", "Spawns the Dolphin-Phi offline Red Team assistant for unhinged exploit generation."),
        ("Live Vulnerability Intel", "run_live_intel", "Tor-proxied OSINT gathering for active CVEs and bounties on GitHub/HackerOne.")
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

class DeadshotUI(App):
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
                list_view = ListView(id="categories")
                for cat in TOOLS.keys():
                    item = ListItem(Label(cat))
                    item.cat_name = cat
                    list_view.append(item)
                yield list_view
            with Vertical(id="content_area"):
                yield Label("DEADSHOT TOOLS V7", classes="tool_title", id="current_tool_title")
                yield Label("Select an operation phase from the sidebar to arm tools.", classes="tool_desc", id="current_tool_desc")
                yield ListView(id="tool_list")
        yield Footer()

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
                os.system("clear")
                print(f"\033[31;40;1m[!] ARMING MODULE:\033[0m {tool_name}")
                os.system(f"sudo ./deadshot.sh {bash_cmd}")
            
            # Re-focus the menu when Bash returns
            self.query_one("#categories").focus()

if __name__ == "__main__":
    app = DeadshotUI(title="DEADSHOT TACTICAL O.S. (V7)")
    app.run()
