## Instalacja Portainer

### 0. Dokumentacja

Portainer to webowy interfejs do zarządzania dockerem, bardzo przydatne, gdy nie lubimy zarządzać z poziomu terminala.
Wszystko co tutaj jest wymienione pochodzi z oficjalnej dokumentacji: [Instalacja Portainer]([https://docs.docker.com/engine/install/ubuntu/](https://docs.portainer.io/start/install-ce/server/docker/linux#docker-compose))

### 1. Plik compose

Poniżej zmodyfikowany plik docker compose, aby stworzyć i uruchomić portainer:
```
services:
  portainer:
    container_name: portainer
    image: portainer/portainer-ce:lts
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /home/USER/docker/portainer/data:/data
    ports:
      - 9443:9443
      - 8000:8000  # optional for Edge Agents
    network_mode: bridge
```

Moje modyfikacje to:
- restart: *unless-stopped* zamiast *always*
- volumes: data wskazuje na folder w moim home
- network_mode: chcę żeby portainer korzystał z domyślnej sieci

Przed uruchomieniem pliku tworzymy folder *portainer* (wewnątrz folderu *docker* utowrzonego po instalacji dockera). Upewnij się, że jesteś w */home/USER*:
```
pwd
```
Powinno pokazać */home/USER* (USER to nazwa usera jaką podałeś przy instalacji Ubuntu - w moim przypadku *bk*). Jeśli nie to wywołaj: 
```
cd
```
A teraz utworzenie potrzebnych folderów i pliku:
```
mkdir docker/portainer
mkdir docker/portainer/data
cd portainer
touch docker-compose.yml
```
Wklejamy zawartość pliku compose do *docker-compose.yml*. Skopiuj kod wyżej, a następnie:
```
nano docker-compose.yml
Ctrl+Shift+V -> wklei tekst
Ctrl+O -> zapyta czy zapisać
Enter -> potwierdź zapis
Ctrl+X -> zamknij plik
```
---
### 2. Utworzenie kontenera

Teraz uruchamiamy komendę (będąc w */home/USER/docker/portainer*):
```
sudo docker compose up -d
```
Czekamy chwilę i kontener powinien zostać uruchomiony.

### 3. Konfiguracja wstępna

Przy instalacji Ubuntu na samym końcu sprawdzaliśmy IP naszego serwera w sieci. Teraz musimy użyć tego IP, żeby skonfigurować portainer. 
Otwieramy przeglądarkę i wpisujemy adres:
```
https://IP:9443
```
Możliwe, że trzeba będzie zaakceptować ryzyko (braku certyfikatu https), ale to nasz serwer więc akceptujemy. Powinno wyświetlić się:

<img width="1401" height="883" alt="image" src="https://github.com/user-attachments/assets/ba068759-6f7d-4c52-a99a-0bf89770fdb5" />

Wpisujemy nazwę naszego admina i dwukrotnie hasło.
Następnie wracamy do terminala i uruchamiamy:
```
sudo docker logs portainer
```
i kopiujemy wartość pola *setup_token=345kjh345hk;j3245kjh23k5jhk...*

Może się zdarzyć, że zamiast panelu do tworzenia usera zobaczymy błąd z sugestią, żeby zrestartować kontener. Wtedy wracamy do terminala do */home/USER/docker/portainer*
i uruchamiamy:
```
sudo docker compose down
sudo docker compose up -d
sudo docker logs portainer
```

Od razu kopiujemy *setup_token*, odświeżamy stronę w przeglądarce i uzupełniamy wszystkie pola. Pomijamy krok, w którym proponuje nam Edge Agents. Powinniśmy zobaczyć to:

<img width="1181" height="630" alt="image" src="https://github.com/user-attachments/assets/fcebfa93-6723-484a-a849-2fa9ffb6aff3" />

Klikamy *Home* po lewej stronie i wybieramy *local*. Teraz jesteśmy w kontekście naszego lokalnego środowiska i możemy przeglądać kontenery.

<img width="1688" height="510" alt="image" src="https://github.com/user-attachments/assets/b5fc33ee-d76e-4ad4-aa56-c388091635fb" />
