#!/bin/bash
# =============================================================================
# make-ubuntu-clone-unique.sh
# Beschreibung: Macht eine geklonte Ubuntu-Maschine einzigartig (Hostname,
#               Machine-ID, SSH-Keys, DHCP-Leases, Cloud-Init, Logs).
# Nutzung:      sudo ./scripts/make-ubuntu-clone-unique.sh <neuer-hostname>
# =============================================================================

set -euo pipefail

# Gemeinsame Bibliothek laden
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Root-Berechtigung prüfen
check_root

NEW_HOSTNAME="${1:-}"

if [[ -z "$NEW_HOSTNAME" ]]; then
  msg_error "Kein Hostname angegeben."
  echo "Nutzung: sudo $0 <neuer-hostname>"
  exit 1
fi

# Hostname setzen und /etc/hosts aktualisieren
set_hostname() {
  msg_info "[1/8] Hostname setzen: $NEW_HOSTNAME"
  hostnamectl set-hostname "$NEW_HOSTNAME"

  if [[ -f /etc/hosts ]]; then
    sed -i "s/^\(127\.0\.1\.1\s*\).*/\1$NEW_HOSTNAME/" /etc/hosts || true
    if ! grep -q "^127.0.1.1" /etc/hosts; then
      echo "127.0.1.1 $NEW_HOSTNAME" >> /etc/hosts
    fi
  fi
}

# Machine-ID neu generieren für Eindeutigkeit
regenerate_machine_id() {
  msg_info "[2/8] Machine-ID neu generieren"
  rm -f /etc/machine-id
  rm -f /var/lib/dbus/machine-id
  systemd-machine-id-setup
  ln -sf /etc/machine-id /var/lib/dbus/machine-id
}

# SSH Host-Keys neu generieren
regenerate_ssh_keys() {
  msg_info "[3/8] SSH Host-Keys neu generieren"
  rm -f /etc/ssh/ssh_host_*
  dpkg-reconfigure openssh-server >/dev/null 2>&1 || ssh-keygen -A
}

# Cloud-Init Zustand zurücksetzen (falls installiert)
reset_cloud_init() {
  msg_info "[4/8] Cloud-Init zurücksetzen (falls vorhanden)"
  if command -v cloud-init >/dev/null 2>&1; then
    cloud-init clean --logs
  fi
}

# DHCP-Leases entfernen
remove_dhcp_leases() {
  msg_info "[5/8] DHCP-Leases entfernen"
  rm -f /var/lib/dhcp/* || true
  rm -f /var/lib/NetworkManager/*.lease || true
  rm -f /var/lib/NetworkManager/*.leases || true
}

# Temporäre Dateien bereinigen
clean_temp_files() {
  msg_info "[6/8] Temporäre Dateien bereinigen"
  rm -rf /tmp/*
  rm -rf /var/tmp/*
}

# Logs bereinigen
clean_logs() {
  msg_info "[7/8] Logs bereinigen"
  find /var/log -type f -exec truncate -s 0 {} \; || true
  journalctl --rotate >/dev/null 2>&1 || true
  journalctl --vacuum-time=1s >/dev/null 2>&1 || true
}

# Shell-History löschen
clear_history() {
  msg_info "[8/8] Shell-History löschen"
  rm -f /root/.bash_history
  history -c || true
}

# Hauptlogik: Alle Schritte ausführen
main() {
  set_hostname
  regenerate_machine_id
  regenerate_ssh_keys
  reset_cloud_init
  remove_dhcp_leases
  clean_temp_files
  clean_logs
  clear_history

  echo
  msg_ok "Fertig. Neustart empfohlen:"
  echo "  sudo reboot"
}

main
