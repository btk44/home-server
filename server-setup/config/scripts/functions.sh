#!/usr/bin/env bash

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
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