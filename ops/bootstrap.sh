#!/usr/bin/env bash
# =============================================================================
# bootstrap.sh — Prepare a fresh Ubuntu Server Pi for Ansible
# =============================================================================
# Usage: ./ops/bootstrap.sh <PI_IP> [SSH_USER]
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

# --ask-vault-pass is printed only when there is actually something encrypted
# to decrypt. Operator overrides live in a vaulted local.yml that is not in the
# repository, so a fresh clone has nothing to unlock and should not be asked
# for a passphrase it does not have; this host does, and omitting the flag
# there fails with "Attempting to decrypt but no vault secrets found".
VAULT_HINT=""
if grep -rlq '^\$ANSIBLE_VAULT' "$(dirname "$0")/../ansible/inventory" 2>/dev/null; then
    VAULT_HINT=" --ask-vault-pass"
fi

if command -v ansible &>/dev/null; then
    cd "$(dirname "$0")/../ansible"
    # -e homelab_ssh_port=22 is not optional here, and its absence used to
    # make this step fail on exactly the machine it exists to check. The
    # inventory resolves ansible_port to `homelab_ssh_port | default(
    # ssh_port_hardened)`, so without the override this ping is sent to the
    # hardened port — on a host that has not been hardened yet, because that
    # is what bootstrap is for.
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
