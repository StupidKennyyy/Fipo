# Fipo

**Fipo** on Docker Compose'i abil loodud konteineripõhine ettevõtte IT-infrastruktuuri simulatsioon. Projekti eesmärk on luua väike virtuaalne ettevõtte võrk, kus erinevaid Linuxi süsteeme saab keskselt hallata, monitoorida ja turvalisemaks muuta.

Projekt on loodud õppeotstarbel ning keskendub süsteemihaldusele, võrguarhitektuurile ja küberturvalisusele.

## Eesmärgid

- Luua mitmest Linuxi süsteemist koosnev ettevõtte IT-infrastruktuur.
- Jagada seadmed eraldatud võrgutsoonidesse.
- Võimaldada keskset süsteemihaldust Ansible'i abil.
- Rakendada SSH-võtmepõhist autentimist.
- Koguda süsteemide kohta infot ja jälgida nende turvalisust.
- Rakendada konfiguratsioonihaldust, monitooringut ja varundamist.

## Infrastruktuur

Projekt koosneb kaheksast Linuxi konteinerist:

| Konteiner | Operatsioonisüsteem | Roll |
|---|---|---|
| `hq-controller` | Ubuntu 24.04 | Keskne haldusserver |
| `backup-vault` | Debian 12 | Varukoopiate server |
| `ws-dev-01` | Ubuntu 24.04 | Arendaja tööjaam |
| `ws-fin-01` | Ubuntu 24.04 | Finantsosakonna tööjaam |
| `srv-app-01` | Rocky Linux 9 | Rakendusserver |
| `kiosk-lobby` | Debian 12 | Avalik infokiosk |
| `iot-sensor-1` | Alpine Linux | IoT-andur |
| `iot-cam-1` | Debian | IoT-kaamera |

### Võrguarhitektuur

Seadmed on jaotatud kolme Docker-võrku:

| Võrk | Alamvõrk | Eesmärk |
|---|---|---|
| `mgmt_net` | `172.30.10.0/24` | Haldusvõrk |
| `corp_net` | `172.30.20.0/24` | Ettevõtte sisevõrk |
| `dmz_iot` | `172.30.30.0/24` | DMZ ja IoT-seadmed |

Täpsemat võrguarhitektuuri kirjeldab [ARCHITECTURE.md](ARCHITECTURE.md).

## Kasutatavad tehnoloogiad

- **Docker Compose** – konteinerite ja võrkude haldamine.
- **Ansible** – süsteemide keskne konfiguratsioonihaldus.
- **OpenSSH** – turvaline ühendus hallatavate masinatega.
- **Nginx** – CMDB veebiliidese teenindamine.
- **osquery** – süsteemide info kogumine ja turvaseire.

## Projekti struktuur

```text
Fipo/
├── cmdb-dashboard/    # CMDB veebiliides
├── playbooks/         # Ansible playbook'id
├── scripts/           # Abiskriptid
├── ssh/               # SSH seadistamise skriptid
├── docker-compose.yml # Infrastruktuuri konfiguratsioon
├── hosts.ini          # Ansible inventar
├── ARCHITECTURE.md    # Süsteemi arhitektuur
└── README.md          # Projekti dokumentatsioon
```

## Paigaldamine ja käivitamine

### Eeltingimused

Enne projekti käivitamist peavad olema paigaldatud:

- Docker
- Docker Compose v2

### Projekti allalaadimine

```bash
git clone https://github.com/StupidKennyyy/Fipo.git
cd Fipo
```

### Konteinerite käivitamine

```bash
docker compose up -d
```

Konteinerite oleku kontrollimiseks:

```bash
docker compose ps -a
```

### Logide vaatamine

Kõigi konteinerite logide reaalajas jälgimiseks:

```bash
docker compose logs -f --tail=100
```

## Kasulikud käsud

| Käsk | Kirjeldus |
|---|---|
| `docker compose up -d` | Käivitab konteinerid |
| `docker compose down` | Peatab ja eemaldab konteinerid |
| `docker compose ps -a` | Näitab kõigi konteinerite olekut |
| `docker compose logs -f` | Jälgib logisid reaalajas |
| `docker compose restart` | Taaskäivitab konteinerid |

### Halduskontrollerisse sisenemine

```bash
docker compose exec hq-controller bash
```

### Ansible ühenduste testimine

```bash
docker compose exec hq-controller ansible all -m ping
```

### Ansible playbook'i käsitsi käivitamine

```bash
docker compose exec hq-controller \
  ansible-playbook /opt/fipo/playbooks/01-setup.yml
```

## Arenduse hetkeseis

Projekt on aktiivses arenduses. Praeguseks on loodud konteineripõhine infrastruktuur, seadistatud võrgud ning toimiv SSH-ühendus keskse kontrolleri ja hallatavate masinate vahel.

Järgmised arendusetapid keskenduvad:
- osquery agentide paigaldamisele ja seadistamisele.
- CMDB veebiliidese arendamisele.
- Süsteemide turvalisuse tugevdamisele.
- Failide tervikluse jälgimisele.
- Automaatsele varundamisele ja taastamisele.
- Turvaintsidentide simuleerimisele ja lahendamisele.

## Dokumentatsioon

- [ARCHITECTURE.md](ARCHITECTURE.md) – infrastruktuuri ja süsteemi arhitektuur.
- [INCIDENT_REPORT.md](INCIDENT_REPORT.md) – turvaintsidentide kirjeldused ja lahendused (lisatakse hiljem).

## Autor

Projekt on loodud õppeotstarbelise IT-infrastruktuuri ja küberturvalisuse harjutusena.