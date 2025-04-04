#!/bin/bash
# Script to fix Kubernetes repository issues

set -e

echo "===== Fixing Kubernetes Repository ====="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# Create keyrings directory
mkdir -p /etc/apt/keyrings

# Remove old Kubernetes repository and key
echo "Removing old Kubernetes repository configuration..."
rm -f /etc/apt/sources.list.d/kubernetes.list
rm -f /etc/apt/trusted.gpg.d/kubernetes-archive-keyring.gpg
rm -f /etc/apt/keyrings/kubernetes-archive-keyring.gpg

# Add the new Kubernetes repository
echo "Adding new Kubernetes repository..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

# Update package lists
echo "Updating package lists..."
apt-get update

echo "✓ Kubernetes repository fixed successfully"
