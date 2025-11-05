#!/usr/bin/env python3
"""
MCP Server Konfiguration verwalten
Usage: 
  python3 copy-mcp-servers.py QUELL_PROJEKT ZIEL_PROJEKT              # Zwischen Projekten kopieren
  python3 copy-mcp-servers.py --export PROJEKT CONFIG_FILE            # Exportieren für anderen PC
  python3 copy-mcp-servers.py --import CONFIG_FILE ZIEL_PROJEKT       # Importieren von anderem PC
  python3 copy-mcp-servers.py --list                                  # Verfügbare Projekte anzeigen
"""

import json
import sys
import os
import shutil

def copy_mcp_servers(source_project, target_project):
    config_file = os.path.expanduser('~/.claude.json')
    
    # Backup erstellen
    os.system(f'cp {config_file} {config_file}.backup')
    
    # JSON laden
    with open(config_file, 'r') as f:
        data = json.load(f)
    
    projects = data['projects']
    
    # Quell-Projekt prüfen
    if source_project not in projects:
        print(f"❌ Quell-Projekt '{source_project}' nicht gefunden!")
        return False
    
    # MCP Server aus Quell-Projekt kopieren
    source_servers = projects[source_project].get('mcpServers', {})
    
    if not source_servers:
        print(f"❌ Keine MCP Server in '{source_project}' gefunden!")
        return False
    
    # Ziel-Projekt erstellen falls nicht vorhanden
    if target_project not in projects:
        projects[target_project] = {
            "allowedTools": [],
            "history": [],
            "mcpContextUris": [],
            "mcpServers": {},
            "enabledMcpjsonServers": [],
            "disabledMcpjsonServers": [],
            "hasTrustDialogAccepted": False,
            "projectOnboardingSeenCount": 0,
            "hasClaudeMdExternalIncludesApproved": False,
            "hasClaudeMdExternalIncludesWarningShown": False
        }
    
    # MCP Server kopieren
    projects[target_project]['mcpServers'] = source_servers.copy()
    
    # JSON speichern
    with open(config_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"✅ {len(source_servers)} MCP Server von '{source_project}' nach '{target_project}' kopiert:")
    for server in source_servers.keys():
        print(f"   - {server}")
    
    return True

def export_mcp_config(project_path, export_file):
    """MCP Server Konfiguration für anderen PC exportieren"""
    config_file = os.path.expanduser('~/.claude.json')
    
    with open(config_file, 'r') as f:
        data = json.load(f)
    
    if project_path not in data['projects']:
        print(f"❌ Projekt '{project_path}' nicht gefunden!")
        return False
    
    servers = data['projects'][project_path].get('mcpServers', {})
    
    if not servers:
        print(f"❌ Keine MCP Server in '{project_path}' gefunden!")
        return False
    
    # Export-Konfiguration erstellen
    export_config = {
        'source_project': project_path,
        'export_date': __import__('datetime').datetime.now().isoformat(),
        'mcp_servers': servers,
        'docker_commands': []
    }
    
    # Docker Pull Commands für alle Images generieren
    for server_name, config in servers.items():
        if config.get('command') == 'docker':
            # Docker Image aus args extrahieren
            args = config.get('args', [])
            for i, arg in enumerate(args):
                if not arg.startswith('-') and '/' in arg and ':' in arg:
                    export_config['docker_commands'].append(f"docker pull {arg}")
                elif not arg.startswith('-') and '/' in arg:
                    export_config['docker_commands'].append(f"docker pull {arg}:latest")
    
    # Export speichern
    with open(export_file, 'w') as f:
        json.dump(export_config, f, indent=2)
    
    print(f"✅ MCP Server Konfiguration exportiert nach: {export_file}")
    print(f"📦 {len(servers)} Server: {', '.join(servers.keys())}")
    print(f"🐳 {len(export_config['docker_commands'])} Docker Images")
    
    return True

def import_mcp_config(import_file, target_project):
    """MCP Server Konfiguration von anderem PC importieren"""
    config_file = os.path.expanduser('~/.claude.json')
    
    # Backup erstellen
    shutil.copy2(config_file, f"{config_file}.backup")
    
    # Import-Datei laden
    try:
        with open(import_file, 'r') as f:
            import_config = json.load(f)
    except FileNotFoundError:
        print(f"❌ Import-Datei '{import_file}' nicht gefunden!")
        return False
    except json.JSONDecodeError:
        print(f"❌ Ungültiges JSON in '{import_file}'!")
        return False
    
    # Claude-Konfiguration laden
    with open(config_file, 'r') as f:
        data = json.load(f)
    
    # Ziel-Projekt erstellen falls nicht vorhanden
    if target_project not in data['projects']:
        data['projects'][target_project] = {
            "allowedTools": [],
            "history": [],
            "mcpContextUris": [],
            "mcpServers": {},
            "enabledMcpjsonServers": [],
            "disabledMcpjsonServers": [],
            "hasTrustDialogAccepted": False,
            "projectOnboardingSeenCount": 0,
            "hasClaudeMdExternalIncludesApproved": False,
            "hasClaudeMdExternalIncludesWarningShown": False
        }
    
    # MCP Server importieren
    imported_servers = import_config.get('mcp_servers', {})
    data['projects'][target_project]['mcpServers'] = imported_servers
    
    # Claude-Konfiguration speichern
    with open(config_file, 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"✅ {len(imported_servers)} MCP Server importiert nach '{target_project}':")
    for server in imported_servers.keys():
        print(f"   - {server}")
    
    # Docker Commands anzeigen
    docker_commands = import_config.get('docker_commands', [])
    if docker_commands:
        print(f"\n🐳 Benötigte Docker Images (vor Claude Code Start ausführen):")
        for cmd in docker_commands:
            print(f"   {cmd}")
    
    return True

def list_projects():
    """Verfügbare Projekte und deren MCP Server anzeigen"""
    config_file = os.path.expanduser('~/.claude.json')
    
    with open(config_file, 'r') as f:
        data = json.load(f)
    
    print("Verfügbare Projekte:")
    for project in data['projects'].keys():
        servers = list(data['projects'][project].get('mcpServers', {}).keys())
        if servers:
            print(f"  {project} (Server: {', '.join(servers)})")
        else:
            print(f"  {project} (keine Server)")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    
    if sys.argv[1] == "--list":
        list_projects()
    elif sys.argv[1] == "--export" and len(sys.argv) == 4:
        export_mcp_config(sys.argv[2], sys.argv[3])
    elif sys.argv[1] == "--import" and len(sys.argv) == 4:
        import_mcp_config(sys.argv[2], sys.argv[3])
    elif len(sys.argv) == 3:
        copy_mcp_servers(sys.argv[1], sys.argv[2])
    else:
        print(__doc__)
        list_projects()