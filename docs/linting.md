# Linting Configuration

This document describes the linting tools and configurations used in the Cloud ELT Infrastructure project.

## Overview

We use several linting tools to ensure code quality and consistency across the project:

1. **TFLint** - For Terraform code
2. **ansible-lint** - For Ansible playbooks and roles
3. **Pylint** - For Python code
4. **ShellCheck** - For shell scripts
5. **yamllint** - For YAML files

## Virtual Environment

It's strongly recommended to use a Python virtual environment when installing and running linters. This isolates the linters and their dependencies from your system Python installation.

```bash
# Set up a new virtual environment
./scripts/setup-venv.sh

# Activate the existing virtual environment
source venv/bin/activate  # Linux/macOS
venv\Scripts\activate     # Windows
```

For detailed information about setting up and using a virtual environment, see [Virtual Environment Guide](virtual-environment.md).

## Installation

To install all required linters, first activate your virtual environment, then run:

```bash
source venv/bin/activate  # Activate your virtual environment first
./scripts/install-linters.sh
```

This script will detect your operating system and install the appropriate versions of all linters.

## Running Linters

To run all linters at once:

```bash
source venv/bin/activate  # Activate your virtual environment first
./scripts/run-linters.sh
```

This script will:
1. Check if all required linters are installed
2. Run each linter with appropriate configuration
3. Report issues found in each linting step

## Linter Configurations

All linter configurations are stored in the `.lintconfig` directory:

### TFLint (Terraform)

Configuration: `.lintconfig/tflint.hcl`

TFLint is configured to:
- Check for deprecated Terraform syntax
- Validate variable declarations and types
- Enforce naming conventions
- Verify module structure
- Include specific rules for Azure and OCI providers

To run manually:
```bash
cd terraform
tflint --config=../.lintconfig/tflint.hcl --recursive
```

### ansible-lint (Ansible)

Configuration: `.lintconfig/.ansible-lint`

ansible-lint is configured to:
- Check for deprecated Ansible syntax
- Enforce Ansible best practices
- Verify playbook structure
- Skip certain rules that don't apply to this project

To run manually:
```bash
ansible-lint -c .lintconfig/.ansible-lint ansible
```

### Pylint (Python)

Configuration: `.lintconfig/.pylintrc`

Pylint is configured to:
- Enforce PEP 8 style guidelines with some exceptions
- Check for logical errors
- Limit code complexity
- Enforce naming conventions

To run manually:
```bash
pylint --rcfile=.lintconfig/.pylintrc [python_files]
```

### ShellCheck (Shell scripts)

Configuration: `.lintconfig/.shellcheckrc`

ShellCheck is configured to:
- Check for common shell script bugs
- Enforce shell script best practices
- Ignore certain rules that don't apply to this project

To run manually:
```bash
shellcheck -x --rc-file=.lintconfig/.shellcheckrc [shell_files]
```

### yamllint (YAML)

Configuration: `.lintconfig/.yamllint`

yamllint is configured to:
- Check for YAML syntax errors
- Enforce consistent formatting
- Verify document structure

To run manually:
```bash
yamllint -c .lintconfig/.yamllint .
```

## CI/CD Integration

The linting tools are integrated into our GitHub Actions workflow in `.github/workflows/terraform-validate.yml`.

For each pull request and push to main/develop branches, the workflow will:
1. Run all linters
2. Report any issues found
3. Run security scans with Checkov and tfsec

## Pre-commit Hooks

To enable linting as pre-commit hooks, run:

```bash
pre-commit install
```

This will configure git to run the linters before each commit, preventing code with linting issues from being committed.

## Customizing Linter Rules

If you need to modify linter rules or configurations:

1. Edit the appropriate file in the `.lintconfig` directory
2. Test your changes by running the specific linter
3. Update this documentation if the behavior changes significantly 