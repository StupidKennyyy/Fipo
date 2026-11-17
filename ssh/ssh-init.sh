
#!/bin/sh
set -eu

SSH_DIR="/root/.ssh"
EXCHANGE_DIR="/ssh-exchange"
CONTROLLER_KEY="$EXCHANGE_DIR/controller.pub"

mkdir -p "$SSH_DIR" "$EXCHANGE_DIR" /var/run/sshd
chmod 700 "$SSH_DIR"

if [ "${SSH_ROLE:-worker}" = "controller" ]; then
    echo "Kontroller: kontrollin SSH võtmepaari..."

    if [ ! -f "$SSH_DIR/id_ed25519" ]; then
        ssh-keygen -t ed25519 -N "" -f "$SSH_DIR/id_ed25519"
    fi

    cp "$SSH_DIR/id_ed25519.pub" "$CONTROLLER_KEY"
    cat "$SSH_DIR/id_ed25519.pub" > "$SSH_DIR/authorized_keys"
    echo "Kontrolleri avalik võti avaldatud."

else
    echo "Ootan kontrolleri avalikku võtit..."

    attempts=0
    while [ ! -s "$CONTROLLER_KEY" ]; do
        attempts=$((attempts + 1))

        if [ "$attempts" -ge 180 ]; then
            echo "VIGA: Kontrolleri avalikku võtit ei leitud!"
            exit 1
        fi

        sleep 1
    done

    if ! grep -qxF "$(cat "$CONTROLLER_KEY")" "$SSH_DIR/authorized_keys" 2>/dev/null; then
        cat "$CONTROLLER_KEY" >> "$SSH_DIR/authorized_keys"
    fi

    echo "Kontrolleri avalik võti lisatud."
fi

chmod 600 "$SSH_DIR/authorized_keys" 2>/dev/null || true
chmod 600 "$SSH_DIR/id_ed25519" 2>/dev/null || true
chmod 644 "$SSH_DIR/id_ed25519.pub" 2>/dev/null || true

# Genereeri SSH serveri host-võtmed
ssh-keygen -A

# SSH seadistus
sed -i -E '/^[[:space:]]*(PubkeyAuthentication|PasswordAuthentication|KbdInteractiveAuthentication|PermitRootLogin)[[:space:]]/d' /etc/ssh/sshd_config

cat >> /etc/ssh/sshd_config <<'EOF'

PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
EOF

# Kontrolli konfiguratsiooni ja käivita SSH server
sshd -t

echo "SSH server käivitub..."
exec /usr/sbin/sshd -D -e

