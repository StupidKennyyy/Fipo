#!/bin/bash
set -e

PLAYBOOK_DIR="/opt/fipo/playbooks"
INVENTORY="/etc/ansible/hosts"

for playbook in "$PLAYBOOK_DIR"/[0-9][0-9]-*.yml; do
    [ -f "$playbook" ] || continue

    echo "===================================="
    echo "Käivitan: $(basename "$playbook")"
    echo "===================================="

    ansible-playbook -i "$INVENTORY" "$playbook"
done

echo "Kõik playbook'id on edukalt käivitatud!"
