## Instalacja Ubuntu Server – wersja podstawowa

### 0. Nawigacja

Nawigacja w instalatorze: strzałki ↑ ↓ – poruszanie się, **Enter** – zatwierdzenie, **Spacja** – zaznaczanie opcji, **Tab** – przejście między polami. Na końcu każdego ekranu wybieramy **Done** (lub **Continue**), aby przejść dalej.


### 1. Menu startowe GRUB

Po uruchomieniu komputera z nośnika (pendrive / ISO) pojawia się menu GRUB. Wybieramy domyślną pozycję **Try or Install Ubuntu Server** i zatwierdzamy Enterem.

<img width="675" height="369" alt="01 grub" src="https://github.com/user-attachments/assets/8d94fbd5-e104-41ea-8912-e023d3f25d61" />

---

### 2. Wybór języka

Wybieramy **English (UK)**. Dzięki temu format daty i godziny jest zbliżony do polskiego (dzień/miesiąc/rok, 24-godzinny zegar), a system pozostaje w języku angielskim, co ułatwia szukanie rozwiązań problemów w internecie.

<img width="1274" height="330" alt="02 language" src="https://github.com/user-attachments/assets/32ceaed3-0476-4e75-84d5-33ba9ff62f61" />

---

### 3. Układ klawiatury

- **Layout:** Polish
- **Variant:** Polish

Bez żadnych dodatkowych opcji – standardowa klawiatura polska (programisty). 

<img width="1272" height="271" alt="03 keyboard" src="https://github.com/user-attachments/assets/a29f7ce6-adf5-468f-9102-ac71780bc3d2" />

---

### 4. Typ instalacji

Wybieramy **Ubuntu Server** (zwykła wersja, **nie** *minimized*). Opcję *Search for third-party drivers* zostawiamy niezaznaczoną.

<img width="1272" height="414" alt="04 base installation" src="https://github.com/user-attachments/assets/3f0246fb-5315-4c5c-a5e2-a0a9c38e42de" />

---

### 5. Konfiguracja sieci

#### Kabel Ethernet

Jeśli kabel jest podpięty, sieć powinna zostać wykryta automatycznie, a interfejs (np. `enp1s0`) otrzyma adres IP z DHCP (na zrzucie: `192.168.122.195/24`).

<img width="1272" height="312" alt="05 network" src="https://github.com/user-attachments/assets/ffa3fbd6-9b30-465e-b2b5-f580c1aaaf77" />

#### Wi-Fi

Jeśli komputer ma kartę Wi-Fi, można ją skonfigurować przez **Edit Wi-Fi**:

1. Wybieramy **Choose a visible network** i wskazujemy sieć (lub wpisujemy nazwę ręcznie w polu *Network Name*).
2. Wpisujemy hasło w polu *Password*.
3. Zatwierdzamy przyciskiem **Save**.
4. **Przed przejściem dalej czekamy, aż połączenie zostanie nawiązane i interfejs dostanie adres IP.**

<img width="749" height="321" alt="06 wifi" src="https://github.com/user-attachments/assets/32df1f39-6673-4009-941c-615aa9cb22e0" />

#### Adres IP

Na razie zostawiamy **automatyczne nadawanie adresu (DHCP)**. Niektóre routery mogą przydzielać za każdym razem inny adres, więc jeśli potrzebny jest **stały adres IP**, można:

- wejść w ekranie sieci w ręczną konfigurację interfejsu (*Edit IPv4* → *Manual*), albo
- zmienić to później w pliku konfiguracyjnym netplan: `/etc/netplan/50-cloud-init.yaml` (nazwa pliku może się nieco różnić), a następnie zastosować zmiany poleceniem `sudo netplan apply`.

Alternatywnie można ustawić rezerwację adresu (DHCP reservation) w routerze.

---

### 6. Proxy

Pole **Proxy address** zostawiamy **puste** (nie korzystamy z proxy).

<img width="1272" height="312" alt="06 proxy" src="https://github.com/user-attachments/assets/3c115796-5318-459d-b14e-23e91d74f9f3" />

---


### 7. Mirror archiwum Ubuntu

Instalator domyślnie proponuje serwer lustrzany zgodny z lokalizacją (np. `http://pl.archive.ubuntu.com/ubuntu/`). Zostawiamy domyślny adres i czekamy na zakończenie testu mirrora (komunikat *The mirror location is being tested*), a następnie przechodzimy dalej.

<img width="1272" height="388" alt="07 mirrors" src="https://github.com/user-attachments/assets/3948068f-d5af-4086-bc9d-1e9d9d00d823" />

---

### 8. Konfiguracja dysku

#### Ekran 1 – wybór dysku

- Wybieramy **Use an entire disk** i wskazujemy dysk przeznaczony na system (na zrzucie `/dev/vda`, 25 GB).
- Zaznaczamy **Set up this disk as an LVM group** jeśli chcemy dynamiczne przydzielanie miejsca dla partycji dysków, jeśli nie to można odznaczyć. Poniżej jest wyjaśniony każdy wariant.
- **Nie zaznaczamy** *Encrypt the LVM group with LUKS*.

> **Dlaczego bez szyfrowania?** Przy szyfrowaniu dysku hasło trzeba by wpisywać przy każdym uruchomieniu serwera. Automatyzacja tego przez SSH w initramfs jest skomplikowana, więc dla prostego serwera rezygnujemy z szyfrowania.

**Uwaga:** instalacja **nadpisuje cały wybrany dysk** – wszystkie dane na nim zostaną utracone.

<img width="1272" height="500" alt="08 disk" src="https://github.com/user-attachments/assets/0cc083eb-cfdd-44c9-9b70-9df51d235ff5" />

#### Ekran 2 – podsumowanie układu
#### Wariant z LVM (wybierz jeśli chcesz elastyczność w zmienianiu rozmiarów partycji)

Instalator pokazuje proponowany podział dysku:
 
| Punkt montowania | Rozmiar | Typ | Urządzenie |
|---|---|---|---|
| `/` | ok. 11,5 GB | ext4 | LVM Logical Volume (`ubuntu-lv`) |
| `/boot` | 2 GB | ext4 | partycja dysku |
| – | 1 MB | BIOS grub spacer | partycja 1 |
 
> **Wskazówka:** domyślnie instalator przydziela woluminowi `/` tylko część grupy wolumenów `ubuntu-vg` – reszta (na zrzucie ok. 11,5 GB) pozostaje jako *free space*. Można ją wykorzystać od razu (edytując `ubuntu-lv` i ustawiając maksymalny rozmiar) albo później, rozszerzając wolumen poleceniami:
>
> ```bash
> sudo lvextend -r -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
> ```
 
<img width="1272" height="609" alt="09 disk2" src="https://github.com/user-attachments/assets/b1b92314-8f41-4fda-ad11-ccefbbb00335" />
 
#### Wariant bez LVM (wybierz jeśli chcesz maksymalną prostotę i nie będziesz potrzebować nigdy zmian)
 
Jeśli na pierwszym ekranie **odznaczymy** opcję *Set up this disk as an LVM group*, instalator zaproponuje prostszy układ, bez woluminów logicznych:
 
| Punkt montowania | Rozmiar | Typ | Urządzenie |
|---|---|---|---|
| `/` | ok. 25 GB (cały dysk) | ext4 | zwykła partycja dysku (partycja 2) |
| – | 1 MB | BIOS grub spacer | partycja 1 |
 
Różnice w stosunku do wariantu z LVM:
 
- cały dostępny dysk jest przeznaczony na `/` – nie zostaje wolne miejsce w grupie wolumenów (w *AVAILABLE DEVICES* widnieje *No available devices*),
- nie ma osobnej partycji `/boot` ani grupy `ubuntu-vg`,
- układ jest prostszy, ale późniejsza zmiana rozmiarów, dodawanie dysków do jednej przestrzeni czy snapshoty są mniej wygodne niż w LVM.
> **Uwaga:** na komputerach z UEFI (a nie z klasycznym BIOS-em, jak na zrzucie) instalator doda dodatkowo niewielką partycję EFI (`/boot/efi`).
 
<img width="1581" height="466" alt="08b disk" src="https://github.com/user-attachments/assets/25a53b64-dfb6-436b-ac67-72ca7be187dd" />

#### Nie wiesz co wybrać? 
Ze swojej strony mógłbym polecić na początek wybór z LVM i od razu przypisać 100% wolnego miejsca do `/`. Żeby to zrobić wciskamy spację na linii z `ubutnu-lv`, 
później `Edit` i w polu `Size` wpisujemy maksymalną wartość, a później `Save`.  

<img width="1582" height="698" alt="lvm-setup" src="https://github.com/user-attachments/assets/7ea75593-a058-4ac0-9457-fbfe53b5cb97" />


---

### 9. Profil użytkownika

Uzupełniamy dane:

| Pole | Opis | Przykład |
|---|---|---|
| **Your name** | Imię / nazwa użytkownika | `bk` |
| **Your servers name** | Nazwa serwera (hostname) widoczna w sieci | `bk-server` |
| **Pick a username** | Login użytkownika | `bk` |

Hasło jest potrzebne także do wykonywania poleceń przez `sudo`, nawet gdy później logujemy się przez SSH.

<img width="1272" height="417" alt="10 user setup" src="https://github.com/user-attachments/assets/9ffd0d0f-19d4-4682-aac8-5144236365ac" />

---

### 10. Ubuntu Pro

Wybieramy **Skip for now** – nie aktywujemy Ubuntu Pro. W razie potrzeby można to zrobić później poleceniem `pro attach`.

<img width="1272" height="298" alt="11 pro skip" src="https://github.com/user-attachments/assets/d519dd61-5c84-4614-a324-03da07909eb1" />

---

### 11. Konfiguracja SSH

Zaznaczamy **Install OpenSSH server**, aby można było łączyć się z serwerem zdalnie.

- *Allow password authentication over SSH* – pozostaje zaznaczone (logowanie hasłem).
- *Import SSH key* – opcjonalnie; jeśli nie importujemy klucza, zostawiamy bez zmian (*No authorized key*).

Połączenie z innego komputera:

```bash
ssh bk@<adres-ip-serwera>
```

<img width="1272" height="338" alt="12 ssh" src="https://github.com/user-attachments/assets/fd010afb-5ada-403c-9b24-4cc2f3341eba" />

---

### 12. Dodatkowe pakiety (Featured server snaps)

Nie zaznaczamy żadnego pakietu – instalujemy tylko podstawowy system. Przechodzimy dalej przyciskiem **Done**. Wszystko, co potrzebne, można doinstalować później.

<img width="1272" height="456" alt="13 extras" src="https://github.com/user-attachments/assets/4857838b-7bc2-4fc1-a541-ed2f975eb4db" />

---

### 13. Zakończenie

Po zatwierdzeniu ostatniego ekranu rozpocznie się właściwa instalacja. Gdy się zakończy (pojawi się przycisk **Reboot Now**):

1. Wybieramy **Reboot Now**.
2. Po wyświetleniu komunikatu usuwamy nośnik instalacyjny i naciskamy Enter.
3. Po restarcie logujemy się utworzonym użytkownikiem.

Adres IP serwera można sprawdzić poleceniem:

```bash
ip a
```

---

### 14. Aktualizacje

Na koniec dobrze jeszcze zaktualizować system zanim przejdziemy do instalacji różnych programów.
```
sudo apt update
sudo apt upgrade -y
```
