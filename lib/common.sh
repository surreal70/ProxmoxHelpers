#!/bin/bash
# =============================================================================
# common.sh - Gemeinsame Bibliothek für Proxmox Helper Scripts
# =============================================================================
# Beschreibung: Stellt gemeinsame Funktionen bereit, die von allen Proxmox
#               Helper Scripts verwendet werden: Farbausgabe, Fehlerbehandlung,
#               Root-Prüfung, Kommando-Prüfung und interaktive Auswahl.
# Nutzung:      source "$(dirname "$0")/../lib/common.sh"
# =============================================================================

set -euo pipefail

# -----------------------------------------------------------------------------
# Farbdefinitionen für Terminal-Ausgabe
# -----------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Ausgabefunktionen
# -----------------------------------------------------------------------------

# Gibt eine Info-Meldung in Blau aus
msg_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} ${message}"
}

# Gibt eine Erfolgsmeldung in Grün aus
msg_ok() {
    local message="$1"
    echo -e "${GREEN}[OK]${NC} ${message}"
}

# Gibt eine Warnung in Gelb aus
msg_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} ${message}" >&2
}

# Gibt eine Fehlermeldung in Rot aus (auf stderr)
msg_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} ${message}" >&2
}

# -----------------------------------------------------------------------------
# Prüfungen
# -----------------------------------------------------------------------------

# Prüft ob das Skript mit Root-Berechtigung ausgeführt wird.
# Beendet mit Exit-Code 1 falls nicht root.
check_root() {
    if [[ $EUID -ne 0 ]]; then
        msg_error "Dieses Skript muss als Root ausgeführt werden."
        exit 1
    fi
}

# Prüft ob ein benötigtes Kommando verfügbar ist.
# Parameter: cmd - Name des zu prüfenden Kommandos
# Beendet mit Exit-Code 1 falls Kommando nicht gefunden.
check_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        msg_error "Benötigtes Kommando nicht gefunden: ${cmd}"
        exit 1
    fi
}

# -----------------------------------------------------------------------------
# Interaktionsfunktionen
# -----------------------------------------------------------------------------

# Fragt den Benutzer um Bestätigung (Ja/Nein).
# Parameter: prompt - Die anzuzeigende Frage
# Rückgabe: 0 bei Ja, 1 bei Nein
confirm() {
    local prompt="$1"
    local answer

    while true; do
        echo -en "${YELLOW}${prompt} [j/N]:${NC} "
        read -r answer
        case "${answer,,}" in
            j|ja|y|yes)
                return 0
                ;;
            n|nein|no|"")
                return 1
                ;;
            *)
                msg_warn "Bitte mit 'j' oder 'n' antworten."
                ;;
        esac
    done
}

# Zeigt eine nummerierte Liste an und lässt den Benutzer auswählen.
# Parameter: prompt - Überschrift/Aufforderung für die Auswahl
# Stdin: Zeilenweise Einträge (ein Eintrag pro Zeile)
# Ausgabe: Der ausgewählte Eintrag auf stdout
# Rückgabe: 0 bei erfolgreicher Auswahl, 1 bei Abbruch oder leerer Liste
select_from_list() {
    local prompt="$1"
    local -a items=()
    local choice

    # Einträge aus stdin lesen
    while IFS= read -r line; do
        [[ -n "$line" ]] && items+=("$line")
    done

    if [[ ${#items[@]} -eq 0 ]]; then
        msg_warn "Keine Einträge zur Auswahl vorhanden."
        return 1
    fi

    echo -e "\n${BLUE}${prompt}${NC}"
    echo "-------------------------------------------"
    for i in "${!items[@]}"; do
        printf "  %3d) %s\n" "$((i + 1))" "${items[$i]}"
    done
    echo "-------------------------------------------"

    while true; do
        echo -en "Auswahl [1-${#items[@]}] (0 = Abbruch): "
        read -r choice

        if [[ "$choice" == "0" ]]; then
            msg_info "Abgebrochen."
            return 1
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#items[@]} )); then
            echo "${items[$((choice - 1))]}"
            return 0
        fi

        msg_warn "Ungültige Auswahl. Bitte eine Zahl zwischen 1 und ${#items[@]} eingeben."
    done
}
