#!/bin/bash

###############################################################################
# VoxMatrix Flutter App - Initial Setup Script
###############################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if Flutter is installed
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed. Please install Flutter first."
        log_info "Visit: https://flutter.dev/docs/get-started/install"
        exit 1
    fi

    # Check Flutter version
    FLUTTER_VERSION=$(flutter --version | head -n 1 | awk '{print $2}')
    log_success "Flutter version: $FLUTTER_VERSION"

    # Check if git is installed
    if ! command -v git &> /dev/null; then
        log_warning "Git is not installed."
    else
        log_success "Git is installed: $(git --version)"
    fi

    # Check if pre-commit is installed
    if ! command -v pre-commit &> /dev/null; then
        log_warning "pre-commit is not installed. Install with: pip install pre-commit"
    else
        log_success "pre-commit is installed: $(pre-commit --version)"
    fi
}

# Setup Flutter
setup_flutter() {
    log_info "Setting up Flutter..."

    # Run Flutter doctor
    log_info "Running Flutter doctor..."
    flutter doctor -v

    # Install dependencies
    log_info "Installing Flutter dependencies..."
    flutter pub get

    # Precache iOS and Android artifacts
    log_info "Precaching Flutter artifacts..."
    flutter precache --ios --android

    log_success "Flutter setup complete!"
}

# Setup code generation
setup_codegen() {
    log_info "Setting up code generation..."

    # Check if build_runner is in pubspec
    if grep -q "build_runner" pubspec.yaml 2>/dev/null; then
        log_info "Running build_runner for the first time..."
        flutter pub run build_runner build --delete-conflicting-outputs || log_warning "build_runner setup failed, continuing..."
    else
        log_warning "build_runner not found in pubspec.yaml"
    fi

    log_success "Code generation setup complete!"
}

# Setup pre-commit hooks
setup_hooks() {
    log_info "Setting up pre-commit hooks..."

    if [ -f ".pre-commit-config.yaml" ]; then
        if command -v pre-commit &> /dev/null; then
            pre-commit install
            log_success "Pre-commit hooks installed!"
        else
            log_warning "pre-commit not found. Skipping hook installation."
        fi
    else
        log_warning ".pre-commit-config.yaml not found. Skipping pre-commit setup."
    fi
}

# Setup environment files
setup_env() {
    log_info "Setting up environment files..."

    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp .env.example .env
            log_success "Created .env from .env.example"
        else
            log_warning ".env.example not found. Creating empty .env..."
            cat > .env << EOF
# VoxMatrix Environment Variables
# Add your configuration here

# API Configuration
API_BASE_URL=
API_KEY=

# Firebase Configuration (optional)
FIREBASE_API_KEY=
FIREBASE_PROJECT_ID=

# Other Configuration
DEBUG_MODE=true
EOF
            log_success "Created .env file"
        fi
    else
        log_info ".env file already exists"
    fi
}

# Setup git secrets
setup_git_secrets() {
    log_info "Setting up git configuration..."

    # Configure git to handle line endings
    git config core.autocrlf input 2>/dev/null || true

    log_success "Git configuration complete!"
}

# Create necessary directories
setup_directories() {
    log_info "Creating necessary directories..."

    mkdir -p logs
    mkdir -p test/mock_data
    mkdir -p assets/images
    mkdir -p assets/icons

    log_success "Directories created!"
}

# Run initial analysis
run_analyze() {
    log_info "Running initial code analysis..."

    flutter analyze || log_warning "Analysis found issues. Please review."

    log_success "Initial analysis complete!"
}

# Main setup flow
main() {
    echo ""
    echo "========================================"
    echo "  VoxMatrix Flutter App Setup"
    echo "========================================"
    echo ""

    # Change to script directory
    cd "$(dirname "$0")/.."

    # Run setup steps
    check_prerequisites
    setup_directories
    setup_env
    setup_flutter
    setup_codegen
    setup_hooks
    setup_git_secrets
    run_analyze

    echo ""
    echo "========================================"
    log_success "Setup completed successfully!"
    echo "========================================"
    echo ""
    echo "Next steps:"
    echo "  1. Review and update .env file"
    echo "  2. Run 'flutter doctor' to verify setup"
    echo "  3. Run 'make test' to verify tests"
    echo "  4. Start coding with 'flutter run'"
    echo ""
}

# Run main function
main "$@"
