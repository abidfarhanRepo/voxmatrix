#!/bin/bash

###############################################################################
# VoxMatrix Flutter App - Test Script
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

# Variables
COVERAGE=false
VERBOSE=false
WATCH=false
UPDATE_GOLDENS=false
REPORTER="compact"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --coverage)
            COVERAGE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --watch)
            WATCH=true
            shift
            ;;
        --update-goldens)
            UPDATE_GOLDENS=true
            shift
            ;;
        --reporter)
            REPORTER="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --coverage          Generate coverage report"
            echo "  --verbose           Show detailed test output"
            echo "  --watch             Watch mode (run tests on file changes)"
            echo "  --update-goldens    Update golden test files"
            echo "  --reporter TYPE     Set reporter (compact, expanded, json)"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Change to script directory
cd "$(dirname "$0")/.."

# Show header
echo ""
echo "========================================"
echo "  VoxMatrix Flutter Tests"
echo "========================================"
echo ""

# Pre-test checks
log_info "Running pre-test checks..."

# Check Flutter installation
if ! command -v flutter &> /dev/null; then
    log_error "Flutter is not installed!"
    exit 1
fi

# Install dependencies
log_info "Installing dependencies..."
flutter pub get

# Run code generation if needed
if grep -q "build_runner" pubspec.yaml 2>/dev/null; then
    log_info "Running code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs || log_warning "Code generation failed, continuing..."
fi

# Build test arguments
TEST_ARGS=""

if [ "$COVERAGE" = true ]; then
    TEST_ARGS="$TEST_ARGS --coverage"
fi

if [ "$VERBOSE" = true ]; then
    TEST_ARGS="$TEST_ARGS --verbose"
fi

if [ "$UPDATE_GOLDENS" = true ]; then
    TEST_ARGS="$TEST_ARGS --update-goldens"
fi

TEST_ARGS="$TEST_ARGS --test-randomize-ordering-seed random"
TEST_ARGS="$TEST_ARGS --reporter=$REPORTER"

# Run tests
if [ "$WATCH" = true ]; then
    log_info "Running tests in watch mode..."
    flutter test $TEST_ARGS --watch
else
    log_info "Running tests..."
    flutter test $TEST_ARGS

    TEST_EXIT_CODE=$?

    if [ $TEST_EXIT_CODE -eq 0 ]; then
        log_success "All tests passed!"
    else
        log_error "Some tests failed!"
        exit $TEST_EXIT_CODE
    fi
fi

# Coverage report
if [ "$COVERAGE" = true ]; then
    log_info "Generating coverage report..."

    if [ -d "coverage" ]; then
        # Format coverage as lcov
        if command -v dart &> /dev/null; then
            dart run coverage:format_coverage \
                --lcov \
                --in=coverage \
                --out=coverage/lcov.info \
                --packages=.packages \
                --report-on=lib || log_warning "Coverage formatting failed"
        fi

        # Show coverage summary
        if [ -f "coverage/lcov.info" ]; then
            log_info "Coverage report generated: coverage/lcov.info"

            # Try to generate HTML report
            if command -v genhtml &> /dev/null; then
                genhtml coverage/lcov.info -o coverage/html || log_warning "HTML coverage generation failed"
                log_success "HTML coverage report: coverage/html/index.html"
            else
                log_warning "Install lcov for HTML reports: apt install lcov"
            fi

            # Calculate coverage percentage
            if command -v lcov &> /dev/null; then
                COVERAGE_PERCENT=$(lcov --summary coverage/lcov.info 2>&1 | grep "lines" | grep -oP '\d+\.\d+%' || echo "N/A")
                log_success "Line coverage: $COVERAGE_PERCENT"
            fi
        fi
    else
        log_warning "Coverage directory not found"
    fi
fi

# Integration tests
if [ -d "integration_test" ]; then
    log_info "Running integration tests..."

    if [ "$WATCH" = false ]; then
        # Check for connected devices
        DEVICES=$(flutter devices | grep -c "^[a-zA-Z0-9]" || true)

        if [ "$DEVICES" -gt 0 ]; then
            flutter test integration_test --dart-define=CI=true || log_warning "Integration tests failed"
        else
            log_warning "No devices found. Skipping integration tests."
        fi
    fi
fi

# Summary
echo ""
echo "========================================"
log_success "Test run completed!"
echo "========================================"
echo ""

if [ "$COVERAGE" = true ]; then
    echo "Coverage reports:"
    echo "  - LCOV: coverage/lcov.info"
    if [ -d "coverage/html" ]; then
        echo "  - HTML: coverage/html/index.html"
    fi
    echo ""
fi
