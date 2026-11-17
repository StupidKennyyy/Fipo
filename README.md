Projekt on mõeldud lihtsa firma klientseadmete pargi ehitamine, tsentraalne haldus ja küberkaitse (Docker Compose + Ansible + Osquery)



Ülespanemiseks saab kasutada docker-compose (https://docs.docker.com/compose/)



Kasutades docker-compose ehitab see projekti kaustas oleva docker-compose.yml

(Saab kasutada ka lihtsalt docker compose, kui docker-compose ei tööta.)



Eesmärk on katsetada sellise projekti karastust ja vaadata, kas on intsidendi rapordis süsteemi ründajaid.



Compose failis on 8 "pilti", mis peaksid olema siis veebiserveri databaas, databaasi krüpteeritud varukoopiad, tööjaam arendaja jaoks, tundlikke finantsdokumentide databaas, RH siseserver, kliendikiosk, temperatuuri logija ja IP-valvekaamera.



Playbook kaustas peaks olema konfiguratsioonid kõikide "piltide" jaoks.



Ansible on paigaldatud, et kiiresti automatiseerida konfiguratsiooni või varukoopiate tegemist.

