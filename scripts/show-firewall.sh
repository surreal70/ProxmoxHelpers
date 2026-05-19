#!/bin/bash
# =============================================================================
# show-firewall.sh - Firewall-Regeln und Status anzeigen
# =============================================================================
# Beschreibung: Zeigt den Firewall-Status (aktiv/inaktiv), Datacenter-Level
#               Firewall-Regeln und Host-Level Firewall-Regeln an.
#               Gibt eine Warnung aus wenn die Firewall deaktiviert ist.
# Nutzung:      ./scripts/show-firewall.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root

# Zeigt den Firewall-Status und warnt wenn deaktiviert
show_fw_status() {
    msg_info "Firewall-Status:"
    echo ""

    local fw_status
    fw_status=$(pvesh get /cluster/firewall/options 2>/dev/null | grep -i "enable" | head -1) || fw_status=""

    if [[ -z "$fw_status" ]]; then
        msg_warn "Firewall-Status konnte nicht ermittelt werden."
    elif echo "$fw_status" | grep -qi "0\|false\|no"; then
        msg_warn "⚠️  FIREWALL IST DEAKTIVIERT! Der Host ist möglicherweise ungeschützt."
    else
        msg_ok "Firewall ist aktiv."
    fi
    echo ""
}

# Zeigt Datacenter-Level Firewall-Regeln
show_datacenter_rules() {
    msg_info "Datacenter Firewall-Regeln:"
    echo ""

    local rules
    rules=$(pvesh get /cluster/firewall/rules --output-format text 2>/dev/null) || {
        msg_warn "Datacenter Firewall-Regeln konnten nicht abgerufen werden."
        echo ""
        return
    }

    if [[ -z "$rules" || "$rules" == "[]" ]]; then
        msg_info "Keine Datacenter Firewall-Regeln definiert."
    else
        echo "$rules"
    fi
    echo ""
}

# Zeigt Host-Level Firewall-Regeln
show_host_rules() {
    msg_info "Host Firewall-Regeln:"
    echo ""

    local node
    node=$(hostname 2>/dev/null) || {
        msg_warn "Hostname konnte nicht ermittelt werden."
        echo ""
        return
    }

    local rules
    rules=$(pvesh get "/nodes/${node}/firewall/rules" --output-format text 2>/dev/null) || {
        msg_warn "Host Firewall-Regeln konnten nicht abgerufen werden."
        echo ""
        return
    }

    if [[ -z "$rules" || "$rules" == "[]" ]]; then
        msg_info "Keine Host Firewall-Regeln definiert."
    else
        echo "$rules"
    fi
    echo ""
}

# Hauptfunktion: Firewall-Status und Regeln anzeigen
main() {
    msg_info "Firewall-Übersicht"
    echo "==========================================="
    echo ""

    show_fw_status
    show_datacenter_rules
    show_host_rules

    msg_ok "Firewall-Übersicht abgeschlossen."
}

main "$@"
