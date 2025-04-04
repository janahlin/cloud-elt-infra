#!/bin/bash
# Script to fix GitHub CLI repository issues

set -e

echo "===== Fixing GitHub CLI Repository ====="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (sudo)"
  exit 1
fi

# Create keyrings directory
mkdir -p /usr/share/keyrings

# Remove old GitHub CLI repository and key
echo "Removing old GitHub CLI repository configuration..."
rm -f /etc/apt/sources.list.d/github-cli.list
rm -f /usr/share/keyrings/githubcli-archive-keyring.gpg

# Add the new GitHub CLI repository
echo "Adding new GitHub CLI repository..."
# Use a temporary file approach to avoid prompts
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg > /tmp/githubcli.gpg
cat /tmp/githubcli.gpg > /usr/share/keyrings/githubcli-archive-keyring.gpg
rm /tmp/githubcli.gpg
chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" > /etc/apt/sources.list.d/github-cli.list

# Update package lists
echo "Updating package lists..."
apt-get update

echo "✓ GitHub CLI repository fixed successfully"
