#!/bin/bash
# Script to run all linters for cloud-elt-infra project

set -e

HEADER_COLOR="\033[1;34m"
SUCCESS_COLOR="\033[1;32m"
ERROR_COLOR="\033[1;31m"
WARNING_COLOR="\033[1;33m"
RESET_COLOR="\033[0m"

title() {
  echo -e "${HEADER_COLOR}==== $1 ====${RESET_COLOR}"
}

success() {
  echo -e "${SUCCESS_COLOR}✓ $1${RESET_COLOR}"
}

error() {
  echo -e "${ERROR_COLOR}✗ $1${RESET_COLOR}"
  ERRORS=$((ERRORS+1))
}

warning() {
  echo -e "${WARNING_COLOR}! $1${RESET_COLOR}"
}

# Initialize error counter
ERRORS=0

# Check if required tools are installed
check_tools() {
  title "Checking for required linting tools"
  
  MISSING_TOOLS=0
  
  if ! command -v tflint &> /dev/null; then
    warning "tflint not found. Terraform linting will be skipped."
    warning "Install with: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"
    MISSING_TOOLS=$((MISSING_TOOLS+1))
  else
    success "tflint found"
  fi
  
  if ! command -v ansible-lint &> /dev/null; then
    warning "ansible-lint not found. Ansible linting will be skipped."
    warning "Install with: pip install ansible-lint"
    MISSING_TOOLS=$((MISSING_TOOLS+1))
  else
    success "ansible-lint found"
  fi
  
  if ! command -v pylint &> /dev/null; then
    warning "pylint not found. Python linting will be skipped."
    warning "Install with: pip install pylint"
    MISSING_TOOLS=$((MISSING_TOOLS+1))
  else
    success "pylint found"
  fi
  
  if ! command -v shellcheck &> /dev/null; then
    warning "shellcheck not found. Shell script linting will be skipped."
    warning "Install with: apt-get install shellcheck (Ubuntu/Debian)"
    MISSING_TOOLS=$((MISSING_TOOLS+1))
  else
    success "shellcheck found"
  fi
  
  if ! command -v yamllint &> /dev/null; then
    warning "yamllint not found. YAML linting will be skipped."
    warning "Install with: pip install yamllint"
    MISSING_TOOLS=$((MISSING_TOOLS+1))
  else
    success "yamllint found"
  fi
  
  if [ $MISSING_TOOLS -gt 0 ]; then
    warning "$MISSING_TOOLS linting tools are missing. Some checks will be skipped."
    warning "Run 'scripts/install-linters.sh' to install all required linters."
  else
    success "All linting tools are installed"
  fi
}

# Run TFLint on Terraform files
run_tflint() {
  if ! command -v tflint &> /dev/null; then
    return
  fi
  
  title "Running TFLint on Terraform files"
  
  cd terraform
  if tflint --config=../.lintconfig/tflint.hcl --recursive; then
    success "TFLint completed successfully"
  else
    error "TFLint found issues"
  fi
  cd ..
}

# Run ansible-lint on Ansible files
run_ansible_lint() {
  if ! command -v ansible-lint &> /dev/null; then
    return
  fi
  
  title "Running ansible-lint on Ansible files"
  
  if ansible-lint -c .lintconfig/.ansible-lint ansible; then
    success "ansible-lint completed successfully"
  else
    error "ansible-lint found issues"
  fi
}

# Run pylint on Python files
run_pylint() {
  if ! command -v pylint &> /dev/null; then
    return
  fi
  
  title "Running pylint on Python files"
  
  # Find all Python files, excluding .git, venv, etc.
  PYTHON_FILES=$(find . -type f -name "*.py" | grep -v "\.git\|venv\|\.cache\|\.lintconfig")
  
  if [ -z "$PYTHON_FILES" ]; then
    warning "No Python files found to lint"
    return
  fi
  
  if pylint --rcfile=.lintconfig/.pylintrc $PYTHON_FILES; then
    success "pylint completed successfully"
  else
    error "pylint found issues"
  fi
}

# Run shellcheck on shell scripts
run_shellcheck() {
  if ! command -v shellcheck &> /dev/null; then
    return
  fi
  
  title "Running shellcheck on shell scripts"
  
  # Find all shell script files, excluding .git, venv, etc.
  SHELL_FILES=$(find . -type f -name "*.sh" | grep -v "\.git\|venv\|\.cache\|\.lintconfig")
  
  if [ -z "$SHELL_FILES" ]; then
    warning "No shell script files found to lint"
    return
  fi
  
  if shellcheck -x --rc-file=.lintconfig/.shellcheckrc $SHELL_FILES; then
    success "shellcheck completed successfully"
  else
    error "shellcheck found issues"
  fi
}

# Run yamllint on YAML files
run_yamllint() {
  if ! command -v yamllint &> /dev/null; then
    return
  fi
  
  title "Running yamllint on YAML files"
  
  if yamllint -c .lintconfig/.yamllint .; then
    success "yamllint completed successfully"
  else
    error "yamllint found issues"
  fi
}

# Main function
main() {
  check_tools
  
  echo ""
  run_tflint
  
  echo ""
  run_ansible_lint
  
  echo ""
  run_pylint
  
  echo ""
  run_shellcheck
  
  echo ""
  run_yamllint
  
  echo ""
  title "Lint Summary"
  
  if [ $ERRORS -eq 0 ]; then
    success "All linters completed successfully"
  else
    error "$ERRORS linter(s) reported issues"
    exit 1
  fi
}

# Run main function
main 