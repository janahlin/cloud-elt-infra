# Python Virtual Environment Setup

This document describes how to set up and use a Python virtual environment for the Cloud ELT Infrastructure project.

## Overview

A Python virtual environment is an isolated environment for Python projects. It allows you to work on a specific project without affecting other projects or your system Python installation. This is especially important for this project, which requires specific versions of libraries like Ansible, Pylint, and other tools.

## Ansible Versions

This project uses the following Ansible packages:

- **ansible-core**: 2.17.10
- **ansible**: 10.7.0
- **ansible-compat**: 25.1.5
- **ansible-lint**: 25.2.0

These versions are specified in the `requirements.txt` file and are automatically installed when setting up the virtual environment.

## Automatic Setup

We provide a script to automatically set up a virtual environment:

```bash
./scripts/setup-venv.sh
```

This script will:
1. Check your Python installation and version (requires Python 3.8+)
2. Check for Terraform installation (requires Terraform 1.0+)
3. Check for Ansible installation (recommends Ansible 2.9+)
4. Check for Azure CLI and OCI CLI installations
5. Check for the Python venv module
6. Create a new virtual environment named `venv` in the project root
7. Activate the virtual environment
8. Install all required dependencies from `requirements.txt`
9. Install Ansible and related packages with specific versions
10. Install cloud provider CLIs and development tools

You can also specify a custom name for your virtual environment:

```bash
./scripts/setup-venv.sh my_custom_venv
```

## Manual Setup

If you prefer to set up the virtual environment manually, follow these steps:

### 1. Create a Virtual Environment

```bash
# On Linux/macOS
python3 -m venv venv

# On Windows
python -m venv venv
```

### 2. Activate the Virtual Environment

```bash
# On Linux/macOS
source venv/bin/activate

# On Windows
venv\Scripts\activate
```

When activated, your command prompt will be prefixed with `(venv)` indicating that the virtual environment is active.

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Install Ansible Collections

```bash
# Install collections inside the virtual environment
ansible-galaxy collection install ansible.posix:1.5.4 community.general:9.1.0 -p venv/lib/python3.10/site-packages/ansible_collections
```

## Working with the Virtual Environment

### Activating the Environment

Every time you open a new terminal to work on the project, you need to activate the virtual environment:

```bash
# On Linux/macOS
source venv/bin/activate

# On Windows
venv\Scripts\activate
```

### Deactivating the Environment

When you're done working on the project, you can deactivate the virtual environment:

```bash
deactivate
```

### Installing New Dependencies

If you need to install additional packages:

```bash
pip install package_name
```

Remember to update the requirements.txt file:

```bash
pip freeze > requirements.txt
```

## Ansible Collections Management

### Using Project-Specific Collections

This project is configured to use Ansible collections from the virtual environment first, falling back to system-level collections if needed. This prevents conflicts between different versions of the same collection.

If you see warnings about multiple versions of collections, you can fix this with:

```bash
./scripts/fix-ansible-collections.sh
```

This script will:
1. Detect your virtual environment's Python version
2. Install the required collection versions into your virtual environment
3. Update the `ansible.cfg` file to prioritize collections in the virtual environment

### Manually Installing Collections

If you need to install additional collections or specific versions:

```bash
ansible-galaxy collection install collection_name:version -p venv/lib/python3.10/site-packages/ansible_collections
```

### Adding New Collection Dependencies

If you add a new collection dependency to the project:

1. Add the collection to the `install_ansible_collections` function in `scripts/setup-venv.sh`
2. Add the collection to the `fix_collections` function in `scripts/fix-ansible-collections.sh`
3. Document the new dependency in the relevant documentation

## Using with Linters and Deployment Scripts

All linters and deployment scripts in this project will work with your virtual environment once it's activated.

```bash
# First, activate the virtual environment
source venv/bin/activate

# Then run linters
./scripts/run-linters.sh

# Or deploy infrastructure
ansible-playbook ansible/playbooks/deploy_azure_infra.yml -e @azure-vars.yml
```

## Common Issues and Solutions

### Virtual Environment Not Activating

If you see an error such as "cannot be loaded because running scripts is disabled on this system", you need to adjust your execution policy on Windows:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Module Not Found Errors

If you see "ModuleNotFoundError", make sure:
1. Your virtual environment is activated (you should see `(venv)` in your prompt)
2. You've installed all dependencies with `pip install -r requirements.txt`

### Ansible Collection Conflicts

If you see warnings like:
```
WARNING: Another version of 'ansible.posix' was found installed...
```

Run the provided fix script:
```bash
./scripts/fix-ansible-collections.sh
```

### Python Version Issues

This project requires Python 3.8 or newer. If you have multiple Python versions installed, make sure to create the virtual environment with the correct version:

```bash
python3.8 -m venv venv
```
