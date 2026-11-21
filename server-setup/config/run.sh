#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/scripts/functions.sh"


# Scan and import all scripts from the templates directory
scripts=()
for script in "$SCRIPT_DIR"/templates/*.sh; do
    [ -f "$script" ] && source "$script" # import script
    name="${script##*/}"                 # strip directory part
    name="${name%.script.sh}"            # strip script extension
    scripts+=("$name")
done


select_container_to_manage() {
    printf '%s\n' "Select container you want to manage:"
    for i in "${!scripts[@]}"; do
        printf '%d: %s\n' "$i" "${scripts[$i]}"
    done

    read -r -p "Enter the number of the container you want to manage: " selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 0 || selection >= ${#scripts[@]} )); then
        fail 'Invalid selection.'
    fi
    selected_script="${scripts[$selection]}"
    printf 'You selected: %s\n' "$selected_script"
}

select_container_operation() {
    printf '%s\n' "Select operation for container '$selected_script':"
    operations=("start" "stop" "restart" "create" "update" "remove")
    for i in "${!operations[@]}"; do
        printf '%d: %s\n' "$i" "${operations[$i]}"
    done

    read -r -p "Enter the number of the operation you want to perform: " op_selection
    if ! [[ "$op_selection" =~ ^[0-9]+$ ]] || (( op_selection < 0 || op_selection >= ${#operations[@]} )); then
        fail 'Invalid selection.'
    fi
    selected_operation="${operations[$op_selection]}"
    printf 'You selected operation: %s\n' "$selected_operation"
}


select_container_to_manage
select_container_operation

