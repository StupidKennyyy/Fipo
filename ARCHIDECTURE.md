# Fipo – Süsteemi arhitektuur

## 1. Projekti ülevaade

Fipo on Docker Compose'i abil loodud konteineripõhine ettevõtte IT-infrastruktuuri labor. Projekt simuleerib väikese ettevõtte sisevõrku, mis koosneb tööjaamadest, serveritest, IoT-seadmetest ja kesksest haldussüsteemist.

Infrastruktuur koosneb kaheksast Linuxi konteinerist, mis on jaotatud kolme eraldatud Docker-võrgu vahel. Keskne haldusserver `hq-controller` vastutab teiste masinate haldamise eest Ansible'i ja SSH kaudu.

Projekti peamised eesmärgid:

- Ettevõtte sisevõrgu keskkonna simuleerimine.
    
- Seadmete eraldamine erinevatesse võrgutsoonidesse.
    
- Keskse halduse võimaldamine Ansible'i abil.
    
- SSH-võtmepõhise autentimise seadistamine kontrolleri ja hallatavate masinate vahel.
    
- Aluse loomine kesksele monitooringule, konfiguratsioonihaldusele ja turvalisuse tugevdamisele.
    

## 2. Infrastruktuuri ülevaade

Keskkond koosneb kaheksast konteinerist:

|Konteiner|Operatsioonisüsteem|Roll|
|---|---|---|
|`hq-controller`|Ubuntu 24.04|Keskne haldusserver|
|`backup-vault`|Debian 12|Varukoopiate salvestusserver|
|`ws-dev-01`|Ubuntu 24.04|Arendaja tööjaam|
|`ws-fin-01`|Ubuntu 24.04|Finantsosakonna tööjaam|
|`srv-app-01`|Rocky Linux 9|Rakendusserver|
|`kiosk-lobby`|Debian 12|Avalik infokiosk|
|`iot-sensor-1`|Alpine Linux|IoT-andur|
|`iot-cam-1`|Debian|IoT-kaamera|

Iga konteiner esindab eraldiseisvat masinat simuleeritud ettevõtte infrastruktuuris.

## 3. Võrguarhitektuur

Infrastruktuur kasutab kolme Docker Bridge-võrku, et eraldada seadmed vastavalt nende rollidele.

|Võrk|Alamvõrk|Eesmärk|
|---|---|---|
|`mgmt_net`|`172.30.10.0/24`|Haldusinfrastruktuur|
|`corp_net`|`172.30.20.0/24`|Ettevõtte tööjaamad ja serverid|
|`dmz_iot`|`172.30.30.0/24`|Avalikud seadmed ja IoT-seadmed|

### 3.1 Haldusvõrk (mgmt_net)

Haldusvõrk sisaldab keskset kontrollerit ja varukoopiate serverit.

|Konteiner|IP-aadress|
|---|---|
|`hq-controller`|`172.30.10.10`|
|`backup-vault`|`172.30.10.20`|

Kontroller kasutab seda võrku haldusinfrastruktuuriga suhtlemiseks.

### 3.2 Ettevõtte sisevõrk (corp_net)

Ettevõtte sisevõrk sisaldab töötajate tööjaamu ja rakendusserverit.

|Konteiner|IP-aadress|
|---|---|
|`hq-controller`|`172.30.20.5`|
|`ws-dev-01`|`172.30.20.10`|
|`ws-fin-01`|`172.30.20.11`|
|`srv-app-01`|`172.30.20.20`|

### 3.3 DMZ- ja IoT-võrk (dmz_iot)

DMZ-võrk sisaldab seadmeid, mis peavad olema ettevõtte sisevõrgust eraldatud.

|Konteiner|IP-aadress|
|---|---|
|`hq-controller`|`172.30.30.5`|
|`kiosk-lobby`|`172.30.30.10`|
|`iot-sensor-1`|`172.30.30.20`|
|`iot-cam-1`|Määratakse Docker Compose'i kaudu|

Kontroller on ühendatud kõigi kolme võrguga, võimaldades hallata seadmeid kogu infrastruktuuris.

Kiosk ja IoT-seadmed on ühendatud ainult DMZ-võrguga. Need ei tohiks omada otsest ligipääsu tundlikele ettevõtte sisevõrgu masinatele ega varukoopiate serverile.

## 4. Keskne haldus – Ansible

Ansible on paigaldatud `hq-controller` konteinerisse ning seda kasutatakse teiste konteinerite kaugjuhtimiseks ja haldamiseks.

Ansible'i inventar asub failis `hosts.ini`, kus on määratletud hallatavad masinad ja nende grupid.

Inventar on jaotatud järgmisteks loogilisteks gruppideks:

- `workstations` – ettevõtte töötajate tööjaamad.
    
- `servers` – rakendus- ja haldusserverid.
    
- `kiosks` – avalik infokiosk.
    
- `iot` – IoT-seadmed.
    
- `vault` – varukoopiate salvestusserver.
    

Ansible suhtleb hallatavate masinatega SSH-protokolli kaudu.

Ühenduste toimivust on testitud Ansible'i `ping` mooduliga. Kõik kaheksa hosti, sealhulgas kontroller ise, tagastasid edukalt vastuse `pong`.

## 5. SSH-autentimine

Infrastruktuuris kasutatakse paroolipõhise autentimise asemel SSH avaliku võtme põhist autentimist.

SSH-võtmepaar genereeritakse `hq-controller` konteineris, kasutades Ed25519 algoritmi.

- Privaatvõti jääb ainult `hq-controller` konteinerisse.
    
- Avalik võti jagatakse hallatavatele konteineritele.
    
- Hallatavad masinad lisavad kontrolleri avaliku võtme oma `authorized_keys` faili.
    
- SSH paroolipõhine autentimine on keelatud.
    

Avaliku võtme jagamiseks kasutatakse Docker Compose'i ühist köidet nimega `ssh_exchange`.

Konteinerite käivitamisel kasutatakse SSH initsialiseerimisskripti, mis asub projekti `ssh/` kataloogis ja ühendatakse konteineritega Docker Compose'i kaudu.

Selline lahendus võimaldab Ansible'il luua ühendusi hallatavate masinatega ilma paroole sisestamata.

## 6. Automaatne käivitamine ja Ansible'i seadistamine

Ansible'i playbook'ide automaatseks käivitamiseks kasutatakse eraldi käivitusskripti. See võimaldab rakendada infrastruktuuri konfiguratsiooni ilma, et administraator peaks iga playbook'i käsitsi käivitama.

### 6.1 Playbook'ide ühendamine

Projekti `playbooks/` kataloog ühendatakse Docker Compose'i kaudu otse `hq-controller` konteineriga.

Kataloog ühendatakse asukohta:

`/opt/fipo/playbooks`

Tänu sellele on kõik projektis olevad playbook'id kontrollerile kättesaadavad ning nende muutmiseks ei ole vaja faile konteinerisse käsitsi kopeerida.

### 6.2 Automaatne käivitusskript

Playbook'ide käivitamiseks kasutatakse eraldi skripti `run-playbooks.sh`.

Skript:

- Otsib `playbooks/` kataloogist numbrilise prefiksiga YAML-faile.
    
- Käivitab leitud playbook'id järjekorras.
    
- Kasutab Ansible'i inventarifaili `/etc/ansible/hosts`.
    
- Peatab käivitamise vea korral, et vältida järgmiste playbook'ide käivitamist ebaõnnestunud seadistuse järel.
    

Playbook'ide nimedes kasutatakse numbrilisi prefikseid, näiteks `01-setup.yml`, `02-osquery.yml` ja `03-hardening.yml`. See aitab määrata nende käivitamise järjekorda.

### 6.3 Käivitamise järjekord

Automaatne seadistamine toimub pärast konteinerite käivitamist järgmises järjekorras:

1. `hq-controller` käivitub ja kontrollib SSH-võtmepaari olemasolu.
    
2. Kontrolleri avalik SSH-võti jagatakse teistele konteineritele.
    
3. Käivitatakse kontrolleri SSH-server.
    
4. Kontroller kontrollib hallatavate masinate SSH-ühenduste toimivust.
    
5. Pärast hallatavate masinate kättesaadavaks muutumist käivitatakse Ansible'i playbook'id.
    
6. Playbook'id täidetakse määratud järjekorras.
    
7. Pärast seadistamise lõpetamist jääb kontroller tööle ning SSH-server jätkab töötamist.
    

Hostide kättesaadavuse kontrollimiseks kasutatakse SSH-ühenduse loomise katseid. Kui mõni host ei muutu kuue minuti jooksul kättesaadavaks, katkestatakse automaatne seadistamine veateatega.

Automaatse käivitamise eesmärk on tagada, et konfiguratsiooni rakendamine toimuks alles pärast seda, kui vajalikud masinad on valmis.