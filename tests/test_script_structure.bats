#!/usr/bin/env bats
# =============================================================================
# test_script_structure.bats - Property-Tests für Script-Struktur-Compliance
# =============================================================================
# Feature: proxmox-helper-scripts, Property 6: Script structure compliance
# Feature: proxmox-helper-scripts, Property 7: ShellCheck compliance
# Feature: proxmox-helper-scripts, Property 8: Function documentation
#
# Validates: Requirements 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7
# =============================================================================

load 'test_helper'

# -----------------------------------------------------------------------------
# Property 6: Script structure compliance
# For any script in the collection, it should contain:
# (a) #!/bin/bash as the first line
# (b) set -euo pipefail within the first 10 lines
# (c) a header comment block with description
# (d) a root permission check before any operational logic
# -----------------------------------------------------------------------------

@test "Property 6: All scripts have #!/bin/bash as first line" {
    while IFS= read -r script; do
        local first_line
        first_line=$(head -n 1 "$script")
        [ "$first_line" = "#!/bin/bash" ] || {
            echo "FAIL: $script - first line is: $first_line"
            return 1
        }
    done < <(get_all_scripts)
}

@test "Property 6: All scripts have 'set -euo pipefail' within first 15 lines" {
    while IFS= read -r script; do
        local found
        found=$(head -n 15 "$script" | grep -c "set -euo pipefail" || true)
        [ "$found" -ge 1 ] || {
            echo "FAIL: $script - 'set -euo pipefail' not found in first 15 lines"
            return 1
        }
    done < <(get_all_scripts)
}

@test "Property 6: All scripts have a header comment with description" {
    while IFS= read -r script; do
        local has_description
        has_description=$(head -n 15 "$script" | grep -ci "beschreibung\|description" || true)
        [ "$has_description" -ge 1 ] || {
            echo "FAIL: $script - no description header found"
            return 1
        }
    done < <(get_all_scripts)
}

@test "Property 6: All scripts check for root permission" {
    while IFS= read -r script; do
        local has_root_check
        has_root_check=$(grep -c "check_root" "$script" || true)
        [ "$has_root_check" -ge 1 ] || {
            echo "FAIL: $script - no root check (check_root) found"
            return 1
        }
    done < <(get_all_scripts)
}

# -----------------------------------------------------------------------------
# Property 7: ShellCheck compliance
# For any script in the collection, running shellcheck should produce zero
# errors (exit code 0).
# -----------------------------------------------------------------------------

@test "Property 7: All scripts pass shellcheck without errors" {
    command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed"

    while IFS= read -r script; do
        run shellcheck -S error "$script"
        [ "$status" -eq 0 ] || {
            echo "FAIL: $script - shellcheck errors:"
            echo "$output"
            return 1
        }
    done < <(get_all_scripts)
}

@test "Property 7: common.sh passes shellcheck without errors" {
    command -v shellcheck >/dev/null 2>&1 || skip "shellcheck not installed"

    run shellcheck -S error "${LIB_DIR}/common.sh"
    [ "$status" -eq 0 ] || {
        echo "FAIL: lib/common.sh - shellcheck errors:"
        echo "$output"
        return 1
    }
}

# -----------------------------------------------------------------------------
# Property 8: Function documentation
# For any function definition in any script, there should be a comment on the
# line(s) immediately preceding the function declaration.
# -----------------------------------------------------------------------------

@test "Property 8: All functions in scripts have preceding documentation comments" {
    while IFS= read -r script; do
        local line_num=0
        local prev_line=""
        local prev_prev_line=""

        while IFS= read -r line; do
            line_num=$((line_num + 1))

            # Match function definitions: name() { or function name {
            if echo "$line" | grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{' || \
               echo "$line" | grep -qE '^\s*function\s+[a-zA-Z_]'; then
                # Check if previous non-empty line is a comment
                if ! echo "$prev_line" | grep -qE '^\s*#' && \
                   ! echo "$prev_prev_line" | grep -qE '^\s*#'; then
                    echo "FAIL: $script line $line_num - function has no preceding comment: $line"
                    return 1
                fi
            fi

            if [ -n "$line" ]; then
                prev_prev_line="$prev_line"
                prev_line="$line"
            fi
        done < "$script"
    done < <(get_all_scripts)
}

@test "Property 8: All functions in common.sh have preceding documentation comments" {
    local script="${LIB_DIR}/common.sh"
    local line_num=0
    local prev_line=""
    local prev_prev_line=""

    while IFS= read -r line; do
        line_num=$((line_num + 1))

        if echo "$line" | grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)\s*\{' || \
           echo "$line" | grep -qE '^\s*function\s+[a-zA-Z_]'; then
            if ! echo "$prev_line" | grep -qE '^\s*#' && \
               ! echo "$prev_prev_line" | grep -qE '^\s*#'; then
                echo "FAIL: lib/common.sh line $line_num - function has no preceding comment: $line"
                return 1
            fi
        fi

        if [ -n "$line" ]; then
            prev_prev_line="$prev_line"
            prev_line="$line"
        fi
    done < "$script"
}
