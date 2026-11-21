#### Samba  [ [docs](https://github.com/crazy-max/docker-samba) ]

- create directories:
  ```bash
  cd ~/docker/setup
  mkdir -p samba/data
  touch samba/samba.compose.yml
  nano samba/samba.compose.yml
  ```

- paste the content of [samba.compose.yml](../config/templates/samba.compose.yml) and save `ctrl+o --> enter --> ctrl+x`.
  This file contains two users and two shares. One is an admin user with access to all data directory and the other user has access to his directory only. Admin user is just a fake access user. All files saved physically on docker host system will be owned by default USER_X.
- create directory for default USER_X:
  ```bash 
  mkdir -p ~/docker/data/users/USER_X
  ```
- open `.env` file and paste samba section (**put there your values!**):
  ```bash
  nano .env
  ```
  ```
  # Samba
  SAMBA_VERSION=latest
  SAMBA_USER=USER_X
  SAMBA_PASSWORD=USER_X_PASSWORD
  SAMBA_USER_ADMIN=USER_X_ADMIN
  SAMBA_PASSWORD_ADMIN=USER_X_ADMIN_PASSWORD
  SAMBA_ADMIN_UID=1001
  SAMBA_ADMIN_GID=1001
  ```
- save file `ctrl+o --> enter --> ctrl+x`
- run the container:
  ```bash
  sudo docker compose --file samba/samba.compose.yml --env-file .env up
  ```
- look at logs to see whether the container started and hit `d` to detach if there are no issues
- in case of issues you can detach and stop the container
  ```bash
  sudo docker compose --file samba/samba.compose.yml --env-file .env down
  ```