## Instalacja Docker

### 0. Dokumentacja

Wszystko, co opisano w tym poradniku, pochodzi z oficjalnej dokumentacji: [Instalacja Dockera w systemie Ubuntu](https://docs.docker.com/engine/install/ubuntu/).


### 1. Konfiguracja repozytorium Dockera

Otwórz terminal i połącz się z serwerem:
```
ssh USER@192.168.XXX.XXX
```

W terminalu uruchamiamy kolejno polecenia z dokumentacji:
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

### 2. Instalacja pakietów

Po aktualizacji pakietów APT z poprzedniego kroku uruchamiamy polecenie instalacyjne:
```
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```
---

### 3. Uruchomienie

Po zakończeniu instalacji sprawdzamy status usługi Docker:
```
sudo systemctl status docker
```
Jeśli usługa nie jest aktywna (`active`), uruchamiamy ją poleceniem:
```
sudo systemctl start docker
```
---

### 4. Utworzenie folderu na konfiguracje i dane kontenerów

Tworzymy katalog, w którym będziemy przechowywać konfiguracje i dane Dockera:
```
mkdir docker
```
---

**Zdecydowanie polecam traktować ten poradnik jako nieaktualny i skorzystać z oficjalnej dokumentacji Dockera podanej na początku.**

