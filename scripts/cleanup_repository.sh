#!/bin/bash

# Script to clean up the repository by removing test environments, reports, and other temporary files

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo_status() {
    echo -e "${GREEN}=== $1 ===${NC}"
}

echo_warning() {
    echo -e "${YELLOW}WARNING: $1${NC}"
}

echo_error() {
    echo -e "${RED}ERROR: $1${NC}"
    exit 1
}

# Check if running in the correct directory
if [ ! -d "ansible" ]; then
    echo_error "Please run this script from the repository root directory"
fi

# Confirm before proceeding
echo -e "${YELLOW}This script will remove test environments, reports, backup directories, upgrade scripts and other temporary files.${NC}"
read -p "Do you want to continue? (y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Cleanup aborted."
    exit 0
fi

# Remove test environments
echo_status "Removing test environments"
rm -rf ansible_test_venv/ || echo_warning "Failed to remove ansible_test_venv"
rm -rf ansible_test_env/ || echo_warning "Failed to remove ansible_test_env"
rm -rf ansible_upgrade_env/ || echo_warning "Failed to remove ansible_upgrade_env"
rm -rf ansible_cloud_test_env/ || echo_warning "Failed to remove ansible_cloud_test_env"
rm -rf ansible_dr_test_env/ || echo_warning "Failed to remove ansible_dr_test_env"
rm -rf ansible_cloud_test/ || echo_warning "Failed to remove ansible_cloud_test"
rm -rf ansible_dr_test/ || echo_warning "Failed to remove ansible_dr_test"

# Remove test directories with timestamps
echo_status "Removing test directories with timestamps"
rm -rf ansible_test_20250404_* || echo_warning "Failed to remove test directories with timestamps"

# Remove backup directories
echo_status "Removing backup directories"
rm -rf ansible_backup/ || echo_warning "Failed to remove ansible_backup"
rm -rf ansible_backup_*/ || echo_warning "Failed to remove timestamped backup directories"

# Remove report files
echo_status "Removing report files"
rm -f ansible_upgrade_report.txt || echo_warning "Failed to remove ansible_upgrade_report.txt"
rm -f ansible_disaster_recovery_report.txt || echo_warning "Failed to remove ansible_disaster_recovery_report.txt"
rm -f ansible_cloud_integration_report.txt || echo_warning "Failed to remove ansible_cloud_integration_report.txt"
rm -f ansible_post_upgrade_report.txt || echo_warning "Failed to remove ansible_post_upgrade_report.txt"
rm -f ansible_post_upgrade.txt || echo_warning "Failed to remove ansible_post_upgrade.txt"
rm -f ansible_pre_upgrade.txt || echo_warning "Failed to remove ansible_pre_upgrade.txt"
rm -f ansible_version.txt || echo_warning "Failed to remove ansible_version.txt"
rm -f inventory_pre_upgrade.txt || echo_warning "Failed to remove inventory_pre_upgrade.txt"
rm -f ansible_config_pre_upgrade.txt || echo_warning "Failed to remove ansible_config_pre_upgrade.txt"
rm -f playbook_test.log || echo_warning "Failed to remove playbook_test.log"

# Remove temporary vault password files
echo_status "Removing temporary vault password files"
rm -f .vault_pass_dev.txt || echo_warning "Failed to remove .vault_pass_dev.txt"
rm -f .vault_pass_prod.txt || echo_warning "Failed to remove .vault_pass_prod.txt"
rm -f .vault_pass_test.txt || echo_warning "Failed to remove .vault_pass_test.txt"

# Remove upgrade-specific scripts
echo_status "Removing upgrade-specific scripts"
rm -f scripts/ansible_upgrade_execute.sh || echo_warning "Failed to remove ansible_upgrade_execute.sh"
rm -f scripts/ansible_upgrade_execution_test.sh || echo_warning "Failed to remove ansible_upgrade_execution_test.sh"
rm -f scripts/ansible_check_simple.sh || echo_warning "Failed to remove ansible_check_simple.sh"
rm -f scripts/ansible_upgrade_test.py || echo_warning "Failed to remove ansible_upgrade_test.py"
rm -f scripts/ansible_upgrade_check.sh || echo_warning "Failed to remove ansible_upgrade_check.sh"

# Update requirements.txt with the latest versions
echo_status "Updating requirements.txt with the latest versions"
sed -i 's/ansible-core==.*/ansible-core==2.17.10/' requirements.txt || echo_warning "Failed to update ansible-core version in requirements.txt"
sed -i 's/ansible==.*/ansible==10.7.0/' requirements.txt || echo_warning "Failed to update ansible version in requirements.txt"
sed -i 's/ansible-compat==.*/ansible-compat==25.1.5/' requirements.txt || echo_warning "Failed to update ansible-compat version in requirements.txt"

echo_status "Cleanup completed successfully"
