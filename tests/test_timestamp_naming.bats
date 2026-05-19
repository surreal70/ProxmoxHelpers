#!/usr/bin/env bats
# =============================================================================
# test_timestamp_naming.bats - Property-Test: Timestamp-Namenskonvention
# =============================================================================
# Feature: proxmox-helper-scripts, Property 5: Timestamp-based naming follows format
#
# For any point in time, generated names (backup archives and snapshot names)
# should follow their respective format patterns:
# - Backup: pve-backup-YYYY-MM-DD_HHMMSS
# - Snapshot: pre-maintenance-YYYYMMDD-HHMMSS
#
# Validates: Requirements 8.3, 11.3
# =============================================================================

load 'test_helper'

# -----------------------------------------------------------------------------
# Property 5: Timestamp-based naming follows format
# -----------------------------------------------------------------------------

@test "Property 5: backup-configs.sh uses pve-backup-YYYY-MM-DD_HHMMSS format" {
    local script="${SCRIPTS_DIR}/backup-configs.sh"
    [ -f "$script" ] || {
        echo "FAIL: backup-configs.sh not found"
        return 1
    }

    # Verify the date format string in the script matches the expected pattern
    local format_found
    format_found=$(grep -c 'pve-backup-$(date +%Y-%m-%d_%H%M%S)' "$script" || true)
    [ "$format_found" -ge 1 ] || {
        echo "FAIL: backup-configs.sh does not use 'pve-backup-\$(date +%Y-%m-%d_%H%M%S)' format"
        return 1
    }
}

@test "Property 5: snapshot-vm.sh uses pre-maintenance-YYYYMMDD-HHMMSS format" {
    local script="${SCRIPTS_DIR}/snapshot-vm.sh"
    [ -f "$script" ] || {
        echo "FAIL: snapshot-vm.sh not found"
        return 1
    }

    # Verify the date format string in the script matches the expected pattern
    local format_found
    format_found=$(grep -c 'pre-maintenance-$(date +%Y%m%d-%H%M%S)' "$script" || true)
    [ "$format_found" -ge 1 ] || {
        echo "FAIL: snapshot-vm.sh does not use 'pre-maintenance-\$(date +%Y%m%d-%H%M%S)' format"
        return 1
    }
}

@test "Property 5: Backup timestamp generates valid parseable date" {
    # Simulate the date format used in backup-configs.sh
    local generated
    generated="pve-backup-$(date +%Y-%m-%d_%H%M%S)"

    # Verify it matches the expected regex pattern
    echo "$generated" | grep -qE '^pve-backup-[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{6}$' || {
        echo "FAIL: Generated backup name '$generated' does not match pattern"
        return 1
    }

    # Extract and validate the date portion is parseable
    local date_part
    date_part=$(echo "$generated" | sed 's/pve-backup-//' | sed 's/_[0-9]\{6\}$//')
    date -d "$date_part" +%Y-%m-%d >/dev/null 2>&1 || {
        echo "FAIL: Date portion '$date_part' is not a valid date"
        return 1
    }
}

@test "Property 5: Snapshot timestamp generates valid parseable date" {
    # Simulate the date format used in snapshot-vm.sh
    local generated
    generated="pre-maintenance-$(date +%Y%m%d-%H%M%S)"

    # Verify it matches the expected regex pattern
    echo "$generated" | grep -qE '^pre-maintenance-[0-9]{8}-[0-9]{6}$' || {
        echo "FAIL: Generated snapshot name '$generated' does not match pattern"
        return 1
    }

    # Extract and validate the date portion is parseable
    local date_part
    date_part=$(echo "$generated" | sed 's/pre-maintenance-//' | sed 's/-[0-9]\{6\}$//')
    date -d "$date_part" +%Y%m%d >/dev/null 2>&1 || {
        echo "FAIL: Date portion '$date_part' is not a valid date"
        return 1
    }
}
