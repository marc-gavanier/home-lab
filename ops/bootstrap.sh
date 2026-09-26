#!/usr/bin/env bash

set -euo pipefail

PI_IP="${1:?Usage: $0 <PI_IP> [SSH_USER]}"
SSH_USER="${2:-ubuntu}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_homelab}"

echo "=== Home Lab Bootstrap ==="
echo "Target: ${SSH_USER}@${PI_IP}"
echo ""

if [ ! -f "${SSH_KEY}" ]; then
    echo "[1/4] Generating SSH key pair..."
    ssh-keygen -t ed25519 -f "${SSH_KEY}" -C "homelab" -N ""
else
    echo "[1/4] SSH key already exists: ${SSH_KEY}"
fi

echo "[2/4] Copying SSH public key to Pi..."
ssh-copy-id -i "${SSH_KEY}.pub" "${SSH_USER}@${PI_IP}"

echo "[3/4] Installing Python 3 on Pi..."
ssh -i "${SSH_KEY}" "${SSH_USER}@${PI_IP}" \
    "sudo apt-get update -qq && sudo apt-get install -yqq python3 python3-apt"

echo "[4/4] Verifying Ansible connectivity..."

VAULT_HINT=""
if grep -rlq '^\$ANSIBLE_VAULT' "$(dirname "$0")/../ansible/inventory" 2>/dev/null; then
    VAULT_HINT=" --ask-vault-pass"
fi

if command -v ansible &>/dev/null; then
    cd "$(dirname "$0")/../ansible"
    ansible homelab -m ping \
        --extra-vars "homelab_ip=${PI_IP} ansible_user=${SSH_USER} homelab_ssh_port=22" \
        --private-key "${SSH_KEY}"
    echo ""
    echo "=== Bootstrap complete! ==="
    echo ""
    echo "Next steps:"
    echo "  1. Edit ansible/inventory/group_vars/all.yml (set your Pi's IP)"
    echo "  2. Run: cd ansible && ansible-playbook playbooks/site.yml \\"
    echo "            -e homelab_ssh_port=22${VAULT_HINT}"
    echo ""
    echo "     The port override is needed until the hardening run has moved"
    echo "     SSH; after that, drop it and the inventory resolves it itself."
else
    echo "Ansible not found locally. Install it with: pip install ansible"
    echo ""
    echo "=== Bootstrap partial — SSH is ready ==="
    echo ""
    echo "Next steps:"
    echo "  1. Install Ansible: pip install ansible"
    echo "  2. Edit ansible/inventory/group_vars/all.yml"
    echo "  3. Run: cd ansible && ansible-playbook playbooks/site.yml \\"
    echo "            -e homelab_ssh_port=22${VAULT_HINT}"
fi
