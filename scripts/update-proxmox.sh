#!/bin/bash
# =============================================================================
# update-proxmox.sh - Proxmox VE System-Update durchführen
# =============================================================================
# Beschreibung: Aktualisiert Paketlisten und installiert verfügbare Upgrades
#               auf dem Proxmox VE Host. Zeigt eine Zusammenfassung und fragt
#               vor dem Upgrade um Bestätigung.
# Nutzung:      ./scripts/update-proxmox.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root

# Aktualisiert Paketlisten und prüft verfügbare Upgrades
# Rückgabe: 0 wenn Updates verfügbar, 1 wenn keine Updates
check_updates() {
    msg_info "Aktualisiere Paketlisten..."
    if ! apt-get update -qq 2>/dev/null; then
        msg_error "Fehler beim Aktualisieren der Paketlisten."
        exit 1
    fi
    msg_ok "Paketlisten aktualisiert."

    local upgradable
    upgradable=$(apt list --upgradable 2>/dev/null | grep -c "upgradable" || true)

    if [[ "$upgradable" -eq 0 ]]; then
        return 1
    fi
    return 0
}

# Zeigt eine Zusammenfassung der verfügbaren Updates
show_update_summary() {
    msg_info "Verfügbare Updates:"
    echo ""
    apt list --upgradable 2>/dev/null | grep -v "^Listing" || true
    echo ""
}

# Führt das System-Upgrade durch
perform_update() {
    msg_info "Führe System-Upgrade durch..."
    if ! apt-get dist-upgrade -y 2>&1; then
        msg_error "Fehler beim System-Upgrade. Bitte manuell prüfen."
        exit 1
    fi
    msg_ok "System-Upgrade erfolgreich abgeschlossen."
}

# Hauptfunktion: Prüfung → Zusammenfassung → Bestätigung → Update
main() {
    msg_info "Proxmox VE System-Update"
    echo ""

    if ! check_updates; then
        msg_ok "Das System ist bereits auf dem neuesten Stand. Keine Updates verfügbar."
        exit 0
    fi

    show_update_summary

    if ! confirm "System-Upgrade jetzt durchführen?"; then
        msg_info "Update abgebrochen."
        exit 0
    fi

    echo ""
    perform_update
}

main "$@"
