#!/bin/bash
# =============================================================================
# backup-configs.sh - Proxmox Konfigurationsdateien sichern
# =============================================================================
# Beschreibung: Sichert wichtige Proxmox-Konfigurationsdateien (/etc/pve/,
#               /etc/network/) in ein datiertes tar.gz-Archiv mit Manifest.
# Nutzung:      ./scripts/backup-configs.sh [ZIELVERZEICHNIS]
#               Standard-Zielverzeichnis: /root/pve-backups
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root

DEFAULT_BACKUP_DIR="/root/pve-backups"

# Erstellt das datierte Backup-Verzeichnis
# Parameter: base_path - Basis-Pfad für Backups
# Ausgabe: Pfad zum erstellten Backup-Verzeichnis
create_backup_dir() {
    local base_path="$1"
    local dated_dir
    dated_dir="${base_path}/pve-backup-$(date +%Y-%m-%d_%H%M%S)"

    if ! mkdir -p "$dated_dir" 2>/dev/null; then
        msg_error "Kann Backup-Verzeichnis nicht erstellen: ${dated_dir}"
        exit 1
    fi

    echo "$dated_dir"
}

# Sichert die Proxmox-Konfiguration aus /etc/pve/
# Parameter: backup_dir - Zielverzeichnis für die Sicherung
backup_pve_config() {
    local backup_dir="$1"

    msg_info "Sichere /etc/pve/..."
    if [[ -d /etc/pve ]]; then
        cp -a /etc/pve/ "${backup_dir}/etc-pve/" 2>/dev/null || {
            msg_warn "Einige Dateien in /etc/pve/ konnten nicht kopiert werden."
        }
        msg_ok "/etc/pve/ gesichert."
    else
        msg_warn "/etc/pve/ nicht gefunden. Überspringe."
    fi
}

# Sichert die Netzwerkkonfiguration aus /etc/network/
# Parameter: backup_dir - Zielverzeichnis für die Sicherung
backup_network_config() {
    local backup_dir="$1"

    msg_info "Sichere /etc/network/..."
    if [[ -d /etc/network ]]; then
        cp -a /etc/network/ "${backup_dir}/etc-network/" 2>/dev/null || {
            msg_warn "Einige Dateien in /etc/network/ konnten nicht kopiert werden."
        }
        msg_ok "/etc/network/ gesichert."
    else
        msg_warn "/etc/network/ nicht gefunden. Überspringe."
    fi
}

# Erstellt ein tar.gz-Archiv und eine Manifest-Datei
# Parameter: backup_dir - Das zu archivierende Backup-Verzeichnis
create_archive() {
    local backup_dir="$1"
    local archive="${backup_dir}.tar.gz"

    # Manifest erstellen
    msg_info "Erstelle Manifest..."
    {
        echo "# Proxmox Konfigurations-Backup"
        echo "# Erstellt: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "# Host: $(hostname)"
        echo "# ---"
        echo ""
        echo "Gesicherte Dateien:"
        find "$backup_dir" -type f | sort | while IFS= read -r file; do
            echo "  ${file#"$backup_dir"/}"
        done
    } > "${backup_dir}/manifest.txt"
    msg_ok "Manifest erstellt."

    # Archiv erstellen
    msg_info "Erstelle Archiv: ${archive}"
    if ! tar -czf "$archive" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")" 2>/dev/null; then
        msg_error "Fehler beim Erstellen des Archivs."
        exit 1
    fi

    # Temporäres Verzeichnis entfernen
    rm -rf "$backup_dir"

    msg_ok "Archiv erstellt: ${archive}"
}

# Hauptfunktion: Backup-Prozess orchestrieren
main() {
    local target_dir="${1:-$DEFAULT_BACKUP_DIR}"

    msg_info "Proxmox Konfigurations-Backup"
    msg_info "Zielverzeichnis: ${target_dir}"
    echo ""

    # Basis-Verzeichnis sicherstellen
    if ! mkdir -p "$target_dir" 2>/dev/null; then
        msg_error "Kann Zielverzeichnis nicht erstellen: ${target_dir}"
        exit 1
    fi

    local backup_dir
    backup_dir=$(create_backup_dir "$target_dir")

    backup_pve_config "$backup_dir"
    backup_network_config "$backup_dir"
    create_archive "$backup_dir"

    echo ""
    msg_ok "Backup erfolgreich abgeschlossen."
}

main "$@"
