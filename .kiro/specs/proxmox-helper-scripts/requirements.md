# Requirements Document

## Introduction

Dieses Dokument definiert die Anforderungen für eine Sammlung von Proxmox Helper-Skripten, die häufige Verwaltungsaufgaben auf Proxmox VE Hosts vereinfachen. Die Sammlung umfasst Skripte für Container- und VM-Verwaltung, System-Updates, Backups, Netzwerk- und Festplatteninformationen sowie Firewall-Übersicht.

## Glossary

- **Proxmox_Helper_Scripts**: Die Sammlung von Shell-Skripten zur Proxmox VE Verwaltung
- **LXC_Container**: Ein Linux Container, der auf dem Proxmox VE Host läuft
- **VM**: Eine virtuelle Maschine (QEMU/KVM), die auf dem Proxmox VE Host läuft
- **CTID**: Container ID — die eindeutige numerische Kennung eines LXC-Containers
- **VMID**: Virtual Machine ID — die eindeutige numerische Kennung einer VM
- **Graceful_Stop**: Ein kontrolliertes Herunterfahren via `pct stop` bzw. `qm stop`
- **Interactive_Mode**: Modus, in dem der Benutzer eine Auswahl aus einer Liste treffen kann
- **Argument_Mode**: Modus, in dem die ID als Kommandozeilenargument übergeben wird
- **PCT**: Proxmox Container Toolkit — Kommandozeilenwerkzeug zur LXC-Verwaltung
- **QM**: QEMU Manager — Kommandozeilenwerkzeug zur VM-Verwaltung
- **Snapshot**: Ein Zustandsabbild einer VM zu einem bestimmten Zeitpunkt
- **SMART**: Self-Monitoring, Analysis and Reporting Technology — Festplattendiagnose

## Requirements

### Requirement 1: README-Dokumentation

**User Story:** Als Proxmox-Administrator möchte ich eine übersichtliche README.md-Dokumentation, damit ich schnell verstehe, welche Skripte verfügbar sind und wie ich sie verwende.

#### Acceptance Criteria

1. WHEN die README.md erstellt wird, THEN SHALL die Proxmox_Helper_Scripts eine Projektbeschreibung mit Zweck und Umfang enthalten
2. WHEN die README.md erstellt wird, THEN SHALL die Proxmox_Helper_Scripts eine Auflistung aller verfügbaren Skripte mit Kurzbeschreibung enthalten
3. WHEN die README.md erstellt wird, THEN SHALL die Proxmox_Helper_Scripts Installationsanweisungen und Voraussetzungen dokumentieren
4. WHEN die README.md erstellt wird, THEN SHALL die Proxmox_Helper_Scripts für jedes Skript Nutzungsbeispiele zeigen
5. WHEN die README.md erstellt wird, THEN SHALL die Proxmox_Helper_Scripts Hinweise zu Berechtigungen und Sicherheit enthalten

### Requirement 2: LXC-Container Neustart

**User Story:** Als Proxmox-Administrator möchte ich einen LXC-Container sicher neustarten, damit ich Wartungsaufgaben schnell und kontrolliert durchführen kann.

#### Acceptance Criteria

1. WHEN eine gültige CTID als Argument übergeben wird, THEN SHALL das Restart_Script den LXC_Container mit Graceful_Stop herunterfahren und anschließend starten
2. WHEN keine CTID als Argument übergeben wird, THEN SHALL das Restart_Script in den Interactive_Mode wechseln und laufende LXC_Container mit CTID und Hostname auflisten
3. WHEN der Benutzer eine CTID aus der Liste auswählt, THEN SHALL das Restart_Script den ausgewählten LXC_Container mit Graceful_Stop neustarten
4. IF der LXC_Container mit der angegebenen CTID nicht existiert, THEN SHALL das Restart_Script eine Fehlermeldung ausgeben und mit Exit-Code 1 beenden
5. IF der LXC_Container bereits gestoppt ist, THEN SHALL das Restart_Script den Container direkt starten und den Benutzer informieren
6. IF keine laufenden LXC_Container vorhanden sind, THEN SHALL das Restart_Script eine entsprechende Meldung ausgeben und mit Exit-Code 0 beenden

### Requirement 3: VM Neustart

**User Story:** Als Proxmox-Administrator möchte ich eine VM sicher neustarten, damit ich VM-Wartung kontrolliert durchführen kann.

#### Acceptance Criteria

1. WHEN eine gültige VMID als Argument übergeben wird, THEN SHALL das Restart_Script die VM mit Graceful_Stop herunterfahren und anschließend starten
2. WHEN keine VMID als Argument übergeben wird, THEN SHALL das Restart_Script in den Interactive_Mode wechseln und laufende VMs mit VMID und Name auflisten
3. IF die VM mit der angegebenen VMID nicht existiert, THEN SHALL das Restart_Script eine Fehlermeldung ausgeben und mit Exit-Code 1 beenden
4. IF die VM bereits gestoppt ist, THEN SHALL das Restart_Script die VM direkt starten und den Benutzer informieren
5. IF der Graceful_Stop fehlschlägt, THEN SHALL das Restart_Script eine Fehlermeldung mit Details ausgeben und mit Exit-Code 1 beenden

### Requirement 4: Proxmox System-Update

**User Story:** Als Proxmox-Administrator möchte ich Proxmox VE und installierte Pakete aktualisieren, damit mein System sicher und aktuell bleibt.

#### Acceptance Criteria

1. WHEN das Update-Skript ausgeführt wird, THEN SHALL es die Paketlisten aktualisieren und verfügbare Upgrades installieren
2. WHEN das Update-Skript ausgeführt wird, THEN SHALL es eine Zusammenfassung der aktualisierten Pakete anzeigen
3. IF keine Updates verfügbar sind, THEN SHALL das Update-Skript den Benutzer informieren und mit Exit-Code 0 beenden
4. IF ein Update fehlschlägt, THEN SHALL das Update-Skript eine Fehlermeldung ausgeben und den Benutzer über den Zustand informieren
5. WHEN das Update-Skript ausgeführt wird, THEN SHALL es den Benutzer vor dem Upgrade um Bestätigung bitten

### Requirement 5: Node-Bereinigung

**User Story:** Als Proxmox-Administrator möchte ich Paket-Cache, temporäre Dateien und ungenutzte Daten bereinigen, damit Speicherplatz freigegeben wird.

#### Acceptance Criteria

1. WHEN das Cleanup-Skript ausgeführt wird, THEN SHALL es den APT-Paket-Cache bereinigen
2. WHEN das Cleanup-Skript ausgeführt wird, THEN SHALL es temporäre Dateien entfernen
3. WHEN das Cleanup-Skript ausgeführt wird, THEN SHALL es nicht mehr benötigte Pakete entfernen (autoremove)
4. WHEN das Cleanup-Skript ausgeführt wird, THEN SHALL es den freigegebenen Speicherplatz anzeigen
5. WHEN das Cleanup-Skript ausgeführt wird, THEN SHALL es vor destruktiven Aktionen eine Zusammenfassung anzeigen und Bestätigung verlangen

### Requirement 6: VM-Auflistung

**User Story:** Als Proxmox-Administrator möchte ich alle VMs mit nützlichen Details auflisten, damit ich einen schnellen Überblick über meinen Cluster habe.

#### Acceptance Criteria

1. WHEN das List-VMs-Skript ausgeführt wird, THEN SHALL es alle VMs mit VMID, Name, Status und zugewiesenen Ressourcen (CPU, RAM) anzeigen
2. WHEN das List-VMs-Skript ausgeführt wird, THEN SHALL es die Ausgabe tabellarisch formatieren
3. IF keine VMs vorhanden sind, THEN SHALL das Skript eine entsprechende Meldung ausgeben

### Requirement 7: LXC-Container-Auflistung

**User Story:** Als Proxmox-Administrator möchte ich alle LXC-Container mit nützlichen Details auflisten, damit ich einen schnellen Überblick habe.

#### Acceptance Criteria

1. WHEN das List-LXCs-Skript ausgeführt wird, THEN SHALL es alle LXC_Container mit CTID, Hostname, Status und zugewiesenen Ressourcen anzeigen
2. WHEN das List-LXCs-Skript ausgeführt wird, THEN SHALL es die Ausgabe tabellarisch formatieren
3. IF keine LXC_Container vorhanden sind, THEN SHALL das Skript eine entsprechende Meldung ausgeben

### Requirement 8: Konfigurations-Backup

**User Story:** Als Proxmox-Administrator möchte ich wichtige Proxmox-Konfigurationsdateien sichern, damit ich im Fehlerfall schnell wiederherstellen kann.

#### Acceptance Criteria

1. WHEN das Backup-Skript ausgeführt wird, THEN SHALL es Konfigurationsdateien aus `/etc/pve/` sichern
2. WHEN das Backup-Skript ausgeführt wird, THEN SHALL es Netzwerkkonfiguration und Storage-Konfiguration einschließen
3. WHEN das Backup-Skript ausgeführt wird, THEN SHALL es ein datiertes Archiv im angegebenen Zielverzeichnis erstellen
4. WHEN kein Zielverzeichnis angegeben wird, THEN SHALL das Backup-Skript ein Standard-Verzeichnis verwenden
5. IF das Zielverzeichnis nicht existiert, THEN SHALL das Backup-Skript es erstellen oder eine Fehlermeldung ausgeben

### Requirement 9: Festplatten-Informationen

**User Story:** Als Proxmox-Administrator möchte ich Festplatten-, SMART- und Storage-Informationen anzeigen, damit ich den Zustand meiner Speichermedien überwachen kann.

#### Acceptance Criteria

1. WHEN das Check-Disks-Skript ausgeführt wird, THEN SHALL es alle erkannten Festplatten mit Größe und Typ anzeigen
2. WHEN das Check-Disks-Skript ausgeführt wird, THEN SHALL es SMART-Gesundheitsstatus für jede Festplatte anzeigen
3. WHEN das Check-Disks-Skript ausgeführt wird, THEN SHALL es Proxmox Storage-Pools mit Belegung anzeigen
4. IF SMART-Daten nicht verfügbar sind, THEN SHALL das Skript eine Warnung ausgeben und fortfahren

### Requirement 10: Netzwerk-Informationen

**User Story:** Als Proxmox-Administrator möchte ich Bridges, Interfaces, Routen und IP-Konfiguration anzeigen, damit ich Netzwerkprobleme schnell diagnostizieren kann.

#### Acceptance Criteria

1. WHEN das Net-Info-Skript ausgeführt wird, THEN SHALL es alle Netzwerk-Bridges und deren Mitglieder anzeigen
2. WHEN das Net-Info-Skript ausgeführt wird, THEN SHALL es alle Netzwerk-Interfaces mit IP-Adressen anzeigen
3. WHEN das Net-Info-Skript ausgeführt wird, THEN SHALL es die aktuelle Routing-Tabelle anzeigen
4. WHEN das Net-Info-Skript ausgeführt wird, THEN SHALL es DNS-Konfiguration anzeigen

### Requirement 11: VM-Snapshot

**User Story:** Als Proxmox-Administrator möchte ich vor Wartungsarbeiten einen VM-Snapshot erstellen, damit ich bei Problemen schnell zurückrollen kann.

#### Acceptance Criteria

1. WHEN eine gültige VMID als Argument übergeben wird, THEN SHALL das Snapshot-Skript einen Snapshot der VM erstellen
2. WHEN keine VMID als Argument übergeben wird, THEN SHALL das Snapshot-Skript in den Interactive_Mode wechseln und VMs auflisten
3. WHEN ein Snapshot erstellt wird, THEN SHALL das Skript einen automatischen Namen mit Zeitstempel vergeben
4. WHEN ein Snapshot erfolgreich erstellt wird, THEN SHALL das Skript eine Bestätigung mit Snapshot-Name ausgeben
5. IF die VM nicht existiert, THEN SHALL das Snapshot-Skript eine Fehlermeldung ausgeben und mit Exit-Code 1 beenden

### Requirement 12: Firewall-Regeln anzeigen

**User Story:** Als Proxmox-Administrator möchte ich die effektiven Firewall-Regeln für den Node anzeigen, damit ich die Sicherheitskonfiguration überprüfen kann.

#### Acceptance Criteria

1. WHEN das Firewall-Skript ausgeführt wird, THEN SHALL es die Datacenter-Firewall-Regeln anzeigen
2. WHEN das Firewall-Skript ausgeführt wird, THEN SHALL es die Host-Firewall-Regeln anzeigen
3. WHEN das Firewall-Skript ausgeführt wird, THEN SHALL es den Firewall-Status (aktiv/inaktiv) anzeigen
4. IF die Firewall deaktiviert ist, THEN SHALL das Skript eine deutliche Warnung ausgeben

### Requirement 13: Externe Referenzen in README

**User Story:** Als Proxmox-Administrator möchte ich eine kuratierte Liste externer Referenzen und nützlicher Links in der README, damit ich schnell auf weiterführende Ressourcen zugreifen kann.

#### Acceptance Criteria

1. WHEN die README.md erstellt wird, THEN SHALL sie einen Abschnitt "Externe Referenzen / Nützliche Links" enthalten
2. WHEN die README.md erstellt wird, THEN SHALL sie alle Einträge aus der Datei `externalrefs.txt` als klickbare Links mit Beschreibung enthalten
3. WHEN die README.md erstellt wird, THEN SHALL die Links thematisch gruppiert sein (z.B. Offizielle Dokumentation, Community-Projekte, Monitoring)

### Requirement 14: Proxmox VE Kommandozeilen-Cheat-Sheet

**User Story:** Als Proxmox-Administrator möchte ich ein übersichtliches Cheat-Sheet für häufig verwendete Proxmox-CLI-Befehle, damit ich Kommandos schnell nachschlagen kann ohne die Dokumentation durchsuchen zu müssen.

#### Acceptance Criteria

1. WHEN das Cheat-Sheet erstellt wird, THEN SHALL es als eigenständige Datei `docs/proxmox-cheatsheet.md` im Projekt abgelegt werden
2. WHEN das Cheat-Sheet erstellt wird, THEN SHALL es Abschnitte für Container-Verwaltung (pct), VM-Verwaltung (qm), Storage (pvesm), Cluster (pvecm) und Netzwerk enthalten
3. WHEN das Cheat-Sheet erstellt wird, THEN SHALL es für jeden Befehl eine Kurzbeschreibung und ein Beispiel enthalten
4. WHEN das Cheat-Sheet erstellt wird, THEN SHALL es häufige Aufgaben wie Start/Stop/Restart, Migration, Backup/Restore, Snapshot-Verwaltung und Ressourcen-Anpassung abdecken
5. WHEN die README.md erstellt wird, THEN SHALL sie auf das Cheat-Sheet verlinken

### Requirement 15: Gemeinsame Standards

**User Story:** Als Proxmox-Administrator möchte ich, dass alle Skripte konsistenten Standards folgen, damit Wartbarkeit und Zuverlässigkeit gewährleistet sind.

#### Acceptance Criteria

1. WHEN ein Skript erstellt wird, THEN SHALL es `set -euo pipefail` als Standard-Shell-Optionen verwenden
2. WHEN ein Skript erstellt wird, THEN SHALL es eine Shebang-Zeile `#!/bin/bash` enthalten
3. WHEN ein Skript erstellt wird, THEN SHALL es einen Header-Kommentar mit Beschreibung und Nutzung enthalten
4. WHEN ein Skript gestartet wird, THEN SHALL es prüfen, ob es mit Root-Berechtigung ausgeführt wird
5. IF ein Skript ohne Root-Berechtigung ausgeführt wird, THEN SHALL es eine Fehlermeldung ausgeben und mit Exit-Code 1 beenden
6. WHEN ein Skript erstellt wird, THEN SHALL es ShellCheck-konform sein
7. WHEN Funktionen definiert werden, THEN SHALL jede Funktion mit einem Kommentar dokumentiert sein

## External References

Die Datei `externalrefs.txt` enthält folgende Referenzen, die in die README aufgenommen werden:
- Proxmox Hardening Guide (GitHub)
- ProxMenux (GitHub)
- PegaProx (Website + GitHub)
- PatchMon (Website + Proxmox Integration + GitHub)
- ProxForge Links
- Proxmox VE Offizielle Dokumentation
- Proxmox Wiki
- Proxmox Forum
