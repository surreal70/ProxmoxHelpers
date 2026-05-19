# Implementation Plan: Proxmox Helper Scripts

## Overview

Inkrementelle Implementierung der Proxmox Helper Scripts, beginnend mit der gemeinsamen Bibliothek, gefolgt von den individuellen Skripten in logischer Reihenfolge (einfache Info-Skripte zuerst, dann komplexere Management-Skripte), abschließend README und Tests.

## Tasks

- [x] 1. Projektstruktur und gemeinsame Bibliothek erstellen
  - [x] 1.1 Projektverzeichnisse anlegen und `lib/common.sh` implementieren
    - Erstelle `scripts/` und `lib/` Verzeichnisse
    - Implementiere `lib/common.sh` mit: Farbdefinitionen (RED, GREEN, YELLOW, BLUE, NC), Ausgabefunktionen (msg_info, msg_ok, msg_warn, msg_error), check_root(), check_command(cmd), confirm(prompt), select_from_list()
    - Alle Funktionen mit Kommentaren dokumentieren
    - `set -euo pipefail` und Shebang setzen
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.7_

- [x] 2. Informations-Skripte implementieren
  - [x] 2.1 `scripts/list-lxcs.sh` implementieren
    - Source `lib/common.sh`, Root-Check
    - Funktion `get_all_containers()`: `pct list` parsen
    - Funktion `format_table()`: Tabellarische Ausgabe mit CTID, Hostname, Status, Ressourcen
    - Edge Case: Keine Container vorhanden → Info-Meldung
    - _Requirements: 7.1, 7.2, 7.3_

  - [x] 2.2 `scripts/list-vms.sh` implementieren
    - Source `lib/common.sh`, Root-Check
    - Funktion `get_all_vms()`: `qm list` parsen
    - Funktion `format_table()`: Tabellarische Ausgabe mit VMID, Name, Status, CPU, RAM
    - Edge Case: Keine VMs vorhanden → Info-Meldung
    - _Requirements: 6.1, 6.2, 6.3_

  - [x] 2.3 `scripts/check-disks.sh` implementieren
    - Source `lib/common.sh`, Root-Check
    - Funktion `show_block_devices()`: `lsblk` Übersicht
    - Funktion `show_smart_status()`: `smartctl` pro Festplatte, Warnung wenn nicht verfügbar
    - Funktion `show_storage_pools()`: `pvesm status` parsen
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [x] 2.4 `scripts/net-info.sh` implementieren
    - Source `lib/common.sh`, Root-Check
    - Funktion `show_bridges()`: `brctl show` oder `bridge link`
    - Funktion `show_interfaces()`: `ip addr` parsen
    - Funktion `show_routes()`: `ip route` ausgeben
    - Funktion `show_dns()`: `/etc/resolv.conf` anzeigen
    - _Requirements: 10.1, 10.2, 10.3, 10.4_

  - [x] 2.5 `scripts/show-firewall.sh` implementieren
    - Source `lib/common.sh`, Root-Check
    - Funktion `show_fw_status()`: Firewall-Status prüfen, Warnung wenn deaktiviert
    - Funktion `show_datacenter_rules()`: `pvesh get /cluster/firewall/rules`
    - Funktion `show_host_rules()`: `pvesh get /nodes/<node>/firewall/rules`
    - _Requirements: 12.1, 12.2, 12.3, 12.4_

- [x] 3. Checkpoint - Informations-Skripte prüfen
  - Ensure all scripts have correct structure (shebang, set -euo pipefail, root-check, function comments)
  - Run `bash -n` syntax check on all scripts
  - Ask the user if questions arise

- [x] 4. Management-Skripte implementieren
  - [x] 4.1 `scripts/restart-lxc.sh` implementieren
    - Source `lib/common.sh`, Root-Check, check_command pct
    - Funktion `get_running_containers()`: Laufende Container auflisten
    - Funktion `restart_container(ctid)`: Existenz prüfen, Status prüfen (bereits gestoppt?), Graceful Stop, Start, Erfolgsmeldung
    - `main()`: Argument-Parsing (CTID) oder Interactive Mode mit select_from_list
    - Fehlerbehandlung: Nicht-existente CTID, Stop-Fehler, Start-Fehler
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [x] 4.2 `scripts/restart-vm.sh` implementieren
    - Source `lib/common.sh`, Root-Check, check_command qm
    - Funktion `get_running_vms()`: Laufende VMs auflisten
    - Funktion `restart_vm(vmid)`: Existenz prüfen, Status prüfen, Graceful Stop, Start
    - `main()`: Argument-Parsing (VMID) oder Interactive Mode
    - Fehlerbehandlung: Nicht-existente VMID, Stop-Fehler, Start-Fehler
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 4.3 `scripts/snapshot-vm.sh` implementieren
    - Source `lib/common.sh`, Root-Check, check_command qm
    - Funktion `get_all_vms()`: Alle VMs auflisten
    - Funktion `create_snapshot(vmid)`: Snapshot mit Name `pre-maintenance-YYYYMMDD-HHMMSS` erstellen
    - `main()`: Argument-Parsing (VMID) oder Interactive Mode
    - Fehlerbehandlung: Nicht-existente VMID, Snapshot-Fehler
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

  - [x] 4.4 `scripts/update-proxmox.sh` implementieren
    - Source `lib/common.sh`, Root-Check
    - Funktion `check_updates()`: `apt update`, verfügbare Upgrades prüfen
    - Funktion `show_update_summary()`: Zusammenfassung anzeigen
    - Funktion `perform_update()`: `apt dist-upgrade -y`
    - `main()`: Prüfung → Zusammenfassung → Bestätigung → Update
    - Edge Cases: Keine Updates verfügbar, Update-Fehler
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

  - [x] 4.5 `scripts/cleanup-node.sh` implementieren
    - Source `lib/common.sh`, Root-Check
    - Funktion `get_disk_usage()`: Aktuelle Belegung erfassen
    - Funktion `clean_apt_cache()`: `apt clean` + `apt autoclean`
    - Funktion `remove_unused()`: `apt autoremove`
    - Funktion `clean_temp_files()`: Temporäre Dateien bereinigen
    - Funktion `show_savings()`: Vorher/Nachher Vergleich
    - `main()`: Zusammenfassung → Bestätigung → Bereinigung → Ergebnis
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

  - [x] 4.6 `scripts/backup-configs.sh` implementieren
    - Source `lib/common.sh`, Root-Check
    - Argument: Zielverzeichnis (optional, Standard: `/root/pve-backups`)
    - Funktion `create_backup_dir(path)`: Datiertes Verzeichnis erstellen
    - Funktion `backup_pve_config()`: `/etc/pve/` sichern
    - Funktion `backup_network_config()`: `/etc/network/` sichern
    - Funktion `create_archive(dir)`: tar.gz Archiv erstellen + manifest.txt
    - Fehlerbehandlung: Zielverzeichnis nicht erstellbar
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [x] 5. Checkpoint - Management-Skripte prüfen
  - Ensure all scripts have correct structure
  - Run `bash -n` syntax check on all scripts
  - Ensure all scripts pass `shellcheck`
  - Ask the user if questions arise

- [x] 6. README.md erstellen
  - [x] 6.1 Projekt-README.md schreiben
    - Projektbeschreibung mit Zweck und Umfang
    - Voraussetzungen (Proxmox VE, Root-Zugriff)
    - Installationsanweisungen (git clone, chmod +x)
    - Tabelle aller Skripte mit Kurzbeschreibung
    - Nutzungsbeispiele für jedes Skript (Argument-Mode und Interactive-Mode wo zutreffend)
    - Hinweise zu Berechtigungen und Sicherheit
    - Abschnitt "Externe Referenzen / Nützliche Links" mit allen Einträgen aus `externalrefs.txt`, thematisch gruppiert
    - Link zum Cheat-Sheet (`docs/proxmox-cheatsheet.md`)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 13.1, 13.2, 13.3, 14.5_

  - [x] 6.2 `docs/proxmox-cheatsheet.md` erstellen
    - Abschnitt Container-Verwaltung (pct): create, start, stop, restart, destroy, config, enter, console, list, resize, set
    - Abschnitt VM-Verwaltung (qm): create, start, stop, restart, destroy, config, snapshot, rollback, clone, migrate, template
    - Abschnitt Storage (pvesm): status, add, remove, scan, list
    - Abschnitt Cluster (pvecm): status, nodes, add, create, expected
    - Abschnitt Netzwerk: Bridges, VLANs, Firewall-Befehle
    - Abschnitt Backup & Restore: vzdump, qmrestore, pct restore, Zeitpläne
    - Jeder Befehl mit Kurzbeschreibung und Beispiel
    - _Requirements: 14.1, 14.2, 14.3, 14.4_

- [x] 7. Tests implementieren
  - [x] 7.1 bats-core Testframework einrichten
    - `tests/` Verzeichnis erstellen
    - bats-core Installationshinweise in README
    - Test-Helper für gemeinsame Setup-Logik

  - [x] 7.2 Property-Test: Script-Struktur-Compliance schreiben
    - **Property 6: Script structure compliance**
    - **Property 7: ShellCheck compliance**
    - **Property 8: Function documentation**
    - Iteriere über alle Skripte in `scripts/`, prüfe Shebang, set -euo pipefail, Header, Root-Check, ShellCheck, Funktionskommentare
    - **Validates: Requirements 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7**

  - [x] 7.3 Property-Test: README-Vollständigkeit schreiben
    - **Property 1: README documents all scripts**
    - Iteriere über alle Skripte in `scripts/`, prüfe ob README sie erwähnt und Nutzungsbeispiele enthält
    - **Validates: Requirements 1.2, 1.4**

  - [x] 7.4 Property-Test: Timestamp-Namenskonvention schreiben
    - **Property 5: Timestamp-based naming follows format**
    - Teste Namensgenerierungsfunktionen mit verschiedenen Zeitstempeln
    - **Validates: Requirements 8.3, 11.3**

- [x] 8. Final Checkpoint
  - Ensure all tests pass, ask the user if questions arise
  - Verify all scripts are executable and shellcheck-clean

## Notes

- All tasks are required (no optional markers)
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate structural correctness across all scripts
- Manual integration testing on a Proxmox system is recommended after implementation
