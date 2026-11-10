## Instalacja Docker

### 0. Dokumentacja

Wszystko co tutaj jest wymienione pochodzi z oficjalnej dokumentacji: [Instalacja Docker - Ubuntu](https://docs.docker.com/engine/install/ubuntu/)


### 1. Ustawienie repozytorium docker

W terminalu wywołujemy po kolei komendy z dokumentacji:
```
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

```
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```
```
sudo apt update
```

---

### 2. Instalacja paczek

Po aktualizacji apt (z poprzedniego kroku), wywołujemy komendę instalacyjną:
```
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
---

### 3. Uruchomienie

Po zakończonej instalacji sprawdzamy status dockera:
```
sudo systemctl status docker
```
Jeśli nie jest 'enabled', to uruchamiamy:
```
sudo systemctl start docker
```
---

**mocno polecam ten poradnik traktować jako przedawniony i skorzystać z oficjalnej strony dockera podanej na początku**

