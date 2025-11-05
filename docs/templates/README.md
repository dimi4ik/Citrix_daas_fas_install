# Template-Anpassung und Konfiguration

## 📋 Übersicht

Diese Sektion dokumentiert die Anpassung des Citrix DaaS DevOps Templates für spezifische Projekte und Umgebungen.

## 🎯 Template-Customization Guide

### 🔧 Basis-Anpassungen

#### 1. Projekt-Konfiguration
```bash
# CLAUDE.md - AI-Tool Einstellungen
- Projektname aktualisieren
- Spezifische Entwicklerrichtlinien hinzufügen
- AI-Tool Konfiguration an Projekt anpassen

# docs/promt/promt.md - Projektspezifikation
- Konkrete Citrix DaaS Anforderungen definieren
- Target-Umgebungen spezifizieren
- Compliance-Anforderungen dokumentieren
```

#### 2. Umgebungs-Konfiguration
```hcl
# terraform.auto.tfvars (Beispiel)
project_name     = "mein-citrix-projekt"
environment      = "dev|test|prod"
location         = "West Europe"
cost_center      = "IT-Infrastructure"
contact_email    = "devops@unternehmen.de"

# Umgebungs-spezifische Tags
common_tags = {
  Project      = "mein-citrix-projekt"
  Environment  = "dev"
  ManagedBy    = "Terraform"
  CostCenter   = "IT-Infrastructure"
}
```

#### 3. Cloud-Provider Anpassungen
```bash
# Azure-spezifisch
- Service Principal Konfiguration
- Subscription und Resource Group Setup
- Network Connectivity (VNet, Subnets)

# On-Premises
- VMware vCenter Connectivity
- Netzwerk-Routing Konfiguration
- Backup und Disaster Recovery Setup
```

## 📖 Geplante Template-Beispiele

### 🌟 Beispiel-Szenarien
**Dateien**: `{scenario}-example.md`

#### Enterprise-Deployment
- **Datei**: `enterprise-deployment-example.md`
- Multi-Umgebung Setup (Dev/Test/Prod)
- Umfassende Monitoring und Alerting
- Compliance und Governance Integration

#### Small-Medium Business
- **Datei**: `smb-deployment-example.md`
- Kostengünstige Single-Environment Konfiguration
- Simplified Monitoring Setup
- Basic Security und Backup

#### Hybrid-Cloud Setup
- **Datei**: `hybrid-cloud-example.md`
- Azure + On-Premises Integration
- Network Connectivity Patterns
- Data Sync und Backup Strategien

#### Development Environment
- **Datei**: `development-environment-example.md`
- Lightweight Testing Setup
- Rapid Provisioning/Deprovisioning
- Developer-optimierte Konfiguration

### 🛠️ Konfiguration-Templates

#### Terraform-Variablen Templates
**Datei**: `terraform-variables-template.md`
```hcl
# Beispiel terraform.auto.tfvars Template
variable "project_config" {
  description = "Projekt-spezifische Konfiguration"
  type = object({
    name        = string
    environment = string
    location    = string
    tags        = map(string)
  })
}

variable "citrix_config" {
  description = "Citrix DaaS spezifische Einstellungen"
  type = object({
    resource_location = string
    capacity_config   = object({
      min_instances = number
      max_instances = number
    })
  })
}
```

#### Ansible-Inventar Templates
**Datei**: `ansible-inventory-template.md`
```yaml
# Beispiel Inventory-Struktur
all:
  children:
    citrix_cloud:
      hosts:
        citrix-controller-01:
          ansible_host: 10.0.1.10
          environment: production
    
    citrix_workers:
      hosts:
        worker-[01:05]:
          ansible_host: 10.0.2.[10:14]
          environment: production
```

## 🔄 Template-Migration und Updates

### 📋 Geplante Migration Guides
**Dateien**: `migration-v{version}.md`

#### Template-Version Updates
- **migration-v1.1.md**: Minor Version Updates
- **migration-v2.0.md**: Major Version Breaking Changes
- **migration-legacy.md**: Migration von Legacy-Konfigurationen

#### Best Practices Migration
- Schritt-für-Schritt Update-Anleitungen
- Backward-Compatibility Hinweise
- Rollback-Strategien bei Problemen

### 🔧 Customization Best Practices

#### Template-Modifikationen
```bash
# Empfohlene Anpassungsbereiche
✅ Terraform Variables (terraform.auto.tfvars)
✅ Ansible Inventories und Group Variables
✅ GitLab CI/CD Environment Variables
✅ Projektspezifische Dokumentation

# Nicht empfohlene Modifikationen
❌ Template-Kern-Struktur (.claude/, .cursor/, .github/)
❌ Pre-Commit Hook Konfiguration
❌ Basis-Terraform Module Interfaces
```

#### Versionierung und Updates
```bash
# Template-Updates verfolgen
git remote add template <original-template-repo>
git fetch template
git merge template/main  # Mit Vorsicht!

# Konflikte lösen und projektspezifische Anpassungen beibehalten
```

## 🎓 Template-Implementierung

> **Hinweis**: Detaillierte Template-Beispiele und Konfigurationen werden in **Phase 4: Template-Anpassbarkeit** implementiert, basierend auf konkreten Infrastruktur-Modulen aus Phase 3.

### Template-Entwicklungsstatus
- **✅ Phase 1**: Bestandsaufnahme und Bereinigung
- **🔄 Phase 2**: Dokumentations-Konsolidierung
- **📋 Phase 3**: Template-Struktur Optimierung (geplant)
- **📋 Phase 4**: Template-Anpassbarkeit (geplant)
- **📋 Phase 5**: Qualitätssicherung und Finalisierung (geplant)

### Nächste Entwicklungsschritte
1. **Terraform-Module** mit flexiblen Parametern entwickeln
2. **Ansible-Playbooks** mit Environment-Variables erstellen
3. **Beispiel-Konfigurationen** für verschiedene Szenarien
4. **Migration-Guides** für Template-Updates

## 🔗 Verwandte Dokumentation

- **[../architecture/](../architecture/)**: Architektur-Patterns und Design
- **[../deployment/](../deployment/)**: Deployment-Prozesse und Operations
- **[../../README.md](../../README.md)**: Template-Setup und Übersicht
- **[../../CLAUDE.md](../../CLAUDE.md)**: AI-Tool Konfiguration und Best Practices

## 💡 Template-Support

### Anpassungs-Hilfe
- **AI-Tools**: Claude Code `/validate`, `/plan` für Template-Validierung
- **Cursor IDE**: Automatische Best Practice Suggestions
- **GitHub Copilot**: Template-spezifische Code-Completion

### Community und Support
- **Template Issues**: Repository-spezifische Problem-Meldungen
- **Best Practices**: Community-getriebene Verbesserungsvorschläge
- **Updates**: Regelmäßige Template-Version Updates

---

**Template-Anpassung**: In Entwicklung  
**Template-Version**: v1.0.0  
**Implementierung**: Phase 4 Template-Anpassbarkeit