#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../scripts/env-helper.sh"

docker_process_env_file() { 
    local -a env_lines=()
    local samba_admin_user="${LINUX_USER_NAME}_admin"
    local samba_admin_uid="$((LINUX_USER_ID + 1))"
    local samba_admin_gid="$((LINUX_GROUP_ID + 1))"
    env_lines+=("$(get_begin_section_line "$1")")

    prompt samba_version 'SAMBA_VERSION' 'latest'
    env_lines+=("SAMBA_VERSION=$samba_version")
    printf 'SAMBA_USER [%s]: %s\n' "$LINUX_USER_NAME" "$LINUX_USER_NAME" # this is locked
    env_lines+=("SAMBA_USER=$LINUX_USER_NAME")
    prompt samba_user_password 'SAMBA_PASSWORD' ''
    env_lines+=("SAMBA_PASSWORD=$samba_user_password")
    printf 'SAMBA_USER_ADMIN [%s]: %s\n' "$samba_admin_user" "$samba_admin_user" # this is locked
    env_lines+=("SAMBA_USER_ADMIN=$samba_admin_user")
    prompt samba_admin_user_password 'SAMBA_PASSWORD_ADMIN' ''
    env_lines+=("SAMBA_PASSWORD_ADMIN=$samba_admin_user_password")
    printf 'SAMBA_ADMIN_UID [%s]: %s\n' "$samba_admin_uid" "$samba_admin_uid" # this is locked
    env_lines+=("SAMBA_ADMIN_UID=$samba_admin_uid")
    printf 'SAMBA_ADMIN_GID [%s]: %s\n' "$samba_admin_gid" "$samba_admin_gid" # this is locked
    env_lines+=("SAMBA_ADMIN_GID=$samba_admin_gid")

    env_lines+=("$(get_end_section_line "$1")")
    
    write_to_env_file "$SETUP_DIR/.env" "${env_lines[@]}"
}

docker_create_container_specific_data() {
    local container_setup_dir="$SETUP_DIR/$1"

    mkdir -p "$container_setup_dir/data"
    cp "$SCRIPT_DIR/samba.compose.yml" "$container_setup_dir/samba.compose.yml"
    mkdir -p "$DATA_DIR/users/$LINUX_USER_NAME"
}

docker_post_create_actions() { 
    return 0;
}