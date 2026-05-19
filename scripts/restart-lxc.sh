#!/bin/bash
# =============================================================================
# restart-lxc.sh - LXC-Container sicher neustarten
# =============================================================================
# Beschreibung: Startet einen LXC-Container kontrolliert neu (Graceful Stop +
#               Start). Unterstützt Argument-Mode (CTID als Parameter) und
#               Interactive Mode (Auswahl aus laufenden Containern).
# Nutzung:      ./scripts/restart-lxc.sh [CTID]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/common.sh"

check_root
check_command pct

# Listet alle laufenden Container als "CTID HOSTNAME" auf
get_running_containers() {
    local output
    output=$(pct list 2>/dev/null) || {
        msg_error "Fehler beim Abrufen der Container-Liste."
        exit 1
    }

    echo "$output" | tail -n +2 | while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local ctid status hostname
        ctid=$(echo "$line" | awk '{print $1}')
        status=$(echo "$line" | awk '{print $2}')
        hostname=$(echo "$line" | awk '{print $3}')

        if [[ "$status" == "running" ]]; then
            echo "${ctid} ${hostname}"
        fi
    done
}

# Startet einen Container neu (Graceful Stop + Start)
# Parameter: ctid - Die Container-ID
restart_container() {
    local ctid="$1"

    # Existenz prüfen
    if ! pct status "$ctid" &>/dev/null; then
        msg_error "Container mit CTID ${ctid} existiert nicht."
        exit 1
    fi

    local current_status
    current_status=$(pct status "$ctid" 2>/dev/null | awk '{print $2}')

    # Bereits gestoppt? Direkt starten.
    if [[ "$current_status" == "stopped" ]]; then
        msg_info "Container ${ctid} ist bereits gestoppt. Starte direkt..."
        if ! pct start "$ctid" 2>/dev/null; then
            msg_error "Fehler beim Starten von Container ${ctid}."
            exit 1
        fi
        msg_ok "Container ${ctid} erfolgreich gestartet."
        return 0
    fi

    # Graceful Stop
    msg_info "Stoppe Container ${ctid}..."
    if ! pct stop "$ctid" 2>/dev/null; then
        msg_error "Fehler beim Stoppen von Container ${ctid}."
        exit 1
    fi
    msg_ok "Container ${ctid} gestoppt."

    # Start
    msg_info "Starte Container ${ctid}..."
    if ! pct start "$ctid" 2>/dev/null; then
        msg_error "Fehler beim Starten von Container ${ctid}. Aktueller Status: $(pct status "$ctid" 2>/dev/null | awk '{print $2}')"
        exit 1
    fi
    msg_ok "Container ${ctid} erfolgreich neugestartet."
}

# Hauptfunktion: Argument-Parsing oder Interactive Mode
main() {
    if [[ $# -ge 1 ]]; then
        # Argument-Mode: CTID direkt übergeben
        local ctid="$1"
        restart_container "$ctid"
    else
        # Interactive Mode: Auswahl aus laufenden Containern
        local running
        running=$(get_running_containers)

        if [[ -z "$running" ]]; then
            msg_info "Keine laufenden LXC-Container vorhanden."
            exit 0
        fi

        local selection
        selection=$(echo "$running" | select_from_list "Laufende LXC-Container auswählen:") || exit 0
        local ctid
        ctid=$(echo "$selection" | awk '{print $1}')
        restart_container "$ctid"
    fi
}

main "$@"
