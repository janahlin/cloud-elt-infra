# Python Virtual Environment Setup

This document describes how to set up and use a Python virtual environment for the Cloud ELT Infrastructure project.

## Overview

A Python virtual environment is an isolated environment for Python projects. It allows you to work on a specific project without affecting other projects or your system Python installation. This is especially important for this project, which requires specific versions of libraries like Ansible, Pylint, and other tools.

## Automatic Setup

We provide a script to automatically set up a virtual environment:

```bash
./scripts/setup-venv.sh
```

This script will:
1. Check your Python installation and version (requires Python 3.8+)
2. Create a new virtual environment named `venv` in the project root
3. Activate the virtual environment
4. Install all required dependencies from `requirements.txt`

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

### Python Version Issues

This project requires Python 3.8 or newer. If you have multiple Python versions installed, make sure to create the virtual environment with the correct version:

```bash
python3.8 -m venv venv
``` 