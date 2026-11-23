#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/../scripts/env-helper.sh"

docker_process_env_file() { 
    process_general_env_file "$SCRIPT_DIR/$1.env" "$1"
}

docker_create_container_specific_data() {
    local container_setup_dir="$SETUP_DIR/$1"

    mkdir -p "$DATA_DIR/users"
    mkdir -p "$container_setup_dir/data"
    cp "$SCRIPT_DIR/filebrowser.compose.yml" "$container_setup_dir/filebrowser.compose.yml"
    cp "$SCRIPT_DIR/filebrowser.config.yml" "$container_setup_dir/data/config.yaml"
}

docker_post_create_actions() {   
    local username
    prompt username 'File Browser username' ''
    if [[ -z "$username" ]]; then
        printf 'Error: username cannot be empty.\n' >&2
        return 1
    fi

    printf 'Enter the password at the File Browser prompt.\n'
    sudo docker exec -it filebrowser ./filebrowser user set "$username" --password
}