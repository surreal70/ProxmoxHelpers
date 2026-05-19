#!/bin/bash
# =============================================================================
# list-lxcs.sh - Alle LXC-Container mit Details auflisten
# =============================================================================
# Beschreibung: Zeigt alle LXC-Container auf dem Proxmox VE Host mit CTID,
#               Hostname, Status und zugewiesenen Ressourcen in tabellarischer
#               Formatierung an.
# Nutzung:      ./scripts/list-lxcs.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root

# Liest alle Container und gibt sie als "CTID|HOSTNAME|STATUS|MEM|DISK" aus
get_all_containers() {
    local output
    output=$(pct list 2>/dev/null) || {
        msg_error "Fehler beim Abrufen der Container-Liste."
        exit 1
    }

    # Erste Zeile (Header) überspringen, leere Zeilen ignorieren
    echo "$output" | tail -n +2 | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ctid status hostname
        ctid=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $2}')
        hostname=$(echo "$line" | awk '{print $3}')

        # Ressourcen aus Konfiguration lesen
        local mem disk
        mem=$(pct config "$ctid" 2>/dev/null | grep -E "^memory:" | awk '{print $2}') || mem="-"
        disk=$(pct config "$ctid" 2>/dev/null | grep -E "^rootfs:" | sed -n 's/.*size=\([^,]*\).*/\1/p') || disk="-"

        [[ -z "$mem" ]] && mem="-"
        [[ -z "$disk" ]] && disk="-"

        echo "${ctid}|${hostname}|${status}|${mem}MB|${disk}"
    done
}

# Formatiert die Container-Daten als ausgerichtete Tabelle
format_table() {
    local data="$1"

    printf "${BLUE}%-8s %-20s %-10s %-10s %-10s${NC}\n" "CTID" "HOSTNAME" "STATUS" "RAM" "DISK"
    printf "%-8s %-20s %-10s %-10s %-10s\n" "--------" "--------------------" "----------" "----------" "----------"

    while IFS='|' read -r ctid hostname status mem disk; do
        [[ -z "$ctid" ]] && continue
        printf "%-8s %-20s %-10s %-10s %-10s\n" "$ctid" "$hostname" "$status" "$mem" "$disk"
    done <<< "$data"
}

# Hauptfunktion: Container auflisten und formatiert ausgeben
main() {
    msg_info "LXC-Container auf diesem Host:"
    echo ""

    local container_data
    container_data=$(get_all_containers)

    if [[ -z "$container_data" ]]; then
        msg_info "Keine LXC-Container auf diesem Host vorhanden."
        exit 0
    fi

    format_table "$container_data"
}

main "$@"
