## Instalacja Nginx Proxy Manager

### 1. Plik compose

Poniżej plik docker compose, aby stworzyć i uruchomić nginx porxy manager:
```
services:
  nginx-pm:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-pm
    restart: unless-stopped
    network_mode: bridge
    init: true

    ports:
      - "80:80"
      - "81:81"
      - "443:443"

    environment:
      TZ: Europe/Warsaw

    volumes:
      - /home/USER/docker/nginx-pm/data:/data
      - /home/USER/docker/nginx-pm/letsencrypt:/etc/letsencrypt
```

Otwórz terminal i połącz się z serwerem:
```
ssh USER@192.168.XXX.XXX
```

Przed uruchomieniem pliku tworzymy folder *nginx-pm* (wewnątrz folderu *docker* utowrzonego po instalacji dockera). Upewnij się, że jesteś w */home/USER*:
```
cd docker
mkdir nginx-pm
mkdir nginx-pm/data
mkdir nginx-pm/letsencrypt
cd nginx-pm
touch docker-compose.yml
```
Wklejamy zawartość pliku compose do *docker-compose.yml*. Skopiuj kod wyżej, a następnie:
```
nano docker-compose.yml
Ctrl+Shift+V -> wklei tekst
Zmień USER na swojego usera, np. bk
Ctrl+O -> zapyta czy zapisać
Enter -> potwierdź zapis
Ctrl+X -> zamknij plik
```
---


### 2. Utworzenie kontenera

Teraz uruchamiamy komendę (będąc w */home/USER/docker/nginx-pm*):
```
sudo docker compose up -d
```

### 3. Konfiguracja
