#!/usr/bin/env bash
set -Eeuo pipefail
umask 077

SETUP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TEMPLATES_DIR="$SETUP_DIR/templates"
ENV_FILE="$SETUP_DIR/.env"
DOCKER=(docker)

fail() {
	printf 'Error: %s\n' "$*" >&2
	exit 1
}

confirm() {
	local answer
	read -r -p "$1 [y/N]: " answer || return 1
	[[ "$answer" == [yY] || "$answer" == [yY][eE][sS] ]]
}

prompt() {
	local variable="$1" message="$2" default="$3" answer
	read -r -p "$message [$default]: " answer || fail 'Input cancelled.'
	printf -v "$variable" '%s' "${answer:-$default}"
}

password_prompt() {
	local variable="$1" message="$2" minimum="$3" password repeated
	while true; do
		read -r -s -p "$message: " password || fail 'Input cancelled.'
		printf '\n'
		read -r -s -p 'Repeat password: ' repeated || fail 'Input cancelled.'
		printf '\n'
		if [[ "$password" == "$repeated" && ${#password} -ge "$minimum" ]]; then
			printf -v "$variable" '%s' "$password"
			return
		fi
		printf 'Passwords must match and contain at least %s characters.\n' "$minimum"
	done
}

as_root() {
	if (( EUID == 0 )); then
		"$@"
	else
		sudo "$@"
	fi
}

env_has() {
	[[ -f "$ENV_FILE" ]] && grep -qE "^[[:space:]]*$1=" "$ENV_FILE"
}

env_get() {
	local line value
	while IFS= read -r line || [[ -n "$line" ]]; do
		if [[ "$line" == "$1="* ]]; then
			value="${line#*=}"
			if [[ "$value" == \"*\" || "$value" == \'*\' ]]; then
				value="${value:1:${#value}-2}"
			fi
			printf '%s' "$value"
			return
		fi
	done < "$ENV_FILE"
	return 1
}

env_add() {
	local key="$1" value="$2"
	env_has "$key" && return 0
	value="${value//\'/\\\'}"
	printf "%s='%s'\n" "$key" "$value" >> "$ENV_FILE"
}

env_set() {
	local key="$1" value="$2" temporary
	temporary="$(mktemp "$SETUP_DIR/.env.XXXXXX")"
	if ! awk -v key="$key" '$0 !~ "^[[:space:]]*" key "=" { print }' "$ENV_FILE" > "$temporary"; then
		rm -f -- "$temporary"
		fail 'Could not update .env.'
	fi
	mv -- "$temporary" "$ENV_FILE"
	env_add "$key" "$value"
}

install_docker() {
	local codename architecture
	[[ -r /etc/os-release ]] || fail 'Cannot determine the operating system.'
	source /etc/os-release
	[[ "$ID" == ubuntu ]] || fail 'Automatic installation supports Ubuntu only.'
	codename="${UBUNTU_CODENAME:-${VERSION_CODENAME:-}}"
	[[ -n "$codename" ]] || fail 'Cannot determine the Ubuntu codename.'
	architecture="$(dpkg --print-architecture)"
	as_root apt-get update
	as_root apt-get install -y ca-certificates curl
	as_root install -m 0755 -d /etc/apt/keyrings
	as_root curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
	as_root chmod a+r /etc/apt/keyrings/docker.asc
	printf 'Types: deb\nURIs: https://download.docker.com/linux/ubuntu\nSuites: %s\nComponents: stable\nArchitectures: %s\nSigned-By: /etc/apt/keyrings/docker.asc\n' \
		"$codename" "$architecture" | as_root tee /etc/apt/sources.list.d/docker.sources > /dev/null
	as_root apt-get update
	as_root apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
	as_root systemctl enable --now docker
}

initialize_docker() {
	if ! docker info > /dev/null 2>&1; then
		as_root systemctl start docker
		if (( EUID != 0 )); then
			DOCKER=(sudo docker)
		fi
	fi
	"${DOCKER[@]}" info > /dev/null || fail 'Cannot connect to Docker.'
	"${DOCKER[@]}" compose version > /dev/null || fail 'Install the Docker Compose plugin before continuing.'
}

initialize_structure() {
	local data_dir timezone owner uid gid directory
	[[ ! -L "$ENV_FILE" ]] || fail '.env must not be a symbolic link.'
	touch "$ENV_FILE"
	chmod 600 "$ENV_FILE"
	owner="${SUDO_USER:-$(id -un)}"
	uid="$(id -u "$owner")"
	gid="$(id -g "$owner")"
	if ! env_has DOCKER_SETUP_DIR; then
		printf '\n# Shared\n' >> "$ENV_FILE"
		env_add DOCKER_SETUP_DIR "$SETUP_DIR"
	fi
	[[ "$(env_get DOCKER_SETUP_DIR)" == "$SETUP_DIR" ]] || fail 'DOCKER_SETUP_DIR in .env must match the directory containing this script.'
	if ! env_has DOCKER_DATA_DIR; then
		prompt data_dir 'Shared data directory (absolute path)' "$(dirname -- "$SETUP_DIR")/data"
		[[ "$data_dir" == /* ]] || fail 'The data directory must be an absolute path.'
		env_add DOCKER_DATA_DIR "$data_dir"
	fi
	if ! env_has TZ; then
		prompt timezone 'Timezone' 'Europe/Warsaw'
		env_add TZ "$timezone"
	fi
	env_add DOCKER_SOCKET_PATH /var/run/docker.sock
	env_add RESTART_POLICY unless-stopped
	env_add PUID "$uid"
	env_add PGID "$gid"
	env_add APP_NETWORK app-network
	data_dir="$(env_get DOCKER_DATA_DIR)"
	[[ "$data_dir" == /* && "$data_dir" != / ]] || fail 'Invalid DOCKER_DATA_DIR.'
	[[ "$data_dir" != "$SETUP_DIR" && "$data_dir" != "$SETUP_DIR/"* ]] || fail 'Shared data must be stored outside the setup directory.'
	uid="$(env_get PUID)"
	gid="$(env_get PGID)"
	[[ "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]] || fail 'PUID and PGID must be numeric.'
	mkdir -p -- "$TEMPLATES_DIR"
	for directory in "$data_dir" "$data_dir/users"; do
		if [[ ! -d "$directory" ]]; then
			mkdir -p -- "$directory"
			as_root chown "$uid:$gid" "$directory"
		fi
	done
}

ensure_network() {
	local network
	network="$(env_get APP_NETWORK)"
	[[ -n "$network" ]] || fail 'APP_NETWORK must not be empty.'
	if ! "${DOCKER[@]}" network inspect "$network" > /dev/null 2>&1; then
		"${DOCKER[@]}" network create -d bridge "$network" > /dev/null
	fi
}

compose() {
	"${DOCKER[@]}" compose --project-name "$APP" --file "$APP_DIR/compose.$APP.yml" --env-file "$ENV_FILE" "$@"
}

select_app() {
	local choice
	printf '\n1) Nginx Proxy Manager\n2) Filebrowser\n3) Cancel\n'
	read -r -p 'Select container: ' choice || return 1
	case "$choice" in
		1) APP=nginx-pm; CONTAINER=nginx-pm ;;
		2) APP=filebrowser; CONTAINER=filebrowser-quantum ;;
		3) return 1 ;;
		*) printf 'Invalid selection.\n'; return 1 ;;
	esac
	APP_DIR="$SETUP_DIR/$APP"
	[[ ! -L "$APP_DIR" ]] || fail 'The container directory must not be a symbolic link.'
}

configure_app() {
	local version http_port admin_port https_port admin_password
	if [[ "$APP" == nginx-pm ]]; then
		prompt version 'Nginx Proxy Manager image tag' latest
		prompt http_port 'HTTP port' 80
		prompt admin_port 'Admin port' 81
		prompt https_port 'HTTPS port' 443
		validate_ports "$http_port" "$admin_port" "$https_port"
		printf '\n# Nginx Proxy Manager\n' >> "$ENV_FILE"
		env_set NGINX_PM_VERSION "$version"
		env_set NGINX_HTTP_PORT "$http_port"
		env_set NGINX_ADMIN_PORT "$admin_port"
		env_set NGINX_HTTPS_PORT "$https_port"
	else
		prompt version 'Filebrowser image tag' stable
		prompt http_port 'HTTP port' 7000
		validate_ports "$http_port"
		password_prompt admin_password 'Filebrowser admin password' 5
		printf '\n# FileBrowser\n' >> "$ENV_FILE"
		env_set FILEBROWSER_VERSION "$version"
		env_set FILEBROWSER_HTTP_PORT "$http_port"
		env_set FILEBROWSER_ADMIN_PASSWORD "$admin_password"
	fi
}

validate_ports() {
	local port
	for port in "$@"; do
		[[ "$port" =~ ^[0-9]{1,5}$ ]] || fail 'Ports must be numeric.'
		(( 10#$port >= 1 && 10#$port <= 65535 )) || fail 'Ports must be between 1 and 65535.'
	done
}

create_app() {
	local username data_dir uid gid
	[[ -f "$TEMPLATES_DIR/compose.$APP.yml" ]] || fail "Missing template: $TEMPLATES_DIR/compose.$APP.yml"
	if [[ "$APP" == filebrowser ]]; then
		[[ -f "$TEMPLATES_DIR/config.filebrowser.yml" ]] || fail "Missing template: $TEMPLATES_DIR/config.filebrowser.yml"
		prompt username 'Non-admin Filebrowser username' "${SUDO_USER:-$(id -un)}"
		[[ "$username" =~ ^[a-zA-Z0-9_][a-zA-Z0-9_.-]*$ && "$username" != admin ]] || fail 'Use a non-admin username containing only letters, numbers, dots, underscores, or hyphens.'
	fi
	configure_app
	mkdir -p -- "$APP_DIR/data"
	cp -- "$TEMPLATES_DIR/compose.$APP.yml" "$APP_DIR/compose.$APP.yml"
	if [[ "$APP" == nginx-pm ]]; then
		mkdir -p -- "$APP_DIR/letsencrypt"
	else
		cp -- "$TEMPLATES_DIR/config.filebrowser.yml" "$APP_DIR/data/config.yaml"
		data_dir="$(env_get DOCKER_DATA_DIR)"
		uid="$(env_get PUID)"
		gid="$(env_get PGID)"
		[[ "$uid" =~ ^[0-9]+$ && "$gid" =~ ^[0-9]+$ ]] || fail 'PUID and PGID must be numeric.'
		mkdir -p -- "$data_dir/users/$username"
		as_root chown -R "$uid:$gid" "$APP_DIR/data"
		as_root chown "$uid:$gid" "$data_dir/users/$username"
	fi
	ensure_network
	compose config --quiet
	compose up -d
	if [[ "$APP" == filebrowser ]]; then
		printf 'Wait for Filebrowser to finish starting. Its logs follow.\n'
		compose logs --tail 30
		if confirm 'Is Filebrowser ready to create the non-admin user?'; then
			printf 'Enter the non-admin password at the Filebrowser prompt.\n'
			"${DOCKER[@]}" exec -it "$CONTAINER" ./filebrowser user set "$username" --password
		else
			printf 'User creation skipped. Run: sudo docker exec -it filebrowser-quantum ./filebrowser user set %s --password\n' "$username"
		fi
		printf 'In the admin UI, enable write permissions for the user under Settings > User management > Home.\n'
	fi
	printf '%s created. Configure accounts, DNS, certificates, and proxy hosts in the web UI as needed.\n' "$APP"
}

update_app() {
	[[ -f "$APP_DIR/compose.$APP.yml" ]] || fail 'Cannot update without the local Compose file.'
	compose config --quiet
	compose stop
	if ! compose pull; then
		printf 'Image pull failed; restarting the existing container.\n' >&2
		compose start
		return 1
	fi
	ensure_network
	compose up -d --force-recreate
	printf '%s updated using the image tag in .env.\n' "$APP"
}

remove_env_section() {
	local temporary
	temporary="$(mktemp "$SETUP_DIR/.env.XXXXXX")"
	if ! awk -v app="$APP" '
		app == "nginx-pm" && ($0 ~ /^# Nginx Proxy Manager[[:space:]]*$/ || $0 ~ /^[[:space:]]*(NGINX_PM_VERSION|NGINX_HTTP_PORT|NGINX_ADMIN_PORT|NGINX_HTTPS_PORT)=/) { next }
		app == "filebrowser" && ($0 ~ /^# File[Bb]rowser[[:space:]]*$/ || $0 ~ /^[[:space:]]*(FILEBROWSER_VERSION|FILEBROWSER_HTTP_PORT|FILEBROWSER_ADMIN_PASSWORD)=/) { next }
		{ print }
	' "$ENV_FILE" > "$temporary"; then
		rm -f -- "$temporary"
		fail 'Could not update .env.'
	fi
	chmod 600 "$temporary"
	mv -- "$temporary" "$ENV_FILE"
}

remove_app() {
	[[ "$(env_get DOCKER_SETUP_DIR)" == "$SETUP_DIR" ]] || fail 'DOCKER_SETUP_DIR must match this script directory before removal.'
	printf 'This deletes %s and ALL configuration, databases, and certificates inside it.\n' "$APP_DIR"
	printf 'Shared files in DOCKER_DATA_DIR will be kept.\n'
	confirm "Permanently remove $APP?" || return 0
	[[ -f "$APP_DIR/compose.$APP.yml" ]] || fail 'Cannot safely remove a container without its local Compose file.'
	compose down
	as_root rm -rf -- "$APP_DIR"
	remove_env_section
	printf '%s removed.\n' "$APP"
}

main() {
	local choice
	if ! command -v docker > /dev/null 2>&1; then
		printf 'Docker is not installed.\n1) Install Docker and create base structure\n2) Cancel\n'
		read -r -p 'Select action: ' choice || return 0
		[[ "$choice" == 1 ]] || return 0
		install_docker
		initialize_docker
		initialize_structure
		ensure_network
	else
		initialize_docker
	fi
	select_app || return 0
	if [[ -e "$APP_DIR" ]] || "${DOCKER[@]}" container inspect "$CONTAINER" > /dev/null 2>&1; then
		printf '\n1) Update\n2) Remove\n3) Cancel\n'
		read -r -p 'Select action: ' choice || return 0
		case "$choice" in
			1) initialize_structure; update_app ;;
			2) [[ -f "$ENV_FILE" && ! -L "$ENV_FILE" ]] || fail 'A regular .env file is required for removal.'; remove_app ;;
			3) return 0 ;;
			*) fail 'Invalid selection.' ;;
		esac
	else
		printf '\n1) Create\n2) Cancel\n'
		read -r -p 'Select action: ' choice || return 0
		case "$choice" in
			1) initialize_structure; create_app ;;
			2) return 0 ;;
			*) fail 'Invalid selection.' ;;
		esac
	fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
	main "$@"
fi
