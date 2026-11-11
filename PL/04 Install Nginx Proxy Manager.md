## Instalacja Nginx Proxy Manager

### 1. Plik compose

Poniżej znajduje się plik Docker Compose służący do utworzenia i uruchomienia Nginx Proxy Managera:
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

Przed uruchomieniem pliku tworzymy katalog *nginx-pm* wewnątrz katalogu *docker*, utworzonego podczas konfiguracji Dockera. Upewniamy się, że znajdujemy się w katalogu */home/USER*:
```
cd docker
mkdir nginx-pm
mkdir nginx-pm/data
mkdir nginx-pm/letsencrypt
cd nginx-pm
touch docker-compose.yml
```
Wklejamy zawartość pliku Compose do *docker-compose.yml*. Kopiujemy powyższy kod, a następnie uruchamiamy:
```
nano docker-compose.yml
Ctrl+Shift+V -> wklej tekst
Zmień USER na swoją nazwę użytkownika, np. bk
Ctrl+O -> zapisz plik
Enter -> potwierdź zapis
Ctrl+X -> zamknij plik
```
---


### 2. Utworzenie kontenera

Teraz uruchamiamy polecenie, będąc w katalogu */home/USER/docker/nginx-pm*:
```
sudo docker compose up -d
```
---

### 3. Konfiguracja

Otwieramy przeglądarkę i wpisujemy adres serwera z portem 81. Powinien wyświetlić się ekran tworzenia konta administratora:

<img width="806" height="767" alt="Nginx Proxy Manager admin account setup" src="../assets/images/nginx-proxy-manager-admin-setup.png" />


Po utworzeniu konta administratora zobaczymy następujący ekran:

<img width="1172" height="391" alt="Nginx Proxy Manager dashboard" src="../assets/images/nginx-proxy-manager-dashboard.png" />


Klikamy *Certificates*. Zobaczymy tam przycisk umożliwiający utworzenie nowego certyfikatu. Wrócimy do tego później.

#### Serwis DNS

Do utworzenia certyfikatu potrzebujemy domeny i usługi DNS. Jedną z wielu darmowych opcji jest Dynu ([strona Dynu](https://www.dynu.com/)).
Zakładamy konto i logujemy się. Następnie na ekranie startowym klikamy ikonę koła zębatego w prawym górnym rogu. Powinien wyświetlić się ten ekran:

<img width="1527" height="726" alt="Dynu account settings" src="../assets/images/dynu-account-settings.png" />


Otwieramy *DDNS Services* i klikamy *+Add* po prawej stronie. Następnie wybieramy dostępną nazwę domeny i jej rozszerzenie:

<img width="1456" height="405" alt="Dynu add DDNS domain screen" src="../assets/images/dynu-add-ddns-domain.png" />

Klikamy *+Add*. W kolejnym kroku wpisujemy lokalny adres IP serwera w polu *IP*, a następnie klikamy *Save*:

<img width="807" height="602" alt="Dynu DDNS local IP address configuration" src="../assets/images/dynu-ddns-ip-address.png" />

Po powrocie do ekranu *DDNS Services* powinniśmy zobaczyć utworzony adres:

<img width="1484" height="382" alt="Dynu DDNS services list" src="../assets/images/dynu-ddns-service-list.png" />

Wracamy do ekranu usług, klikamy ikonę koła zębatego w rogu strony i wybieramy *API Credentials*. Jeśli nie mamy jeszcze klucza API, generujemy go przyciskiem *Generate API Credentials*. Następnie wyświetlamy wartość *API Key* i kopiujemy ją.

<img width="1467" height="752" alt="Dynu API credentials" src="../assets/images/dynu-api-credentials.png" />

#### Utworzenie certyfikatu

Wracamy do strony certyfikatów w Nginx Proxy Managerze, klikamy *Add certificate* i wybieramy opcję *Let's Encrypt via DNS*:

<img width="1075" height="600" alt="Nginx Proxy Manager add DNS certificate screen" src="../assets/images/nginx-proxy-manager-add-dns-certificate.png" />

Wpisujemy adres domeny, wybieramy dostawcę Dynu i wklejamy wcześniej skopiowany klucz API. Następnie klikamy *Save* i czekamy na wynik. Może to potrwać ponad minutę:

<img width="527" height="823" alt="Let's Encrypt DNS certificate request using Dynu" src="../assets/images/letsencrypt-dynu-certificate-request.png" />

Po zakończeniu operacji powinniśmy zobaczyć nowy certyfikat:

<img width="923" height="350" alt="Nginx Proxy Manager certificate list" src="../assets/images/letsencrypt-certificate-list.png" />

W razie problemów zajrzyj do sekcji na końcu tego dokumentu.

#### Tworzenie proxy host

Po uzyskaniu certyfikatu możemy skonfigurować przekierowanie z domeny na adres IP serwera i odpowiedni port. W Nginx Proxy Managerze przechodzimy do *Dashboard*, a następnie do *Proxy Hosts*. Klikamy *Add proxy host* i wypełniamy pola jak na zrzucie:

<img width="1048" height="634" alt="Nginx Proxy Manager add proxy host configuration" src="../assets/images/nginx-proxy-manager-add-proxy-host.png" />

Teraz możemy sprawdzić działanie proxy. Poniżej widoczna jest strona otwarta bezpośrednio przez adres IP (zwróć uwagę na komunikat *Not secure*):

<img width="1077" height="442" alt="Website accessed directly by IP without HTTPS" src="../assets/images/nginx-proxy-manager-ip-access-warning.png" />

Po wpisaniu nowo utworzonego adresu proxy strona wygląda następująco: połączenie jest bezpieczne, a adres IP nie jest widoczny w pasku adresu.

<img width="1225" height="532" alt="Website accessed through a secure proxy domain" src="../assets/images/nginx-proxy-manager-secure-domain-access.png" />

Teraz możemy skonfigurować proxy dla Portainera:

<img width="1365" height="832" alt="Portainer proxy host configuration" src="../assets/images/portainer-proxy-host-configuration.png" />
<img width="1382" height="627" alt="Portainer accessed through a secure domain" src="../assets/images/portainer-secure-domain-access.png" />

---

### 4. Uwagi

#### Dostępność domen w internecie

Te przekierowania proxy działają wyłącznie w sieci lokalnej, więc domeny nie są dostępne z zewnątrz. Osoba, która wpisze taki adres na komputerze podłączonym do innej sieci, zostanie skierowana na adres `192.168.0.141` w swojej sieci i najprawdopodobniej zobaczy błąd informujący, że strona nie istnieje. W tej konfiguracji nie udostępniamy usług poza siecią lokalną ani w internecie.

#### Konfiguracja proxy dla kontenerów

Dla każdego nowego kontenera z interfejsem webowym możemy skonfigurować proxy hosta. Dzięki temu jego interfejs otworzymy pod adresem domenowym, np. *moj-kontener.super-server.mytunnel.org*.

#### Problemy

Podczas generowania certyfikatu mogą wystąpić następujące problemy:
- **Brak certyfikatu:** upewnij się, że w polu z kluczem `dns_dynu_auth_token=YOUR_DYNU_AUTH_TOKEN` nie ma zbędnych spacji, szczególnie wokół znaku `=`.
- **Internal Server Error:** prawdopodobnie osiągnięto limit żądań certyfikatu dla wybranego rozszerzenia domeny (np. `mytunnel.org`). Spróbuj wybrać inną domenę.
- **Timeout:** upłynął limit czasu oczekiwania na odpowiedź albo wystąpił błąd. Spróbuj ponownie i ustaw w ostatnim polu wartość większą niż 120.
- **Niekończące się ładowanie:** sprawdź, czy certyfikat nie pojawił się już w tle okna. Czasami okno zawiesza się i nie znika, mimo że operacja zakończyła się powodzeniem.







