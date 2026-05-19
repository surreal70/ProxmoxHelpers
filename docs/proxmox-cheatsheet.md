# Proxmox VE CLI Cheat Sheet

Übersicht häufig verwendeter Proxmox-CLI-Befehle mit Kurzbeschreibung und Beispielen.

---

## Container-Verwaltung (pct)

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `pct list` | Alle Container auflisten | `pct list` |
| `pct create` | Neuen Container erstellen | `pct create 100 local:vztmpl/debian-12-standard_12.2-1_amd64.tar.zst --hostname myct --memory 512 --net0 name=eth0,bridge=vmbr0,ip=dhcp` |
| `pct start` | Container starten | `pct start 100` |
| `pct stop` | Container stoppen | `pct stop 100` |
| `pct restart` | Container neustarten | `pct restart 100` |
| `pct destroy` | Container löschen | `pct destroy 100 --purge` |
| `pct config` | Container-Konfiguration anzeigen | `pct config 100` |
| `pct set` | Container-Konfiguration ändern | `pct set 100 --memory 1024 --cores 2` |
| `pct enter` | In Container-Shell wechseln | `pct enter 100` |
| `pct console` | Container-Konsole öffnen | `pct console 100` |
| `pct resize` | Disk-Größe ändern | `pct resize 100 rootfs +10G` |
| `pct status` | Container-Status anzeigen | `pct status 100` |

### Beispiele

```bash
# Container mit 2 Cores, 2GB RAM erstellen
pct create 101 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname webserver \
  --memory 2048 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.1.101/24,gw=192.168.1.1 \
  --storage local-lvm

# Container-Ressourcen anpassen
pct set 101 --memory 4096 --cores 4

# Disk um 20GB vergrößern
pct resize 101 rootfs +20G
```

---

## VM-Verwaltung (qm)

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `qm list` | Alle VMs auflisten | `qm list` |
| `qm create` | Neue VM erstellen | `qm create 200 --name myvm --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0` |
| `qm start` | VM starten | `qm start 200` |
| `qm stop` | VM stoppen | `qm stop 200` |
| `qm restart` | VM neustarten | `qm restart 200` |
| `qm destroy` | VM löschen | `qm destroy 200 --purge` |
| `qm config` | VM-Konfiguration anzeigen | `qm config 200` |
| `qm set` | VM-Konfiguration ändern | `qm set 200 --memory 4096` |
| `qm snapshot` | Snapshot erstellen | `qm snapshot 200 snap1 --description "Vor Update"` |
| `qm rollback` | Auf Snapshot zurückrollen | `qm rollback 200 snap1` |
| `qm delsnapshot` | Snapshot löschen | `qm delsnapshot 200 snap1` |
| `qm clone` | VM klonen | `qm clone 200 201 --name clone-vm --full` |
| `qm migrate` | VM auf anderen Node migrieren | `qm migrate 200 node2 --online` |
| `qm template` | VM als Template markieren | `qm template 200` |
| `qm status` | VM-Status anzeigen | `qm status 200` |

### Beispiele

```bash
# VM mit ISO erstellen und starten
qm create 200 --name debian-server \
  --memory 4096 --cores 4 \
  --net0 virtio,bridge=vmbr0 \
  --scsi0 local-lvm:32 \
  --cdrom local:iso/debian-12.4.0-amd64-netinst.iso \
  --boot order=scsi0;ide2
qm start 200

# Snapshot vor Wartung erstellen
qm snapshot 200 pre-maintenance --description "Vor System-Update"

# Bei Problemen zurückrollen
qm rollback 200 pre-maintenance

# Live-Migration auf anderen Node
qm migrate 200 pve-node2 --online
```

---

## Storage (pvesm)

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `pvesm status` | Alle Storage-Pools mit Belegung anzeigen | `pvesm status` |
| `pvesm list` | Inhalte eines Storage auflisten | `pvesm list local` |
| `pvesm add` | Neuen Storage hinzufügen | `pvesm add nfs backup-nfs --server 192.168.1.10 --export /backup --content backup` |
| `pvesm remove` | Storage entfernen | `pvesm remove backup-nfs` |
| `pvesm scan` | Verfügbare Storages scannen | `pvesm scan nfs 192.168.1.10` |

### Beispiele

```bash
# NFS-Storage für Backups hinzufügen
pvesm add nfs backup-store \
  --server 192.168.1.50 \
  --export /mnt/backups \
  --content backup,iso

# Lokalen LVM-Thin-Pool hinzufügen
pvesm add lvmthin local-lvm2 \
  --vgname pve --thinpool data2 \
  --content rootdir,images

# Storage-Belegung prüfen
pvesm status
```

---

## Cluster (pvecm)

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `pvecm status` | Cluster-Status anzeigen | `pvecm status` |
| `pvecm nodes` | Cluster-Nodes auflisten | `pvecm nodes` |
| `pvecm create` | Neuen Cluster erstellen | `pvecm create my-cluster` |
| `pvecm add` | Node zum Cluster hinzufügen | `pvecm add 192.168.1.1` |
| `pvecm expected` | Expected Votes setzen | `pvecm expected 1` |
| `pvecm delnode` | Node aus Cluster entfernen | `pvecm delnode pve-node3` |

### Beispiele

```bash
# Neuen Cluster erstellen (auf erstem Node)
pvecm create production-cluster

# Weiteren Node hinzufügen (auf dem neuen Node ausführen)
pvecm add 192.168.1.1 --use_ssh

# Cluster-Status prüfen
pvecm status

# Bei Split-Brain: Expected Votes anpassen
pvecm expected 1
```

---

## Netzwerk

### Bridges und Interfaces

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `ip addr show` | Alle Interfaces mit IPs anzeigen | `ip addr show` |
| `ip link show` | Link-Status aller Interfaces | `ip link show` |
| `bridge link` | Bridge-Mitglieder anzeigen | `bridge link` |
| `brctl show` | Bridges anzeigen (legacy) | `brctl show` |
| `ip route show` | Routing-Tabelle anzeigen | `ip route show` |

### VLANs

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `ip link add` | VLAN-Interface erstellen | `ip link add link vmbr0 name vmbr0.100 type vlan id 100` |
| `ip link set up` | Interface aktivieren | `ip link set vmbr0.100 up` |

### Firewall

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `pvesh get /cluster/firewall/rules` | Datacenter-Firewall-Regeln | `pvesh get /cluster/firewall/rules --output-format text` |
| `pvesh get /nodes/{node}/firewall/rules` | Host-Firewall-Regeln | `pvesh get /nodes/pve/firewall/rules --output-format text` |
| `pvesh get /cluster/firewall/options` | Firewall-Optionen anzeigen | `pvesh get /cluster/firewall/options` |
| `pve-firewall status` | Firewall-Dienst-Status | `pve-firewall status` |
| `pve-firewall start` | Firewall starten | `pve-firewall start` |
| `pve-firewall stop` | Firewall stoppen | `pve-firewall stop` |

### Beispiele

```bash
# Bridge mit VLAN-Awareness erstellen (in /etc/network/interfaces)
# auto vmbr1
# iface vmbr1 inet manual
#     bridge-ports eno2
#     bridge-stp off
#     bridge-fd 0
#     bridge-vlan-aware yes
#     bridge-vids 2-4094

# Netzwerk-Konfiguration neu laden
ifreload -a
```

---

## Backup & Restore

### Backup erstellen (vzdump)

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `vzdump` | Backup einer VM/eines Containers | `vzdump 100 --storage backup-store --mode snapshot` |
| `vzdump --all` | Alle VMs/Container sichern | `vzdump --all --storage backup-store --mode snapshot --compress zstd` |
| `vzdump --pool` | Pool-basiertes Backup | `vzdump --pool production --storage backup-store` |

### Restore

| Befehl | Beschreibung | Beispiel |
|--------|-------------|---------|
| `qmrestore` | VM aus Backup wiederherstellen | `qmrestore /var/lib/vz/dump/vzdump-qemu-200-2024_01_15-12_00_00.vma.zst 200` |
| `pct restore` | Container aus Backup wiederherstellen | `pct restore 100 /var/lib/vz/dump/vzdump-lxc-100-2024_01_15-12_00_00.tar.zst` |

### Backup-Modi

| Modus | Beschreibung |
|-------|-------------|
| `snapshot` | Live-Backup ohne Downtime (empfohlen) |
| `suspend` | VM/Container wird kurz pausiert |
| `stop` | VM/Container wird gestoppt (konsistentestes Backup) |

### Zeitpläne (cron-basiert)

```bash
# Tägliches Backup aller VMs um 02:00 Uhr
# In /etc/cron.d/vzdump oder über GUI: Datacenter → Backup
vzdump --all --storage backup-store --mode snapshot --compress zstd --mailto admin@example.com

# Backup-Jobs über pvesh verwalten
pvesh get /cluster/backup
pvesh create /cluster/backup --vmid 100,200 --storage backup-store --schedule "0 2 * * *" --mode snapshot
```

### Beispiele

```bash
# Snapshot-Backup einer VM mit zstd-Kompression
vzdump 200 --storage backup-store --mode snapshot --compress zstd

# Container wiederherstellen mit neuer ID
pct restore 105 /var/lib/vz/dump/vzdump-lxc-100-2024_01_15-12_00_00.tar.zst \
  --storage local-lvm

# VM wiederherstellen auf anderem Storage
qmrestore /var/lib/vz/dump/vzdump-qemu-200-2024_01_15-12_00_00.vma.zst 210 \
  --storage local-lvm
```
