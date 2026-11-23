#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../scripts/env-helper.sh"
. "$SCRIPT_DIR/../scripts/functions.sh"

docker_process_env_file() { 
    confirm 'This container requires argon2 package to secure admin password, it will installed now, continue? (y/n)'

    as_root apt-get install -y argon2

    local -a env_lines=()
    env_lines+=("$(get_begin_section_line "$1")")

    prompt vaultwarden_version 'VAULTWARDEN_VERSION' 'latest'
    env_lines+=("VAULTWARDEN_VERSION=$vaultwarden_version")
    prompt vaultwarden_http_port 'VAULTWARDEN_HTTP_PORT' '7001'
    env_lines+=("VAULTWARDEN_HTTP_PORT=$vaultwarden_http_port")
    prompt vaultwarden_signups_allowed 'VAULTWARDEN_SIGNUPS_ALLOWED' 'true'
    env_lines+=("VAULTWARDEN_SIGNUPS_ALLOWED=$vaultwarden_signups_allowed")
    
    prompt vaultwarden_admin_password 'VAULTWARDEN_ADMIN_PASSWORD' ''
    env_lines+=("VAULTWARDEN_ADMIN_TOKEN='$(echo -n "$vaultwarden_admin_password" | argon2 "$(openssl rand -base64 32)" -e -id -k 65540 -t 3 -p 4)'")

    env_lines+=("$(get_end_section_line "$1")")
    
    write_to_env_file "$SETUP_DIR/.env" "${env_lines[@]}"
}

docker_create_container_specific_data() {
    local container_setup_dir="$SETUP_DIR/$1"

    mkdir -p "$container_setup_dir/data"
    cp "$SCRIPT_DIR/vaultwarden.compose.yml" "$container_setup_dir/vaultwarden.compose.yml"
    mkdir -p "$DATA_DIR/users/$LINUX_USER_NAME"
}

docker_post_create_actions() { 
    return 0;
}