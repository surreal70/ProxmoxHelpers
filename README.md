# Proxmox Helper Scripts

Eine Sammlung von Bash-Skripten zur Vereinfachung häufiger Verwaltungsaufgaben auf Proxmox VE Hosts. Die Skripte bieten eine konsistente, sichere und benutzerfreundliche Schnittstelle für Container- und VM-Verwaltung, System-Updates, Backups, Netzwerk- und Festplattendiagnose sowie Firewall-Übersicht.

## Voraussetzungen

- **Proxmox VE** 7.x oder höher
- **Root-Zugriff** auf den Proxmox-Host
- Standard-Linux-Tools (`lsblk`, `smartctl`, `ip`, `bridge`)
- Proxmox-CLI-Tools (`pct`, `qm`, `pvesh`, `pvesm`)

## Installation

```bash
# Repository klonen
git clone <repository-url> /opt/proxmox-helper-scripts
cd /opt/proxmox-helper-scripts

# Skripte ausführbar machen
chmod +x scripts/*.sh
```

## Verfügbare Skripte

| Skript | Beschreibung |
|--------|-------------|
| `list-lxcs.sh` | Alle LXC-Container mit CTID, Hostname, Status und Ressourcen auflisten |
| `list-vms.sh` | Alle VMs mit VMID, Name, Status, CPU und RAM auflisten |
| `restart-lxc.sh` | LXC-Container sicher neustarten (Graceful Stop + Start) |
| `restart-vm.sh` | VM sicher neustarten (Graceful Stop + Start) |
| `snapshot-vm.sh` | VM-Snapshot mit Zeitstempel vor Wartungsarbeiten erstellen |
| `update-proxmox.sh` | Proxmox VE System-Update mit Bestätigung durchführen |
| `cleanup-node.sh` | Node bereinigen: APT-Cache, ungenutzte Pakete, temporäre Dateien |
| `backup-configs.sh` | Proxmox-Konfigurationsdateien (/etc/pve/, /etc/network/) sichern |
| `check-disks.sh` | Festplatten, SMART-Status und Storage-Pools anzeigen |
| `net-info.sh` | Bridges, Interfaces, Routen und DNS-Konfiguration anzeigen |
| `show-firewall.sh` | Firewall-Status und Regeln (Datacenter + Host) anzeigen |

## Nutzungsbeispiele

### Container & VM auflisten

```bash
# Alle LXC-Container anzeigen
./scripts/list-lxcs.sh

# Alle VMs anzeigen
./scripts/list-vms.sh
```

### LXC-Container neustarten

```bash
# Argument-Mode: CTID direkt angeben
./scripts/restart-lxc.sh 100

# Interactive Mode: Auswahl aus laufenden Containern
./scripts/restart-lxc.sh
```

### VM neustarten

```bash
# Argument-Mode: VMID direkt angeben
./scripts/restart-vm.sh 200

# Interactive Mode: Auswahl aus laufenden VMs
./scripts/restart-vm.sh
```

### VM-Snapshot erstellen

```bash
# Argument-Mode: VMID direkt angeben
./scripts/snapshot-vm.sh 200

# Interactive Mode: VM aus Liste auswählen
./scripts/snapshot-vm.sh
```

Snapshot-Name wird automatisch generiert: `pre-maintenance-YYYYMMDD-HHMMSS`

### System-Update

```bash
# Paketlisten aktualisieren und Upgrades installieren (mit Bestätigung)
./scripts/update-proxmox.sh
```

### Node bereinigen

```bash
# APT-Cache, ungenutzte Pakete und temporäre Dateien bereinigen
./scripts/cleanup-node.sh
```

### Konfiguration sichern

```bash
# Backup in Standard-Verzeichnis (/root/pve-backups)
./scripts/backup-configs.sh

# Backup in benutzerdefiniertes Verzeichnis
./scripts/backup-configs.sh /mnt/backup/proxmox
```

### Festplatten prüfen

```bash
# Block-Devices, SMART-Status und Storage-Pools anzeigen
./scripts/check-disks.sh
```

### Netzwerk-Informationen

```bash
# Bridges, Interfaces, Routen und DNS anzeigen
./scripts/net-info.sh
```

### Firewall-Regeln anzeigen

```bash
# Firewall-Status, Datacenter- und Host-Regeln anzeigen
./scripts/show-firewall.sh
```

## Berechtigungen und Sicherheit

- Alle Skripte erfordern **Root-Berechtigung** und prüfen dies beim Start
- Destruktive Aktionen (Update, Cleanup) erfordern eine **explizite Bestätigung**
- Fehlerbehandlung mit `set -euo pipefail` verhindert stille Fehler
- Graceful Stop wird für Container/VM-Neustarts verwendet (kein hartes Kill)
- Backup-Skripte erstellen datierte Archive zur Versionierung

## Projektstruktur

```
proxmox-helper-scripts/
├── README.md
├── externalrefs.txt
├── docs/
│   └── proxmox-cheatsheet.md    # CLI Cheat-Sheet
├── lib/
│   └── common.sh                # Gemeinsame Bibliothek
└── scripts/
    ├── backup-configs.sh
    ├── check-disks.sh
    ├── cleanup-node.sh
    ├── list-lxcs.sh
    ├── list-vms.sh
    ├── net-info.sh
    ├── restart-lxc.sh
    ├── restart-vm.sh
    ├── show-firewall.sh
    ├── snapshot-vm.sh
    └── update-proxmox.sh
```

## Proxmox CLI Cheat-Sheet

Ein umfassendes Nachschlagewerk für häufig verwendete Proxmox-CLI-Befehle ist verfügbar unter:

➡️ [docs/proxmox-cheatsheet.md](docs/proxmox-cheatsheet.md)

## Externe Referenzen / Nützliche Links

### Offizielle Proxmox-Ressourcen

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/) — Offizielle Proxmox VE Dokumentation
- [Proxmox Wiki](https://pve.proxmox.com/wiki/) — Community-Wiki mit Anleitungen und Tipps
- [Proxmox Forum](https://forum.proxmox.com/) — Offizielles Support-Forum

### Community-Projekte

- [Proxmox Hardening Guide](https://github.com/HomeSecExplorer/Proxmox-Hardening-Guide) — Sicherheitshärtung für Proxmox VE
- [ProxMenux](https://github.com/MacRimi/ProxMenux) — Menübasiertes Verwaltungstool für Proxmox
- [ProxForge Links](https://proxforge.de/links/) — Kuratierte Linksammlung rund um Proxmox

### Monitoring & Management

- [PegaProx](https://pegaprox.com/) — Proxmox Management-Lösung ([GitHub](https://github.com/PegaProx/project-pegaprox))
- [PatchMon](https://patchmon.net/) — Patch-Monitoring mit [Proxmox-Integration](https://patchmon.net/integrations/proxmox) ([GitHub](https://github.com/PatchMon/PatchMon))

## Tests

Die Tests verwenden [bats-core](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

### Installation

```bash
# bats-core installieren (Debian/Ubuntu)
apt install bats

# Oder via Git
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local
```

### Tests ausführen

```bash
# Alle Tests ausführen
bats tests/

# Einzelne Testdatei ausführen
bats tests/test_script_structure.bats
```

## Lizenz

Dieses Projekt steht unter der MIT-Lizenz.
