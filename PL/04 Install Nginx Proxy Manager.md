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
---

### 3. Konfiguracja

Uruchamiamy przeglądarkę i wpisujemy adres naszego servera z portem 81. Powinniśmy zobaczyć ekran tworzenia admina:

<img width="806" height="767" alt="image" src="https://github.com/user-attachments/assets/12dab6e7-757a-4c14-8284-cac6a15f76d3" />


Po utworzeniu admina zobaczymy poniższy ekran:

<img width="1172" height="391" alt="image" src="https://github.com/user-attachments/assets/a3832f92-d53c-413a-be28-e1918da79e0f" />


Klikamy w Certificates, gdzie zobaczymy jedynie przycisk do utworzenia nowego certyfikatu. Wrócimy do tego później.

#### Serwis DNS

Do certyfikatu będziemy potrzebowali domeny i serwisu DNS. Jedną z (wielu!) darmowych opcji jest Dynu: [link](https://www.dynu.com/).
Polecam założyć konto i zalogować się. Wtedy na ekranie startowym w prawym górnym rogu klikamy na koła zębate i zobaczymy ten ekran:

<img width="1527" height="726" alt="image" src="https://github.com/user-attachments/assets/05872d20-a191-44e2-ac09-ccf4658e3bb2" />


Wchodzimy w *DDNS Services* i po prawej strone klikamy *+Add*, a później wybieramy nazwę domeny i rozszerzenie z tego co jest dostępne:

<img width="1456" height="405" alt="image" src="https://github.com/user-attachments/assets/dc55c490-e5e1-4286-bf36-08e375df94c9" />

Klikamy *+Add* i w kolejnym kroku w polu IP wpisujemy lokalny adres naszego serwera, a później *Save*:

<img width="807" height="602" alt="image" src="https://github.com/user-attachments/assets/a0060817-b155-490f-9738-35bd3962dc33" />

Wracając na ekran *DDNS Services* powinniśmy zobaczyć nasz adres:

<img width="1484" height="382" alt="image" src="https://github.com/user-attachments/assets/53507083-e72d-450e-95ec-92a95bc5fcdb" />

Teraz wracamy na ekran usług (kliknij w koła zębate w rogu strony) i wybieramy *API Credentials*. Jeśli nie mamy wygenerowanego klucza api, to 
generujemy je przyciskiem *Generate API Credentials*. Później podglądamy wartość API Key i ją kopiujemy.

<img width="1467" height="752" alt="image" src="https://github.com/user-attachments/assets/f12c53c6-fb2d-4fff-b824-af1689703f14" />

#### Utworzenie certyfikatu

Wracamy na stronę certyfikatów e Nginx, klikamy *Add certificate* i wybieramy opcję *Let's Encrypt via DNS*:

<img width="1075" height="600" alt="image" src="https://github.com/user-attachments/assets/ad57c2a9-df70-4de9-8d1b-357028fce4a7" />

Wpowadzamy tam adres naszej domeny, wybieramy providera Dynu i wklejamy klucz API, który skopiowaliśmy wcześniej. Następnie klikamy *Save* i czekamy cierpliwie na
efekt (to może zająć nawet ponad minutę):

<img width="527" height="823" alt="image" src="https://github.com/user-attachments/assets/4e25a105-a29b-4113-a208-41a742ccc7b6" />

Gdy operacja się zakończy powinniśmy zobaczyć nowy certyfikat:

<img width="923" height="350" alt="image" src="https://github.com/user-attachments/assets/49d86fb0-2a2e-4b49-823b-10539b1f7612" />

W razie problemów zobacz sekcję na końcu tego pliku / strony.

#### Tworzenie proxy host

Kiedy mamy już certyfikat możemy stworzyć przekierowanie adresu domenowego na ip naszego serwera z odpowiednim portem i certyfikatem. Przechodzimy
w nginx do *Dashboard* a później *Proxy Hosts* i klikamy *Add proxy host*, wypełniając pola jak poniżej:

<img width="1048" height="634" alt="image" src="https://github.com/user-attachments/assets/82bcb819-eb1a-4d34-9ade-ca33a1751af7" />

Teraz możemy wykorzystać proxy, żeby zobaczyć efekt. Poniżej strona z adresem bezpośrednim przez IP (zwróć uwagę że jest *Not secure*):

<img width="1077" height="442" alt="image" src="https://github.com/user-attachments/assets/0c493977-4d14-4bea-a2a5-44df7b66410c" />

A gdy wpiszemy w adres nasz nowo utworzony adres proxy efekt jest następujący (secure i nie ma już adresu ip):

<img width="1225" height="532" alt="image" src="https://github.com/user-attachments/assets/85d848ef-c5ca-4e89-b35c-f6cfa3575381" />

Możemy ustawić teraz proxy dla portainer:

<img width="1365" height="832" alt="image" src="https://github.com/user-attachments/assets/beeca8a3-7a5d-4115-81f3-8f497498b767" />
<img width="1382" height="627" alt="image" src="https://github.com/user-attachments/assets/2257972c-3c7e-40e7-a63d-0ac91e19dd47" />

---

### 4. Uwagi

#### Dostępność domen w internecie

Istotne jest to, że te przekierowania proxy będą działać wyłącznie w sieci lokalnej. Na zewnątrz te domeny nie są dostępne! 
Ktokolwiek wpisze adres w swoim komputerze w innej sieci zostanie po prostu przekierowany na adres 192.168.0.141 w sieci, w której aktualnie się znajduje
i najprawdopodobniej dostanie błąd o nieistniejącej stronie. W tej konfiguracji NIE wychodzimy poza sieć lokalną i nic nie udostępniamy w internecie!

#### Konfiguracje kontenerów

Od teraz przy każdym nowym kontenerze, który ma interfejs webowy możesz ustawić proxy hosta, który pozwoli uruchamiać UI wpisując adres Twojej domeny, np.
*moj-kontener.super-server.mytunnel.org*

#### Problemy

W trakcie generowania certyfikatu mogą się pojawić błędy:
- upewnij się żę nie ma spacji w okienku z kluczem *dns_dynu_auth_token = YOUR_DYNU_AUTH_TOKEN* - usuń spacje przy znaku *=*
- Internal Server Error - prawdopodobnie za dużo osób już wysłało request o certyfikat do rozszerzenia domeny, którą wybrałeś (np. mytunnel.org) i możliwe, że będziesz musiał wybrać inną
- Timeout - odpowiedź nie nadeszła lub wyskoczył błąd - trzeba próbować ponownie i ustawić wartość liczbową w ostatnim polu na więcej niż 120
- Ładowanie w nieskończoność - zwróć uwagę na to czy w tle okienka nie pojawił się już certyfikat, czasami okienko się blokuje i nie znika, mimo że operacja już zakończyła się sukcesem







