#!/bin/bash
# =============================================================================
# net-info.sh - Netzwerk-Informationen anzeigen
# =============================================================================
# Beschreibung: Zeigt Bridges, Interfaces mit IP-Adressen, Routing-Tabelle
#               und DNS-Konfiguration des Proxmox VE Hosts an.
# Nutzung:      ./scripts/net-info.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root

# Zeigt alle Netzwerk-Bridges und deren Mitglieder
show_bridges() {
    msg_info "Netzwerk-Bridges:"
    echo ""

    if command -v bridge &>/dev/null; then
        bridge link 2>/dev/null || msg_warn "bridge link konnte nicht ausgeführt werden."
    elif command -v brctl &>/dev/null; then
        brctl show 2>/dev/null || msg_warn "brctl show konnte nicht ausgeführt werden."
    else
        msg_warn "Weder 'bridge' noch 'brctl' verfügbar."
    fi
    echo ""
}

# Zeigt alle Netzwerk-Interfaces mit IP-Adressen
show_interfaces() {
    msg_info "Netzwerk-Interfaces:"
    echo ""
    ip -brief addr show 2>/dev/null || {
        ip addr show 2>/dev/null || msg_warn "ip addr konnte nicht ausgeführt werden."
    }
    echo ""
}

# Zeigt die aktuelle Routing-Tabelle
show_routes() {
    msg_info "Routing-Tabelle:"
    echo ""
    ip route show 2>/dev/null || msg_warn "ip route konnte nicht ausgeführt werden."
    echo ""
}

# Zeigt die DNS-Konfiguration
show_dns() {
    msg_info "DNS-Konfiguration (/etc/resolv.conf):"
    echo ""
    if [[ -f /etc/resolv.conf ]]; then
        cat /etc/resolv.conf
    else
        msg_warn "/etc/resolv.conf nicht gefunden."
    fi
    echo ""
}

# Hauptfunktion: Alle Netzwerk-Informationen anzeigen
main() {
    msg_info "Netzwerk-Übersicht"
    echo "==========================================="
    echo ""

    show_bridges
    show_interfaces
    show_routes
    show_dns

    msg_ok "Netzwerk-Übersicht abgeschlossen."
}

main "$@"
