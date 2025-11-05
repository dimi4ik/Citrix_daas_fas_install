# Dokumentationsstruktur

Diese Dokumentation ist in logische Bereiche unterteilt, um eine klare Navigation und Wartung zu ermöglichen.

## 📁 Dokumentationsübersicht

### 🏗️ [architecture/](./architecture/)
Architektur-Dokumentation und Design-Entscheidungen
- **Systemarchitektur**: Citrix DaaS Infrastruktur-Design
- **Komponenten-Übersicht**: Terraform-Module und Ansible-Rollen
- **Netzwerk-Design**: Multi-Cloud Connectivity Patterns
- **Sicherheitsarchitektur**: Identity, Access Management, Encryption

### 🚀 [deployment/](./deployment/)
Deployment-Anleitungen und Betriebsdokumentation
- **Installation**: Schritt-für-Schritt Deployment-Guide
- **Konfiguration**: Umgebungs-spezifische Anpassungen
- **Monitoring**: Überwachung und Alerting Setup
- **Troubleshooting**: Häufige Probleme und Lösungen

### 📋 [templates/](./templates/)
Template-Anpassung und Projektspezifische Konfiguration
- **Template-Customization**: Anpassung für neue Projekte
- **Beispielkonfigurationen**: Vorgefertigte Szenarien
- **Best Practices**: Empfohlene Patterns und Workflows
- **Migration Guides**: Updates zwischen Template-Versionen

### 🎯 [promt/](./promt/)
Projektspezifikation und AI-Tool Konfiguration
- **promt.md**: XML-basierte Projektdefinition und Workflow-Spezifikation
- **AI-Integration**: Claude Code, Cursor, GitHub Copilot Konfigurationen

## 🗂️ Dokumentations-Konventionen

### Datei-Naming
```
- README.md              # Übersichts-Dokument pro Verzeichnis
- {component}-guide.md   # Komponent-spezifische Anleitungen
- {scenario}-example.md  # Beispiel-Implementierungen
- troubleshooting.md     # Problem-Lösungen
```

### Markdown-Standards
- **Deutsche Sprache** für alle Dokumentation
- **Konsistente Überschriften** (H1 für Titel, H2 für Hauptbereiche)
- **Code-Blöcke** mit Syntax-Highlighting
- **Emoji-Icons** für bessere visuelle Navigation
- **Interne Verlinkung** zwischen verwandten Dokumenten

### Versionierung
- Dokumentation folgt Template-Versionierung
- Breaking Changes werden in Migration Guides dokumentiert
- Changelog-Einträge für alle dokumentations-relevanten Änderungen

## 🔄 Wartung und Updates

### Automatische Updates
- **terraform-docs**: Automatische Terraform-Modul Dokumentation
- **Pre-Commit Hooks**: Markdown-Linting und Link-Validierung
- **GitLab CI/CD**: Dokumentations-Build und Deployment

### Review-Prozess
1. **Dokumentations-Änderungen** in Feature-Branch
2. **Review durch DevOps-Team** bei Merge Requests  
3. **Konsistenz-Prüfung** mit bestehender Dokumentation
4. **Template-Update** bei strukturellen Änderungen

## 📚 Zusätzliche Ressourcen

### Externe Dokumentation
- **[Citrix DaaS Documentation](https://docs.citrix.com/en-us/citrix-daas)**
- **[Terraform Documentation](https://www.terraform.io/docs)**
- **[Ansible Documentation](https://docs.ansible.com/)**
- **[GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)**

### Template-spezifische Dokumentation
- **[../README.md](../README.md)**: Haupt-Template Dokumentation
- **[../CLAUDE.md](../CLAUDE.md)**: AI-Tool Konfiguration
- **[../CHANGELOG.md](../CHANGELOG.md)**: Template-Versionshistorie
- **[../TEMPLATE_TODO.md](../TEMPLATE_TODO.md)**: Entwicklungs-Roadmap

---

**Dokumentationsstand**: Template v1.0.0  
**Letzte Aktualisierung**: 2025-06-22  
**Maintainer**: DevOps-Team mit AI-Tool Integration