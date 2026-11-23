#!/usr/bin/env bash
. "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/functions.sh"

get_begin_section_line(){
    printf '# [BEGIN] %s\n' "$1"
}

get_end_section_line(){
    printf '# [END] %s\n' "$1"
}

write_to_env_file() {
    local file="$1"
    shift
    {
        printf '\n' || return 1
        printf '%s\n' "$@"
    } >> "$file"
}

process_general_env_file() {
    local env_file="$1"
    local container_name="$2"
    local line key default value escaped
    local -a env_lines=()
    
    # Add opening section marker
    env_lines+=("$(get_begin_section_line "$container_name")")
    
    while IFS= read -r -u 3 line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_]*)=(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            default="${BASH_REMATCH[2]}"
            prompt value "$key" "$default"
            escaped="${value//\\/\\\\}"
            escaped="${escaped//\'/\\\'}"
            env_lines+=("$key=$escaped")
        else
            env_lines+=("$line")
        fi
    done 3< "$env_file"
    
    # Add closing section marker
    env_lines+=("$(get_end_section_line "$container_name")")
    
    write_to_env_file "$SETUP_DIR/.env" "${env_lines[@]}"
}

remove_env_section() {
    local env_file="$1"
    local container_name="$2"
    local temp_file="${env_file}.tmp$$"
    local in_section=false
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ \[BEGIN\]\ $container_name ]]; then
            in_section=true
        elif [[ "$line" =~ ^#\ \[END\]\ $container_name ]]; then
            in_section=false
            continue
        elif [[ "$in_section" == false ]]; then
            echo "$line" >> "$temp_file"
        fi
    done < "$env_file"
    
    mv "$temp_file" "$env_file"
}
