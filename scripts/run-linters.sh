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

# Show usage information
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Run linting checks on the cloud-elt-infra codebase."
  echo ""
  echo "Options:"
  echo "  --init-tflint       Initialize TFLint plugins before running"
  echo "  --force-init-tflint Reinstall all TFLint plugins before running"
  echo "  --help              Display this help message and exit"
  echo ""
  echo "Examples:"
  echo "  $0                   # Run all linters normally"
  echo "  $0 --init-tflint     # Initialize TFLint plugins then run linters"
  echo "  $0 --force-init-tflint  # Reinstall TFLint plugins then run linters"
  echo ""
}

# Initialize error counter
ERRORS=0

# Check if running in virtual environment
check_venv() {
  title "Checking virtual environment"

  if [ -z "$VIRTUAL_ENV" ]; then
    warning "Not running in a Python virtual environment."
    warning "It's strongly recommended to run Python linters in a virtual environment."
    warning "Some linters might not be available or might use system versions."
    warning "To create and activate a virtual environment run:"
    warning "  ./scripts/setup-venv.sh"
    warning "  source venv/bin/activate  # Linux/macOS"
    warning "  venv\\Scripts\\activate     # Windows"

    read -p "Continue without a virtual environment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Exiting. Please create a virtual environment and try again."
      exit 1
    fi
  else
    success "Running in virtual environment: $VIRTUAL_ENV"
  fi
}

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

  TFLINT_ISSUES=0
  CURRENT_DIR=$(pwd)
  CONFIG_PATH="${CURRENT_DIR}/.lintconfig/tflint.hcl"

  echo "Using TFLint config from: ${CONFIG_PATH}"

  # Clean existing plugin installations if needed
  if [ "$1" = "--force-init" ]; then
    echo "Forcing plugin re-initialization..."
    rm -rf ~/.tflint.d/plugins
  fi

  # Check if terraform directory exists
  if [ ! -d "terraform" ]; then
    warning "Terraform directory not found. Skipping TFLint."
    return
  fi

  # Run for root terraform directory
  echo "Checking terraform root directory..."
  cd terraform

  # Initialize plugins if requested
  if [ "$1" = "--init" ] || [ "$1" = "--force-init" ]; then
    echo "Initializing TFLint plugins..."
    tflint --init --config="${CONFIG_PATH}" || echo "Warning: Plugin initialization failed"
  fi

  # Run TFLint
  if ! tflint --config="${CONFIG_PATH}"; then
    TFLINT_ISSUES=$((TFLINT_ISSUES+1))
  fi

  # Check all subdirectories
  for dir_type in "modules" "environments"; do
    if [ -d "$dir_type" ]; then
      for dir in $dir_type/*; do
        if [ -d "$dir" ]; then
          echo "Checking $dir..."
          cd "${CURRENT_DIR}/terraform/$dir"

          # Initialize plugins if requested
          if [ "$1" = "--init" ] || [ "$1" = "--force-init" ]; then
            tflint --init --config="${CONFIG_PATH}" || echo "Warning: Plugin initialization failed in $dir"
          fi

          # Run TFLint
          if ! tflint --config="${CONFIG_PATH}"; then
            TFLINT_ISSUES=$((TFLINT_ISSUES+1))
          fi
        fi
      done
    fi
  done

  # Return to original directory
  cd "$CURRENT_DIR"

  if [ $TFLINT_ISSUES -eq 0 ]; then
    success "TFLint completed successfully"
  else
    error "TFLint found issues in $TFLINT_ISSUES directories"
  fi
}

# Run ansible-lint on Ansible files
run_ansible_lint() {
  if ! command -v ansible-lint &> /dev/null; then
    return
  fi

  title "Running ansible-lint on Ansible files"

  if ANSIBLE_LINT_SKIP_VERBOSITY=1 ansible-lint -c .lintconfig/.ansible-lint ansible; then
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
  # Process command line arguments
  TFLINT_ARGS=""

  while [ "$#" -gt 0 ]; do
    case "$1" in
      --init-tflint)
        TFLINT_ARGS="--init"
        shift
        ;;
      --force-init-tflint)
        TFLINT_ARGS="--force-init"
        shift
        ;;
      --help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
  done

  check_venv
  check_tools

  echo ""
  run_tflint $TFLINT_ARGS

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
    exit 0
  else
    error "$ERRORS linter(s) reported issues"
    exit 1
  fi
}

# Run main function
main "$@"
