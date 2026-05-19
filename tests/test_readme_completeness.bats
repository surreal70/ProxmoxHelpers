#!/usr/bin/env bats
# =============================================================================
# test_readme_completeness.bats - Property-Test: README-Vollständigkeit
# =============================================================================
# Feature: proxmox-helper-scripts, Property 1: README documents all scripts
#
# For any script file present in the scripts/ directory, the README.md should
# contain both a mention of that script's filename and a usage example for it.
#
# Validates: Requirements 1.2, 1.4
# =============================================================================

load 'test_helper'

# -----------------------------------------------------------------------------
# Property 1: README documents all scripts
# -----------------------------------------------------------------------------

@test "Property 1: README mentions all script filenames" {
    [ -f "$README_FILE" ] || {
        echo "FAIL: README.md not found"
        return 1
    }

    while IFS= read -r script; do
        local basename
        basename=$(basename "$script")
        local found
        found=$(grep -c "$basename" "$README_FILE" || true)
        [ "$found" -ge 1 ] || {
            echo "FAIL: Script '$basename' not mentioned in README.md"
            return 1
        }
    done < <(get_all_scripts)
}

@test "Property 1: README contains usage examples for all scripts" {
    [ -f "$README_FILE" ] || {
        echo "FAIL: README.md not found"
        return 1
    }

    while IFS= read -r script; do
        local basename
        basename=$(basename "$script")
        # Check for usage example pattern: ./scripts/scriptname or scripts/scriptname
        local found
        found=$(grep -cE "(\.\/scripts\/${basename}|scripts\/${basename})" "$README_FILE" || true)
        [ "$found" -ge 1 ] || {
            echo "FAIL: No usage example found for '$basename' in README.md"
            return 1
        }
    done < <(get_all_scripts)
}
