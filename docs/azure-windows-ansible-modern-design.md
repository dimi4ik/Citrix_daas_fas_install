# Azure Windows Server 2025 - Moderne Ansible-Verbindung

## Status Quo (2025)

**WinRM ist veraltet:**
- Microsoft pflegt WinRM nicht mehr weiter
- Keine Security-Patches oder Verbesserungen mehr
- Komplexe Konfiguration (Zertifikate, Firewall, GPO)

## Moderne Lösung: OpenSSH + Azure Arc Agent

### Option 1: Native OpenSSH (Empfohlen für einfache Setups)

**Vorteile:**
- **Windows Server 2025**: OpenSSH standardmäßig installiert
- **Ansible Core 2.18+**: Native SSH-Unterstützung für Windows
- Einfachere Konfiguration als WinRM
- Key-basierte Authentifizierung
- Einheitliches Protokoll für Linux/Windows

**Ansible Inventory:**
```yaml
windows_hosts:
  hosts:
    win-server-2025:
      ansible_host: 10.0.1.10
      ansible_user: administrator
      ansible_connection: ssh
      ansible_shell_type: powershell
      ansible_ssh_private_key_file: ~/.ssh/azure_windows_key
```

**Azure VM Extension Setup:**
```bash
# Keine custom script extension nötig - OpenSSH ist bereits aktiv
# Nur SSH-Key deployment erforderlich
az vm run-command invoke \
  --resource-group myRG \
  --name myWinVM \
  --command-id RunPowerShellScript \
  --scripts @configure-openssh-key.ps1
```

### Option 2: Azure Arc Agent + SSH Proxy (Empfohlen für Hybrid/Production)

**Vorteile:**
- Keine VPN oder Jump Host erforderlich
- SSH-Verbindung durch Azure getunnelt (Reverse Proxy)
- Azure RBAC für Zugriffskontrolle
- Integration mit Azure Monitor, Update Management, Hotpatching
- Zentrale Verwaltung über Azure Portal

**Architecture:**
```
Ansible Controller → Azure Portal (Connection Broker) → Azure Arc Agent → Windows Server 2025
```

**Ansible mit Arc SSH Module:**
```yaml
- name: Connect via Azure Arc SSH
  hosts: azure_arc_windows
  connection: ssh
  vars:
    ansible_ssh_common_args: '-o ProxyCommand="az ssh arc --resource-group {{ resource_group }} --name {{ vm_name }}"'
```

**Azure Arc Installation:**
```powershell
# Automatisch via Azure Portal oder:
$env:SUBSCRIPTION_ID = "your-subscription-id"
$env:RESOURCE_GROUP = "your-rg"
$env:LOCATION = "westeurope"

Invoke-WebRequest -Uri "https://aka.ms/azcmagent-windows" -OutFile "AzureConnectedMachineAgent.msi"
msiexec /i AzureConnectedMachineAgent.msi /qn /l*v installationlog.txt

azcmagent connect --subscription-id $env:SUBSCRIPTION_ID `
                  --resource-group $env:RESOURCE_GROUP `
                  --location $env:LOCATION `
                  --tenant-id "your-tenant-id"
```

## Design-Empfehlung

### Für Development/Testing:
**Option 1 - Native OpenSSH**
- Schnelles Setup
- Keine zusätzlichen Azure-Kosten für Arc
- Standard SSH-Key Authentifizierung

### Für Production/Enterprise:
**Option 2 - Azure Arc + SSH Proxy**
- Höhere Sicherheit (keine öffentlichen IPs erforderlich)
- Zentrale Governance und Compliance
- Integration mit Azure Security Center
- Einheitliche Patch-Management-Strategie

## Implementierung (Kurz)

### Terraform für Azure VM + Arc:
```hcl
resource "azurerm_windows_virtual_machine" "win_server" {
  name                = "win-server-2025"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-datacenter-azure-edition"
    version   = "latest"
  }
}

resource "azurerm_arc_machine" "arc_enabled" {
  name                = azurerm_windows_virtual_machine.win_server.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}
```

### Ansible Playbook für OpenSSH-Config:
```yaml
- name: Configure OpenSSH on Windows Server 2025
  hosts: windows
  tasks:
    - name: Ensure OpenSSH Server is running
      win_service:
        name: sshd
        state: started
        start_mode: auto

    - name: Set PowerShell as default shell
      win_shell: |
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" `
                         -Name DefaultShell `
                         -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" `
                         -PropertyType String -Force
```

## Vergleich

| Feature | WinRM (Legacy) | OpenSSH | Arc + SSH |
|---------|---------------|---------|-----------|
| Setup-Komplexität | Hoch | Niedrig | Mittel |
| Security Patches | ❌ Keine | ✅ Aktiv | ✅ Aktiv |
| Key Auth | ⚠️ Komplex | ✅ Native | ✅ Native |
| Azure Integration | ❌ Nein | ⚠️ Basic | ✅ Full |
| Kosten | Keine | Keine | Arc-Agent* |

*Arc-Agent: Kostenlos für Azure VMs, ~$5/Server/Monat für On-Prem

## Zusammenfassung

**Für Windows Server 2025 in Azure im Jahr 2025:**
- ❌ **WinRM nicht mehr verwenden** (EOL)
- ✅ **OpenSSH ist der moderne Standard**
- ✅ **Azure Arc für Enterprise-Szenarien**

**Nächste Schritte:**
1. Azure VM mit Windows Server 2025 erstellen (OpenSSH ist bereits aktiv)
2. SSH-Keys deployen (via Azure Key Vault oder run-command)
3. Optional: Arc-Agent installieren für erweiterte Features
4. Ansible Inventory auf `ansible_connection: ssh` umstellen
