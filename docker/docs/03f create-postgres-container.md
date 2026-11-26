### PostgreSQL [ [docs](https://hub.docker.com/_/postgres/) ]

- create directories:
  ```bash
  cd ~/docker/setup
  mkdir -p postgres/data
  touch postgres/postgres.compose.yml
  nano postgres/postgres.compose.yml
  ```

- paste the content of [postgres.compose.yml](../config/templates/postgres.compose.yml) and save `ctrl+o --> enter --> ctrl+x`.

- open `.env` file and add PostgreSQL section (**put there your values!**):
  ```bash
  nano .env
  ```
  ```
  # PostgreSQL
  POSTGRES_VERSION=latest
  POSTGRES_DB=USER_X_POSTGRES_DB
  POSTGRES_USER=USER_X_POSTGRES_USER
  POSTGRES_PASSWORD=USER_X_POSTGRES_PASSWORD
  POSTGRES_PORT=5432
  ```

- save file `ctrl+o --> enter --> ctrl+x`

- run the container:
  ```bash
  sudo docker compose --file postgres/postgres.compose.yml --env-file .env up
  ```

- look at logs to see whether the container started and hit `d` to detach if there are no issues

- in case of issues you can detach and stop the container:
  ```bash
  sudo docker compose --file postgres/postgres.compose.yml --env-file .env down
  ```

- verify the container is running:
  ```bash
  sudo docker ps | grep postgres
  ```

- to access the PostgreSQL database from your host machine, use a PostgreSQL client like `psql`:
  ```bash
  psql -h localhost -p 5432 -U USER_X_POSTGRES_USER -d USER_X_POSTGRES_DB
  ```
  then enter the password when prompted (use the value from `POSTGRES_PASSWORD`)

- alternatively, you can connect to the container shell:
  ```bash
  sudo docker exec -it postgres sh
  ```
  inside container shell to access PostgreSQL:
  ```bash
  psql -U USER_X_POSTGRES_USER -d USER_X_POSTGRES_DB
  ```
  then type `\q` to exit

#### > Connecting from other containers

If you have other containers that need to access PostgreSQL, they should:
1. Be connected to the same Docker network (by default `app-network`)
2. Use the container name `postgres` as the hostname
3. Use port `5432` (internal container port, not the external port from `.env`)

Example connection string for applications inside other containers:
```
postgresql://USER_X_POSTGRES_USER:USER_X_POSTGRES_PASSWORD@postgres:5432/USER_X_POSTGRES_DB
```

#### > Nginx Proxy Stream

If you want to be able to connect to postgres db using `yourdomain.com` you can create new stream in Nginx interface:
- go to streams
- click *Add stream*
- Incoming port: 5432, Forward Host: postgres (*name of the container*), Forward Port: 5432
- enable TCP switch
- in SSL tab pick your certificate

Example connection string for applications:
```
postgresql://USER_X_POSTGRES_USER:USER_X_POSTGRES_PASSWORD@yourdomain.com:5432/USER_X_POSTGRES_DB
```
