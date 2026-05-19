#!/bin/bash
# =============================================================================
# restart-vm.sh - VM sicher neustarten
# =============================================================================
# Beschreibung: Startet eine virtuelle Maschine kontrolliert neu (Graceful Stop
#               + Start). Unterstützt Argument-Mode (VMID als Parameter) und
#               Interactive Mode (Auswahl aus laufenden VMs).
# Nutzung:      ./scripts/restart-vm.sh [VMID]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root
check_command qm

# Listet alle laufenden VMs als "VMID NAME" auf
get_running_vms() {
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

        if [[ "$status" == "running" ]]; then
            echo "${vmid} ${name}"
        fi
    done
}

# Startet eine VM neu (Graceful Stop + Start)
# Parameter: vmid - Die VM-ID
restart_vm() {
    local vmid="$1"

    # Existenz prüfen
    if ! qm status "$vmid" &>/dev/null; then
        msg_error "VM mit VMID ${vmid} existiert nicht."
        exit 1
    fi

    local current_status
    current_status=$(qm status "$vmid" 2>/dev/null | awk '{print $2}')

    # Bereits gestoppt? Direkt starten.
    if [[ "$current_status" == "stopped" ]]; then
        msg_info "VM ${vmid} ist bereits gestoppt. Starte direkt..."
        if ! qm start "$vmid" 2>/dev/null; then
            msg_error "Fehler beim Starten von VM ${vmid}."
            exit 1
        fi
        msg_ok "VM ${vmid} erfolgreich gestartet."
        return 0
    fi

    # Graceful Stop
    msg_info "Stoppe VM ${vmid}..."
    if ! qm stop "$vmid" 2>/dev/null; then
        msg_error "Fehler beim Stoppen von VM ${vmid}."
        exit 1
    fi
    msg_ok "VM ${vmid} gestoppt."

    # Start
    msg_info "Starte VM ${vmid}..."
    if ! qm start "$vmid" 2>/dev/null; then
        msg_error "Fehler beim Starten von VM ${vmid}. Aktueller Status: $(qm status "$vmid" 2>/dev/null | awk '{print $2}')"
        exit 1
    fi
    msg_ok "VM ${vmid} erfolgreich neugestartet."
}

# Hauptfunktion: Argument-Parsing oder Interactive Mode
main() {
    if [[ $# -ge 1 ]]; then
        local vmid="$1"
        restart_vm "$vmid"
    else
        local running
        running=$(get_running_vms)

        if [[ -z "$running" ]]; then
            msg_info "Keine laufenden VMs vorhanden."
            exit 0
        fi

        local selection
        selection=$(echo "$running" | select_from_list "Laufende VMs auswählen:") || exit 0
        local vmid
        vmid=$(echo "$selection" | awk '{print $1}')
        restart_vm "$vmid"
    fi
}

main "$@"
