#!/usr/bin/env python3
"""
Ansible Playbook Test Script

This script tests a specific playbook with the upgraded Ansible version.
It creates a virtual environment, installs the specified versions, and
runs the playbook in check mode.
"""

import os
import sys
import subprocess
import venv
import time
import argparse
import logging
import shutil
from pathlib import Path
import json

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[logging.StreamHandler(), logging.FileHandler("playbook_test.log")],
)
logger = logging.getLogger(__name__)

# Colors for output
RED = "\033[0;31m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
NC = "\033[0m"  # No Color


def print_status(message):
    """Print a status message in green."""
    logger.info(message)
    print(f"{GREEN}=== {message} ==={NC}")


def print_warning(message):
    """Print a warning message in yellow."""
    logger.warning(message)
    print(f"{YELLOW}WARNING: {message}{NC}")


def print_error(message):
    """Print an error message in red."""
    logger.error(message)
    print(f"{RED}ERROR: {message}{NC}")


def run_command(cmd, check=True, timeout=60, capture_output=True, env=None, cwd=None):
    """Run a command and return its output."""
    try:
        logger.info(f"Running command: {' '.join(cmd)}")
        if cwd:
            logger.info(f"Working directory: {cwd}")
        result = subprocess.run(
            cmd,
            check=check,
            timeout=timeout,
            stdout=subprocess.PIPE if capture_output else None,
            stderr=subprocess.PIPE if capture_output else None,
            text=True,
            env=env,
            cwd=cwd,
        )
        if result.stdout:
            logger.debug(f"Command stdout: {result.stdout}")
        if result.stderr:
            logger.debug(f"Command stderr: {result.stderr}")
        if result.returncode != 0:
            print_error(f"Command failed with return code {result.returncode}")
            print_error(f"Error output: {result.stderr}")
            if check:
                sys.exit(1)
            return None
        return result.stdout
    except subprocess.CalledProcessError as e:
        print_error(f"Command failed: {' '.join(cmd)}")
        print_error(f"Error output: {e.stderr}")
        if check:
            sys.exit(1)
        return None
    except subprocess.TimeoutExpired:
        print_error(f"Command timed out after {timeout} seconds: {' '.join(cmd)}")
        if check:
            sys.exit(1)
        return None
    except Exception as e:
        print_error(f"Unexpected error running command {' '.join(cmd)}: {str(e)}")
        if check:
            sys.exit(1)
        return None


def create_venv(venv_path):
    """Create a virtual environment."""
    print_status(f"Creating virtual environment at {venv_path}")
    try:
        venv.create(venv_path, with_pip=True)
        return True
    except Exception as e:
        print_error(f"Failed to create virtual environment: {e}")
        return False


def activate_venv(venv_path):
    """Activate the virtual environment."""
    if sys.platform == "win32":
        python_path = venv_path / "Scripts" / "python.exe"
        pip_path = venv_path / "Scripts" / "pip.exe"
    else:
        python_path = venv_path / "bin" / "python"
        pip_path = venv_path / "bin" / "pip"

    if not python_path.exists():
        print_error(f"Python executable not found: {python_path}")
        return False

    # Update environment variables
    os.environ["VIRTUAL_ENV"] = str(venv_path)
    os.environ["PATH"] = (
        str(venv_path / ("Scripts" if sys.platform == "win32" else "bin"))
        + os.pathsep
        + os.environ["PATH"]
    )

    # Verify pip installation
    try:
        run_command([str(pip_path), "--version"])
        logger.info("Successfully activated virtual environment")
        return True
    except Exception as e:
        print_error(f"Failed to verify pip installation: {e}")
        return False


def install_packages(venv_path, packages):
    """Install packages using pip."""
    print_status(f"Installing packages: {', '.join(packages)}")
    pip_path = str(
        venv_path / ("Scripts" if sys.platform == "win32" else "bin") / "pip"
    )

    # First try with all dependencies
    cmd = [pip_path, "install", "--timeout=300"] + packages
    output = run_command(cmd, check=False)

    if output is None:
        print_warning("Initial installation failed, trying with --no-deps")
        # Try installing without dependencies
        for package in packages:
            cmd = [pip_path, "install", "--no-deps", package]
            output = run_command(cmd, check=False)
            if output is None:
                print_error(f"Failed to install package: {package}")
                return False

    # Verify installations
    for package in packages:
        package_name = package.split("==")[0]
        cmd = [pip_path, "show", package_name]
        if run_command(cmd, check=False) is None:
            print_error(f"Failed to verify installation of {package}")
            return False

    return True


def setup_test_inventory(test_dir):
    """Create a test inventory file."""
    print_status("Setting up test inventory")
    inventory_dir = test_dir / "inventories"
    inventory_dir.mkdir(exist_ok=True)

    # Create inventory file
    inventory_file = inventory_dir / "test_inventory.ini"
    inventory_file.write_text(
        """[controller]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
terraform_dir=./terraform"""
    )

    return inventory_dir


def create_mock_terraform():
    """Create a mock terraform script."""
    script = """#!/bin/bash
case "$1" in
    "state")
        case "$2" in
            "list")
                echo "module.networking"
                ;;
            "show")
                echo '
{
  "mode": "managed",
  "type": "test_resource",
  "name": "example",
  "provider": "provider[\\"registry.terraform.io/hashicorp/test\\"]",
  "instances": [
    {
      "schema_version": 0,
      "attributes": {
        "id": "test"
      }
    }
  ]
}'
                ;;
            *)
                exit 1
                ;;
        esac
        ;;
    *)
        exit 1
        ;;
esac"""
    return script


def setup_test_environment(test_dir):
    """Set up the test environment with necessary files and directories."""
    print_status("Setting up test environment")

    # Create terraform directory
    terraform_dir = test_dir / "terraform"
    terraform_dir.mkdir(exist_ok=True)

    # Create mock terraform executable
    mock_terraform = test_dir / "bin"
    mock_terraform.mkdir(exist_ok=True)
    terraform_script = mock_terraform / "terraform"
    terraform_script.write_text(create_mock_terraform())
    terraform_script.chmod(0o755)

    # Create vault password files
    vault_dev = test_dir / ".vault_pass_dev.txt"
    vault_prod = test_dir / ".vault_pass_prod.txt"
    vault_dev.write_text("test_dev_password")
    vault_prod.write_text("test_prod_password")

    return terraform_dir


def test_playbook(venv_path, playbook_path, check_mode=True):
    """Test a playbook with the upgraded Ansible version."""
    print_status(f"Testing playbook: {playbook_path}")

    if not os.path.exists(playbook_path):
        print_error(f"Playbook not found: {playbook_path}")
        return False

    ansible_playbook = str(
        venv_path
        / ("Scripts" if sys.platform == "win32" else "bin")
        / "ansible-playbook"
    )

    # Create test directory structure
    test_dir = venv_path / "ansible_test"
    test_dir.mkdir(exist_ok=True)

    # Copy ansible.cfg to test directory
    shutil.copy("ansible/ansible.cfg", test_dir)

    # Setup test inventory and environment
    inventory_dir = setup_test_inventory(test_dir)
    terraform_dir = setup_test_environment(test_dir)

    # Create absolute paths
    terraform_dir_abs = os.path.abspath(terraform_dir)

    # Set environment variables for Ansible
    env = os.environ.copy()
    env["ANSIBLE_CONFIG"] = str(test_dir / "ansible.cfg")
    env["ANSIBLE_VAULT_PASSWORD_FILE"] = str(test_dir / ".vault_pass_dev.txt")
    env["PATH"] = str(test_dir / "bin") + os.pathsep + env["PATH"]

    # First, check syntax only
    print_status("Checking playbook syntax")
    cmd = [
        ansible_playbook,
        "--syntax-check",
        "-i",
        str(inventory_dir / "test_inventory.ini"),
        playbook_path,
    ]
    if run_command(cmd, check=False, env=env) is None:
        print_error("Playbook syntax check failed")
        return False

    # Then run the playbook in check mode if requested
    if check_mode:
        print_status("Running playbook in check mode")
        cmd = [
            ansible_playbook,
            "--check",
            "-i",
            str(inventory_dir / "test_inventory.ini"),
            "-e",
            f"terraform_dir={terraform_dir_abs}",
            playbook_path,
        ]
        if (
            run_command(
                cmd, check=False, capture_output=False, env=env, cwd=terraform_dir_abs
            )
            is None
        ):
            print_error("Playbook check mode run failed")
            return False

    print_status(f"Playbook test completed: {playbook_path}")
    return True


def main():
    """Main function."""
    parser = argparse.ArgumentParser(
        description="Test an Ansible playbook with the upgraded version"
    )
    parser.add_argument("playbook", help="Path to the playbook to test")
    parser.add_argument(
        "--no-check", action="store_true", help="Don't run in check mode"
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="Enable verbose output"
    )
    args = parser.parse_args()

    if args.verbose:
        logger.setLevel(logging.DEBUG)

    # Define the packages to install
    packages = ["ansible-core==2.17.10", "ansible==10.7.0", "ansible-compat==25.1.5"]

    # Create a timestamped virtual environment
    timestamp = time.strftime("%Y%m%d_%H%M%S")
    venv_path = Path(f"ansible_test_{timestamp}")

    try:
        # Create and activate the virtual environment
        if not create_venv(venv_path):
            sys.exit(1)

        if not activate_venv(venv_path):
            sys.exit(1)

        # Install the packages
        if not install_packages(venv_path, packages):
            sys.exit(1)

        # Test the playbook
        if not test_playbook(venv_path, args.playbook, not args.no_check):
            sys.exit(1)

        print_status("Test completed successfully")
        print(f"Virtual environment created at: {venv_path}")
        print("You can activate it manually with:")
        if sys.platform == "win32":
            print(f"  {venv_path}\\Scripts\\activate")
        else:
            print(f"  source {venv_path}/bin/activate")

    except Exception as e:
        print_error(f"Unexpected error: {str(e)}")
        logger.exception("Unexpected error occurred")
        sys.exit(1)
    finally:
        logger.info("Test script completed")


def run_playbook(
    playbook_path,
    inventory_path,
    extra_vars=None,
    vault_password_file=None,
    check_mode=False,
    tags=None,
):
    """Run an Ansible playbook with the specified parameters.

    Args:
        playbook_path (str): Path to the Ansible playbook
        inventory_path (str): Path to the inventory file
        extra_vars (dict, optional): Extra variables to pass to the playbook
        vault_password_file (str, optional): Path to vault password file
        check_mode (bool, optional): Whether to run in check mode
        tags (list, optional): List of tags to run

    Returns:
        bool: True if playbook execution was successful, False otherwise
    """
    logging.info("Running playbook: %s", playbook_path)

    if not os.path.exists(playbook_path):
        logging.error("Playbook not found: %s", playbook_path)
        return False

    if not os.path.exists(inventory_path):
        logging.error("Inventory not found: %s", inventory_path)
        return False

    try:
        cmd = ["ansible-playbook", playbook_path, "-i", inventory_path]
        if extra_vars:
            cmd.extend(["-e", json.dumps(extra_vars)])
        if vault_password_file:
            cmd.extend(["--vault-password-file", vault_password_file])
        if check_mode:
            cmd.append("--check")
        if tags:
            cmd.extend(["--tags", ",".join(tags)])

        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        logging.error("Playbook execution failed: %s", e.stderr)
        return False


def validate_playbook_syntax():
    """Validate the syntax of all playbooks in the repository."""
    playbook_dir = "ansible/playbooks"
    all_valid = True

    for playbook in os.listdir(playbook_dir):
        if playbook.endswith(".yml"):
            playbook_path = os.path.join(playbook_dir, playbook)
            logging.info("Validating playbook: %s", playbook_path)
            if not run_playbook(
                playbook_path, "ansible/inventory/test.ini", check_mode=True
            ):
                all_valid = False

    return all_valid


def test_playbook_execution():
    """Test the execution of various playbooks with different configurations."""
    # Test basic playbook execution
    assert run_playbook(
        "ansible/playbooks/infrastructure_deploy.yml", "ansible/inventory/test.ini"
    )

    # Test playbook with extra vars
    assert run_playbook(
        "ansible/playbooks/backup.yml",
        "ansible/inventory/test.ini",
        {"backup_type": "full"},
    )


if __name__ == "__main__":
    main()
