#!/bin/sh
set -eu

SSH_DIR="/root/.ssh"
EXCHANGE_DIR="/ssh-exchange"
CONTROLLER_KEY="$EXCHANGE_DIR/controller.pub"
MANAGED_KEY="$SSH_DIR/.fipo_controller_key"
INVENTORY="/etc/ansible/hosts"

SSH_ATTEMPTS=90
SSH_INTERVAL=2

echo "Seadistan SSH..."

mkdir -p "$SSH_DIR" "$EXCHANGE_DIR" /var/run/sshd
chmod 700 "$SSH_DIR"

# -----------------------------------------
# Kontrolleri võtme genereerimine ja avaldamine
# -----------------------------------------

if [ "${SSH_ROLE:-worker}" = "controller" ]; then
    echo "Kontroller: kontrollin SSH võtmepaari..."

    if [ ! -s "$SSH_DIR/id_ed25519" ]; then
        ssh-keygen -t ed25519 -N "" -f "$SSH_DIR/id_ed25519"
    fi

    ssh-keygen -y -f "$SSH_DIR/id_ed25519" > "$SSH_DIR/id_ed25519.pub.tmp"
    mv "$SSH_DIR/id_ed25519.pub.tmp" "$SSH_DIR/id_ed25519.pub"

    chmod 600 "$SSH_DIR/id_ed25519"
    chmod 644 "$SSH_DIR/id_ed25519.pub"

    cp "$SSH_DIR/id_ed25519.pub" "$CONTROLLER_KEY.tmp"
    mv "$CONTROLLER_KEY.tmp" "$CONTROLLER_KEY"

    touch "$SSH_DIR/controller-ready"

    echo "Kontrolleri avalik võti avaldatud."
else
    echo "Ootan kontrolleri avalikku võtit..."

    attempts=0

    while [ ! -s "$CONTROLLER_KEY" ]; do
        attempts=$((attempts + 1))

        if [ "$attempts" -ge "$SSH_ATTEMPTS" ]; then
            echo "VIGA: Kontrolleri avalikku võtit ei leitud!"
            exit 1
        fi

        sleep "$SSH_INTERVAL"
    done
fi

# -----------------------------------------
# Kontrolleri võtme automaatne sünkroonimine
# -----------------------------------------

echo "Sünkroonin kontrolleri SSH võtit..."

touch "$SSH_DIR/authorized_keys"

NEW_KEY=$(cat "$CONTROLLER_KEY")

if [ -s "$MANAGED_KEY" ]; then
    OLD_KEY=$(cat "$MANAGED_KEY")

    awk -v old="$OLD_KEY" '$0 != old' \
        "$SSH_DIR/authorized_keys" > "$SSH_DIR/authorized_keys.tmp"
else
    # Esmakordsel sünkroonimisel eemalda varasemad
    # selle projekti kontrolleri võtmed.
    awk '$0 !~ / root@hq-controller$/' \
        "$SSH_DIR/authorized_keys" > "$SSH_DIR/authorized_keys.tmp"
fi

printf '%s\n' "$NEW_KEY" >> "$SSH_DIR/authorized_keys.tmp"
mv "$SSH_DIR/authorized_keys.tmp" "$SSH_DIR/authorized_keys"

printf '%s\n' "$NEW_KEY" > "$MANAGED_KEY"

chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys" "$MANAGED_KEY"

# -----------------------------------------
# SSH serveri seadistamine
# -----------------------------------------

echo "Seadistan SSH serverit..."

ssh-keygen -A

cat > /etc/ssh/sshd_config <<'SSH_CONFIG'
Port 22
HostKey /etc/ssh/ssh_host_ed25519_key
PermitRootLogin prohibit-password
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
SSH_CONFIG

/usr/sbin/sshd -t

# -----------------------------------------
# Ansible konfiguratsioon
# -----------------------------------------

if [ "${SSH_ROLE:-worker}" = "controller" ]; then
    echo "Seadistan Ansible'i..."

    mkdir -p /etc/ansible

    cat > /etc/ansible/ansible.cfg <<'ANSIBLE_CONFIG'
[defaults]
inventory = /etc/ansible/hosts
host_key_checking = False
interpreter_python = auto_silent

[ssh_connection]
transfer_method = piped
ANSIBLE_CONFIG

    echo "Ansible konfiguratsioon loodud."
fi

# -----------------------------------------
# Controller
# -----------------------------------------

if [ "${SSH_ROLE:-worker}" = "controller" ]; then
    echo "Käivitan kontrolleri SSH serveri..."

    /usr/sbin/sshd -D -e &
    SSHD_PID=$!

    trap 'kill "$SSHD_PID" 2>/dev/null || true' EXIT INT TERM

    echo "Ootan, kuni kõik Ansible hostid on kättesaadavad..."

    attempts=0

    until ansible all -m ping; do
        attempts=$((attempts + 1))

        if [ "$attempts" -ge "$SSH_ATTEMPTS" ]; then
            echo "VIGA: Kõik hostid ei muutunud kättesaadavaks."
            break
        fi

        sleep "$SSH_INTERVAL"
    done

    if [ "$attempts" -lt "$SSH_ATTEMPTS" ]; then
        echo "Kõik hostid on kättesaadavad."
        echo "Käivitan Ansible playbook'id..."

        /bin/sh /usr/local/bin/run-playbooks.sh || \
            echo "HOIATUS: Mõni playbook ebaõnnestus."
    fi

    echo "Kontroller jääb tööle."
    wait "$SSHD_PID"
else
    echo "Käivitan worker SSH serveri..."
    exec /usr/sbin/sshd -D -e
fi

