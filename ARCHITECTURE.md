Projektis on docker-compose fail, milles on 8 erinevat docker image-t.



1\. on hq-controller mis peaks hoidma ssh võtmeid ja Nginx serverit monitooringuga.



2\. on backup-vault, mis on isoleeritud varundusserver, kus on klientseadmete krüpteeritud varukoopiad.



3\. on ws-dev-01, mis on siis arendaja tööjaam koos git, python3, vim, htop ja sudo õigustega.



4\. on ws-fin-01, mis hoiab tundlikke finantsdokumente jne.



5\. on srv-app-01 RedHat-põhine siseserver, mis näitab õpilase oskust hallata dnf/rpm paketihalduriga süsteemi.



6\. on kiosk-lobby infokioski lukustatud kasutajaprofiil, sudo keelatud, lubatud ainult kindlad võrguühendused.



7\. on iot-sensor-1, mis on ülikerge apk paketihalduriga tehaseandur, mis genereerib iga minuti järel logifaili /var/log/sensor.log temperatuurinäite.



8\. on iot-cam-1, mis sisaldab IP-kaamera simulaatorit, millel on teadlikult jäetud alguses nõrk konfiguratsioon, mis oleks vaja karastada.

