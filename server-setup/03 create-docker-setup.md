### Base structure

- create base directories:
  ```bash
  mkdir -p ~/docker/setup docker/data
  ls -ln ~/docker/
  ```
  Sample output for my user (which is 1000 - to verify type `id` in terminal) : 
  ```bash
  drwxrwxr-x 2 1000 1000 4096 Nov 20 14:33 data
  drwxrwxr-x 2 1000 1000 4096 Nov 20 14:33 setup
  ```
  In my case user is 1000 (and this will be used in `.env` file).

- create shared directories for file storage
  ```bash
  mkdir ~/docker/data/USER_X/
  ```

- create `.env` file and open it:
  ```bash
  touch ~/docker/setup/.env
  nano ~/docker/setup/.env
  ```

- paste this shared content:
  ```
  # Shared
  DOCKER_SETUP_DIR=/home/USER_X/docker/setup
  DOCKER_DATA_DIR=/home/USER_X/docker/data
  DOCKER_SOCKET_PATH=/var/run/docker.sock
  RESTART_POLICY=unless-stopped
  TZ=Europe/Warsaw
  PUID=1000
  PGID=1000
  APP_NETWORK=app-network
  ```

- save file `ctrl+o --> enter --> ctrl+x`

- create docker network for apps:
  ```bash 
  sudo docker network create -d bridge app-network
  ```
---


#### Directories structure:
```
.
└── home/user/docker/
    ├── data/               <--- shared between containers, data storage (samba, filebrowser)
    │   ├── general files/
    │   └── users
    │       ├── user-1-files/
    │       └── user-2-files/
    └── setup/              <--- compose files and all containers setup data/
        ├── .env            <--- all variables for docker compose files
        ├── compose.sh      <--- helper script to run compose files easier
        ├── samba/
        │   ├── compose.samba.yml
        │   └── data/
        ├── filebrowser/
        │   ├── compose.filebrowser.yml
        │   └── data/
        ├── vaultwarden/
        │   ├── compose.vaultwarden.yml
        │   └── data/
        ├── postgres/
        │   ├── compose.postgres.yml
        │   ├── data/
        │   └── backups/
        ...
```

Create base directory structure:
```bash 
mkdir -p /home/user/docker/data 
mkdir -p /home/user/docker/setup
ls -ln /home/user/docker/data /home/user/docker/data/bk   # owner column should be 1000
```









.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.
.


























Server architecture:
```
                                                         +---------------+
                                                         |     server    |
                                                         |  192.186.x.x  |
                                                         +---------------+
                                                                 |
                                                                 |
                               +---------------------------------+----------------------------------------+
                               |                                 |                                        |
        container.mydomain.com |           smb://192.168.x.x/data|               postgresql://192.168.x.x |
                               v                                 v                                        v
                       +-------*------+                  +-------*------+                         +-------*------+
                       |   Nginx PM   |                  |    Samba     |                         |   Postgres   |
                       +-------*------+                  +-------*------+                         +-------*------+
                               |
                               |
        +----------------------+---------------------+
        |                      |                     |
  +https|                +https|              +https |
        v                      v                     v
+-------*------+       +-------*------+      +-------*------+
| Filebrowser  |       | Vaultwarden  |      |      n8n     |
+-------*------+       +-------*------+      +-------*------+
```


graph source (https://termaid.com/)
```
graph TD
L["laptop"] -->|container.mydomain.com| N{"Nginx PM"} 
L -->|smb://192.168.x.x/data| S{"Samba"}
L -->|postgresql://192.168.x.x| P{"Postgres"}
N -->|+https| F{"Filebrowser"}
N -->|+https| V{"Vaultwarden"}
N -->|+https| N8{"n8n"}
```