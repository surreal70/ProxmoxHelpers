#!/bin/bash
# =============================================================================
# test_helper.bash - Gemeinsame Setup-Logik für bats-core Tests
# =============================================================================
# Beschreibung: Stellt Hilfsfunktionen und Variablen bereit, die von allen
#               Testdateien verwendet werden.
# Nutzung:      load 'test_helper' (in .bats Dateien)
# =============================================================================

# Projektverzeichnis (Root des Repositories)
PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"

# Verzeichnisse
SCRIPTS_DIR="${PROJECT_ROOT}/scripts"
LIB_DIR="${PROJECT_ROOT}/lib"
README_FILE="${PROJECT_ROOT}/README.md"

# Alle Skripte im scripts/ Verzeichnis sammeln (ohne .gitkeep)
get_all_scripts() {
    find "${SCRIPTS_DIR}" -name "*.sh" -type f | sort
}

# Anzahl der Skripte zurückgeben
count_scripts() {
    get_all_scripts | wc -l
}
