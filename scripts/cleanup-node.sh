#!/bin/bash
# =============================================================================
# cleanup-node.sh - Proxmox Node bereinigen und Speicherplatz freigeben
# =============================================================================
# Beschreibung: Bereinigt APT-Paket-Cache, entfernt nicht mehr benötigte Pakete
#               und temporäre Dateien. Zeigt den freigegebenen Speicherplatz an.
# Nutzung:      ./scripts/cleanup-node.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root

# Erfasst die aktuelle Festplattenbelegung der Root-Partition in KB
get_disk_usage() {
    df / --output=used | tail -n 1 | tr -d ' '
}

# Bereinigt den APT-Paket-Cache
clean_apt_cache() {
    msg_info "Bereinige APT-Cache..."
    apt-get clean -qq 2>/dev/null
    apt-get autoclean -qq 2>/dev/null
    msg_ok "APT-Cache bereinigt."
}

# Entfernt nicht mehr benötigte Pakete
remove_unused() {
    msg_info "Entferne nicht mehr benötigte Pakete..."
    apt-get autoremove -y -qq 2>/dev/null
    msg_ok "Ungenutzte Pakete entfernt."
}

# Bereinigt temporäre Dateien
clean_temp_files() {
    msg_info "Bereinige temporäre Dateien..."
    # Alte Dateien in /tmp entfernen (älter als 7 Tage)
    find /tmp -type f -atime +7 -delete 2>/dev/null || true
    # Alte Logs rotieren/bereinigen
    if command -v journalctl &>/dev/null; then
        journalctl --vacuum-time=7d --quiet 2>/dev/null || true
    fi
    msg_ok "Temporäre Dateien bereinigt."
}

# Zeigt den freigegebenen Speicherplatz (Vorher/Nachher Vergleich)
# Parameter: usage_before - Belegung vor der Bereinigung in KB
show_savings() {
    local usage_before="$1"
    local usage_after
    usage_after=$(get_disk_usage)

    local saved_kb=$((usage_before - usage_after))
    local saved_mb=$((saved_kb / 1024))

    echo ""
    if [[ $saved_kb -gt 0 ]]; then
        msg_ok "Freigegebener Speicherplatz: ${saved_mb} MB"
    else
        msg_info "Kein zusätzlicher Speicherplatz freigegeben."
    fi
}

# Hauptfunktion: Zusammenfassung → Bestätigung → Bereinigung → Ergebnis
main() {
    msg_info "Node-Bereinigung"
    echo ""
    msg_info "Folgende Aktionen werden durchgeführt:"
    echo "  - APT-Paket-Cache bereinigen (apt clean + autoclean)"
    echo "  - Nicht mehr benötigte Pakete entfernen (apt autoremove)"
    echo "  - Temporäre Dateien bereinigen (/tmp, Journal-Logs)"
    echo ""

    if ! confirm "Bereinigung jetzt durchführen?"; then
        msg_info "Bereinigung abgebrochen."
        exit 0
    fi

    echo ""
    local usage_before
    usage_before=$(get_disk_usage)

    clean_apt_cache
    remove_unused
    clean_temp_files

    show_savings "$usage_before"
}

main "$@"
