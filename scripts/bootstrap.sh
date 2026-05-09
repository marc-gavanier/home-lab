#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Prepare a fresh Ubuntu Server Pi for Ansible
# =============================================================================
# Usage: ./scripts/bootstrap.sh <PI_IP> [SSH_USER]
#
# What this script does:
#   1. Copies your SSH public key to the Pi
#   2. Installs Python 3 (required by Ansible)
#   3. Verifies Ansible connectivity
# =============================================================================

set -euo pipefail

PI_IP="${1:?Usage: $0 <PI_IP> [SSH_USER]}"
SSH_USER="${2:-ubuntu}"
SSH_KEY="${SSH_KEY:-~/.ssh/id_homelab}"

echo "=== Home Lab Bootstrap ==="
echo "Target: ${SSH_USER}@${PI_IP}"
echo ""

# --- Step 1: Generate SSH key if it doesn't exist ---
if [ ! -f "${SSH_KEY}" ]; then
    echo "[1/4] Generating SSH key pair..."
    ssh-keygen -t ed25519 -f "${SSH_KEY}" -C "homelab" -N ""
else
    echo "[1/4] SSH key already exists: ${SSH_KEY}"
fi

# --- Step 2: Copy SSH key to the Pi ---
echo "[2/4] Copying SSH public key to Pi..."
ssh-copy-id -i "${SSH_KEY}.pub" "${SSH_USER}@${PI_IP}"

# --- Step 3: Install Python 3 on the Pi ---
echo "[3/4] Installing Python 3 on Pi..."
ssh -i "${SSH_KEY}" "${SSH_USER}@${PI_IP}" \
    "sudo apt-get update -qq && sudo apt-get install -yqq python3 python3-apt"

# --- Step 4: Verify Ansible connectivity ---
echo "[4/4] Verifying Ansible connectivity..."
if command -v ansible &>/dev/null; then
    cd "$(dirname "$0")/../ansible"
    ansible homelab -m ping \
        --extra-vars "homelab_ip=${PI_IP} ansible_user=${SSH_USER}" \
        --private-key "${SSH_KEY}"
    echo ""
    echo "=== Bootstrap complete! ==="
    echo ""
    echo "Next steps:"
    echo "  1. Edit ansible/inventory/group_vars/all.yml (set your Pi's IP)"
    echo "  2. Run: cd ansible && ansible-playbook playbooks/site.yml"
else
    echo "Ansible not found locally. Install it with: pip install ansible"
    echo ""
    echo "=== Bootstrap partial — SSH is ready ==="
    echo ""
    echo "Next steps:"
    echo "  1. Install Ansible: pip install ansible"
    echo "  2. Edit ansible/inventory/group_vars/all.yml"
    echo "  3. Run: cd ansible && ansible-playbook playbooks/site.yml"
fi
