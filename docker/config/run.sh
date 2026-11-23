#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/scripts/functions.sh"
. "$SCRIPT_DIR/scripts/env-helper.sh"

LINUX_USER_NAME="$(id -un)" || return 1
LINUX_USER_ID="$(id -u)"
LINUX_GROUP_ID="$(id -g)"
MAIN_DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_DIR="$MAIN_DOCKER_DIR/setup"
DATA_DIR="$MAIN_DOCKER_DIR/data"

# Scan and import all scripts from the templates directory
scripts=()
for script in "$SCRIPT_DIR"/templates/*.sh; do
    name="${script##*/}"                 # strip directory part
    name="${name%.script.sh}"            # strip script extension
    scripts+=("$name")
done

select_option(){
    local -n options_array="$1"
    local message="$2" selection i
    printf '%s\n' "$message"
    for i in "${!options_array[@]}"; do
        printf '%d: %s\n' "$((i+1))" "${options_array[$i]}"
    done

    read -r -p ">> " selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || (( selection < 1 || selection > ${#options_array[@]} )); then
        fail 'Invalid selection.'
    fi
    selected_option="${options_array[$selection-1]}"
    # printf 'You selected: %s\n' "$selected_option"
}

docker_compose_down() {
    as_root docker compose --file "$SETUP_DIR/$1/$1.compose.yml" --env-file "$SETUP_DIR/.env" down
}

docker_compose_up() {
    as_root docker compose --file "$SETUP_DIR/$1/$1.compose.yml" --env-file "$SETUP_DIR/.env" up -d
}

docker_compose_pull() {
    as_root docker compose --file "$SETUP_DIR/$1/$1.compose.yml" --env-file "$SETUP_DIR/.env" pull
}

# base docker actions
docker_start() {
    printf "Starting $1 container... \n"
    as_root docker start "$1"
    printf "Started $1 container.\n"
}

docker_stop() {
    printf "Stopping $1 container... \n"
    as_root docker stop "$1"
    printf "Stopped $1 container.\n"
}

docker_up() {
    confirm 'Want to continue with compose up? (y/n): '

    local setup_created=false
    if [[ ! -f "$SETUP_DIR/$1/$1.compose.yml" ]]; then
        confirm 'Container setup does not exist. Create it? (y/n): '

        printf "Composing up $1 container setup... \n"

        docker_process_env_file "$1"
        docker_create_container_specific_data "$1"

        printf "Created $1 container setup...\n"
        setup_created=true
    else
        printf "Container setup for %s already exists.\n" "$1"
    fi

    printf "Composing up $1 container... \n"
    docker_compose_up "$1"

    if [[ "$setup_created" == true ]]; then
        docker_post_create_actions "$1"
    fi

    printf "Composed up $1 container.\n"
}

docker_update() {
    confirm 'Want to continue with container update? (y/n): '

    printf "Updating $1 container... \n"
    docker_compose_pull "$1"
    docker_compose_down "$1"
    docker_compose_up "$1"
    printf "Updated $1 container.\n"
    printf "This action did not remove the old image. Once you make sure the new container is running correctly, you may want to remove the old image manually.\n"
}

docker_down() {
    confirm 'Want to continue with compose down? (y/n): '

    printf "Composing down $1 container... \n"
    docker_compose_down "$1"
    printf "Composed down $1 container.\n"

    data_remove "$1"
}

data_remove() {
    confirm 'Want to continue with removing container setup (you can do it later with remove operation)? (y/n): '

    remove_env_section "$SETUP_DIR/.env" "$1"
    as_root rm -rf "$SETUP_DIR/$1"
    printf "Removed $1 container setup.\n"
}

setup_general_env_variables(){
    if [[ -f "$SETUP_DIR/.env" ]]; then
        printf 'General .env file already exists at: %s\n\n' "$SETUP_DIR/.env"
        return 0
    fi

    local docker_socket_path="/var/run/docker.sock"
    local restart_policy="unless-stopped"
    local network_name="app-network"
    local timezone="Europe/Warsaw"
    
    printf 'Initializing general environment variables...\n'
    printf 'Linux user name: %s\n' "$LINUX_USER_NAME"
    printf 'Linux user ID: %s\n' "$LINUX_USER_ID"
    printf 'Linux group ID: %s\n' "$LINUX_GROUP_ID"
    printf 'Main Docker directory: %s\n' "$MAIN_DOCKER_DIR"
    printf 'Setup directory: %s\n' "$SETUP_DIR"
    printf 'Data directory: %s\n' "$DATA_DIR"
    printf 'Docker socket path: %s\n' "$docker_socket_path"
    printf 'Restart policy: %s\n' "$restart_policy"
    printf 'Network name: %s\n' "$network_name"
    printf 'Timezone: %s\n' "$timezone"

    printf '\nCreate initial .env file? (y/n): '
    read -r create_env
    if [[ "$create_env" != "y" ]]; then
        exit 0
    fi

    printf 'General env file can be found at: %s\n' "$SETUP_DIR/.env"
    printf 'If you wish to modify these please run:\n'
    printf 'nano %s\n\n\n' "$SETUP_DIR/.env"

    mkdir -p "$SETUP_DIR"
    touch "$SETUP_DIR/.env"
    printf '%s\n' "# Shared - you should not change these values" >> "$SETUP_DIR/.env"
    printf '%s\n' "USER=$LINUX_USER_NAME" >> "$SETUP_DIR/.env"
    printf '%s\n' "PUID=$LINUX_USER_ID" >> "$SETUP_DIR/.env"
    printf '%s\n' "PGID=$LINUX_GROUP_ID" >> "$SETUP_DIR/.env"
    printf '%s\n' "DOCKER_DIR=$MAIN_DOCKER_DIR" >> "$SETUP_DIR/.env"
    printf '%s\n' "DOCKER_SETUP_DIR=$SETUP_DIR" >> "$SETUP_DIR/.env"
    printf '%s\n' "DOCKER_DATA_DIR=$DATA_DIR" >> "$SETUP_DIR/.env"
    printf '%s\n' "DOCKER_SOCKET_PATH=$docker_socket_path" >> "$SETUP_DIR/.env"

    printf '\n%s\n' "# Shared - change according to your setup" >> "$SETUP_DIR/.env"
    printf '%s\n' "RESTART_POLICY=$restart_policy" >> "$SETUP_DIR/.env"
    printf '%s\n' "APP_NETWORK=$network_name" >> "$SETUP_DIR/.env"
    printf '%s\n\n' "TZ=$timezone" >> "$SETUP_DIR/.env"
}


main(){
    setup_general_env_variables

    select_option scripts "Select container you want to manage:"
    selected_script="$selected_option"
    . "$SCRIPT_DIR/templates/$selected_script.script.sh"

    operations=("start" "stop" "restart" "compose up" "compose down" "update image" "remove setup")
    select_option operations "Select operation for container >> $selected_script:"
    selected_operation="$selected_option"

    printf 'Selected container: %s\nSelected operation: %s\n' "$selected_script" "$selected_operation"

    case "$selected_operation" in
        "start")         docker_start "$selected_script" ;;
        "stop")          docker_stop "$selected_script" ;;
        "compose up")    docker_up "$selected_script" ;;
        "compose down")  docker_down "$selected_script" ;;
        "update image")  docker_update "$selected_script" ;;
        "remove setup")  data_remove "$selected_script" ;;
        -)       printf "No operation selected.\n" ;;
        *)       fail "Unknown operation: $selected_operation" ;;
    esac
}

main
