#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../scripts/env-helper.sh"

docker_process_env_file() { 
    process_general_env_file "$SCRIPT_DIR/$1.env" "$1"
 }

docker_create_container_specific_data() {
    local container_setup_dir="$SETUP_DIR/$1"

    mkdir -p "$container_setup_dir/data" "$container_setup_dir/letsencrypt"
    cp "$SCRIPT_DIR/nginx-pm.compose.yml" "$container_setup_dir/nginx-pm.compose.yml"
}

docker_post_create_actions() { return 0; }