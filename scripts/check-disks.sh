#!/bin/bash
# =============================================================================
# check-disks.sh - Festplatten-, SMART- und Storage-Informationen anzeigen
# =============================================================================
# Beschreibung: Zeigt eine Übersicht aller Festplatten mit Größe und Typ,
#               SMART-Gesundheitsstatus und Proxmox Storage-Pools mit Belegung.
# Nutzung:      ./scripts/check-disks.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root

# Zeigt alle erkannten Block-Devices mit Größe und Typ
show_block_devices() {
    msg_info "Block-Devices:"
    echo ""
    lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null || {
        msg_warn "lsblk konnte nicht ausgeführt werden."
    }
    echo ""
}

# Zeigt SMART-Gesundheitsstatus für jede physische Festplatte
show_smart_status() {
    msg_info "SMART-Gesundheitsstatus:"
    echo ""

    if ! command -v smartctl &>/dev/null; then
        msg_warn "smartctl nicht verfügbar. Installieren Sie smartmontools für SMART-Daten."
        echo ""
        return
    fi

    local disks
    disks=$(lsblk -dnpo NAME,TYPE 2>/dev/null | awk '$2=="disk" {print $1}')

    if [[ -z "$disks" ]]; then
        msg_warn "Keine physischen Festplatten erkannt."
        echo ""
        return
    fi

    while IFS= read -r disk; do
        [[ -z "$disk" ]] && continue
        printf "  %-15s " "$disk"
        local health
        health=$(smartctl -H "$disk" 2>/dev/null | grep -i "overall-health\|SMART Health Status" | awk -F: '{print $2}' | xargs) || health=""
        if [[ -n "$health" ]]; then
            echo "$health"
        else
            echo -e "${YELLOW}SMART-Daten nicht verfügbar${NC}"
        fi
    done <<< "$disks"
    echo ""
}

# Zeigt Proxmox Storage-Pools mit Belegung
show_storage_pools() {
    msg_info "Proxmox Storage-Pools:"
    echo ""

    local output
    output=$(pvesm status 2>/dev/null) || {
        msg_warn "pvesm status konnte nicht ausgeführt werden."
        echo ""
        return
    }

    echo "$output"
    echo ""
}

# Hauptfunktion: Alle Festplatten-Informationen anzeigen
main() {
    msg_info "Festplatten- und Storage-Übersicht"
    echo "==========================================="
    echo ""

    show_block_devices
    show_smart_status
    show_storage_pools

    msg_ok "Festplatten-Übersicht abgeschlossen."
}

main "$@"
