#!/bin/bash
# =============================================================================
# snapshot-vm.sh - VM-Snapshot vor Wartungsarbeiten erstellen
# =============================================================================
# Beschreibung: Erstellt einen Snapshot einer VM mit automatischem Zeitstempel-
#               Namen. Unterstützt Argument-Mode (VMID als Parameter) und
#               Interactive Mode (Auswahl aus allen VMs).
# Nutzung:      ./scripts/snapshot-vm.sh [VMID]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root
check_command qm

# Listet alle VMs als "VMID NAME STATUS" auf
get_all_vms() {
    local output
    output=$(qm list 2>/dev/null) || {
        msg_error "Fehler beim Abrufen der VM-Liste."
        exit 1
    }

    echo "$output" | tail -n +2 | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local vmid name status
        vmid=$(echo "$line" | awk '{print $1}')
        name=$(echo "$line" | awk '{print $2}')
        status=$(echo "$line" | awk '{print $3}')
        echo "${vmid} ${name} (${status})"
    done
}

# Erstellt einen Snapshot mit Zeitstempel-basiertem Namen
# Parameter: vmid - Die VM-ID
create_snapshot() {
    local vmid="$1"

    # Existenz prüfen
    if ! qm status "$vmid" &>/dev/null; then
        msg_error "VM mit VMID ${vmid} existiert nicht."
        exit 1
    fi

    local snap_name
    snap_name="pre-maintenance-$(date +%Y%m%d-%H%M%S)"

    msg_info "Erstelle Snapshot '${snap_name}' für VM ${vmid}..."
    if ! qm snapshot "$vmid" "$snap_name" --description "Automatischer Pre-Maintenance Snapshot" 2>/dev/null; then
        msg_error "Fehler beim Erstellen des Snapshots für VM ${vmid}."
        exit 1
    fi

    msg_ok "Snapshot '${snap_name}' für VM ${vmid} erfolgreich erstellt."
}

# Hauptfunktion: Argument-Parsing oder Interactive Mode
main() {
    if [[ $# -ge 1 ]]; then
        local vmid="$1"
        create_snapshot "$vmid"
    else
        local vms
        vms=$(get_all_vms)

        if [[ -z "$vms" ]]; then
            msg_info "Keine VMs auf diesem Host vorhanden."
            exit 0
        fi

        local selection
        selection=$(echo "$vms" | select_from_list "VM für Snapshot auswählen:") || exit 0
        local vmid
        vmid=$(echo "$selection" | awk '{print $1}')
        create_snapshot "$vmid"
    fi
}

main "$@"
