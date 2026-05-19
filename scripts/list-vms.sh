#!/bin/bash
# =============================================================================
# list-vms.sh - Alle VMs mit Details auflisten
# =============================================================================
# Beschreibung: Zeigt alle virtuellen Maschinen auf dem Proxmox VE Host mit
#               VMID, Name, Status, CPU und RAM in tabellarischer Formatierung.
# Nutzung:      ./scripts/list-vms.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root

# Liest alle VMs und gibt sie als "VMID|NAME|STATUS|CPUS|MEM" aus
get_all_vms() {
    local output
    output=$(qm list 2>/dev/null) || {
        msg_error "Fehler beim Abrufen der VM-Liste."
        exit 1
    }

    # Erste Zeile (Header) überspringen, leere Zeilen ignorieren
    echo "$output" | tail -n +2 | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local vmid name status mem cpus
        vmid=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{print $2}')
        status=$(echo "$line" | awk '{print $3}')
        mem=$(echo "$line" | awk '{print $4}')
        # pid is field 5 in qm list, cpus from config
        cpus=$(qm config "$vmid" 2>/dev/null | grep -E "^cores:" | awk '{print $2}') || cpus="-"

        [[ -z "$cpus" ]] && cpus="-"
        [[ -z "$mem" ]] && mem="-"

        echo "${vmid}|${name}|${status}|${cpus}|${mem}MB"
    done
}

# Formatiert die VM-Daten als ausgerichtete Tabelle
format_table() {
    local data="$1"

    printf "${BLUE}%-8s %-20s %-10s %-6s %-10s${NC}\n" "VMID" "NAME" "STATUS" "CPU" "RAM"
    printf "%-8s %-20s %-10s %-6s %-10s\n" "--------" "--------------------" "----------" "------" "----------"

    while IFS='|' read -r vmid name status cpus mem; do
        [[ -z "$vmid" ]] && continue
        printf "%-8s %-20s %-10s %-6s %-10s\n" "$vmid" "$name" "$status" "$cpus" "$mem"
    done <<< "$data"
}

# Hauptfunktion: VMs auflisten und formatiert ausgeben
main() {
    msg_info "Virtuelle Maschinen auf diesem Host:"
    echo ""

    local vm_data
    vm_data=$(get_all_vms)

    if [[ -z "$vm_data" ]]; then
        msg_info "Keine VMs auf diesem Host vorhanden."
        exit 0
    fi

    format_table "$vm_data"
}

main "$@"
