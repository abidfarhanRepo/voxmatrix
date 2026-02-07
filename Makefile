.PHONY: help setup clean format analyze test coverage build-android build-ios gen-codegen deps-upgrade

# Default target
.DEFAULT_GOAL := help

# Colors for output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Variables
FLUTTER := flutter
DART := dart
PROJECT_NAME := voxmatrix
BUILD_DIR := build
COVERAGE_DIR := coverage

help: ## Show this help message
	@echo '$(PROJECT_NAME) - Makefile Commands'
	@echo ''
	@echo 'Usage:'
	@echo '  make <target>'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## Initial setup - install dependencies and configure project
	@echo "$(BLUE)Setting up $(PROJECT_NAME)...$(NC)"
	@$(FLUTTER) pub get
	@$(FLUTTER) precache --ios --android
	@$(FLUTTER) doctor -v
	@echo "$(GREEN)Setup complete!$(NC)"

clean: ## Clean build artifacts and cache
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)/
	@rm -rf .dart_tool/
	@rm -rf $(COVERAGE_DIR)/
	@find . -type d -name ".flutter-plugins" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.lock" -path "*/.dart_tool/*" -delete 2>/dev/null || true
	@cd android && ./gradlew clean 2>/dev/null || true
	@echo "$(GREEN)Clean complete!$(NC)"

format: ## Format Dart code
	@echo "$(BLUE)Formatting code...$(NC)"
	@$(DART) format .
	@$(FLUTTER) pub run build_runner build --delete-conflicting-outputs 2>/dev/null || true
	@echo "$(GREEN)Formatting complete!$(NC)"

format-check: ## Check code formatting without making changes
	@echo "$(BLUE)Checking code format...$(NC)"
	@$(DART) format --output=none --set-exit-if-changed .

analyze: ## Run Flutter analyze
	@echo "$(BLUE)Analyzing code...$(NC)"
	@$(FLUTTER) analyze --fatal-infos
	@echo "$(GREEN)Analysis complete!$(NC)"

fix: ## Apply automatic Dart fixes
	@echo "$(BLUE)Applying Dart fixes...$(NC)"
	@$(DART) fix --apply
	@echo "$(GREEN)Fixes applied!$(NC)"

test: ## Run all tests
	@echo "$(BLUE)Running tests...$(NC)"
	@$(FLUTTER) test --test-randomize-ordering-seed random
	@echo "$(GREEN)Tests complete!$(NC)"

test-verbose: ## Run tests with verbose output
	@echo "$(BLUE)Running tests (verbose)...$(NC)"
	@$(FLUTTER) test --verbose --test-randomize-ordering-seed random

coverage: ## Run tests with coverage report
	@echo "$(BLUE)Running tests with coverage...$(NC)"
	@$(FLUTTER) test --coverage
	@$(DART) run coverage:format_coverage --lcov --in=$(COVERAGE_DIR) --out=$(COVERAGE_DIR)/lcov.info --packages=.packages --report-on=lib
	@echo "$(GREEN)Coverage report generated in $(COVERAGE_DIR)/$(NC)"

coverage-html: ## Generate HTML coverage report
	@echo "$(BLUE)Generating HTML coverage report...$(NC)"
	@$(MAKE) coverage
	@genhtml $(COVERAGE_DIR)/lcov.info -o $(COVERAGE_DIR)/html 2>/dev/null || echo "Install lcov for HTML reports: apt install lcov"
	@echo "$(GREEN)HTML report generated in $(COVERAGE_DIR)/html/$(NC)"

deps-upgrade: ## Upgrade dependencies to latest versions
	@echo "$(BLUE)Upgrading dependencies...$(NC)"
	@$(FLUTTER) pub upgrade --major-versions
	@$(FLUTTER) pub outdated
	@echo "$(GREEN)Dependencies upgraded!$(NC)"

deps-check: ## Check for outdated dependencies
	@echo "$(BLUE)Checking for outdated dependencies...$(NC)"
	@$(FLUTTER) pub outdated

audit: ## Audit dependencies for security vulnerabilities
	@echo "$(BLUE)Auditing dependencies...$(NC)"
	@$(DART) pub audit

build-android: ## Build Android APK (debug)
	@echo "$(BLUE)Building Android APK (debug)...$(NC)"
	@$(FLUTTER) build apk --debug
	@echo "$(GREEN)Android APK built: $(BUILD_DIR)/app/outputs/flutter-apk/app-debug.apk$(NC)"

build-android-release: ## Build Android APK (release)
	@echo "$(BLUE)Building Android APK (release)...$(NC)"
	@$(FLUTTER) build apk --release
	@echo "$(GREEN)Android APK built: $(BUILD_DIR)/app/outputs/flutter-apk/app-release.apk$(NC)"

build-android-bundle: ## Build Android App Bundle (AAB)
	@echo "$(BLUE)Building Android App Bundle...$(NC)"
	@$(FLUTTER) build appbundle --release
	@echo "$(GREEN)Android AAB built: $(BUILD_DIR)/app/outputs/bundle/release/app-release.aab$(NC)"

build-ios: ## Build iOS app (debug)
	@echo "$(BLUE)Building iOS app (debug)...$(NC)"
	@$(FLUTTER) build ios --debug --no-codesign
	@echo "$(GREEN)iOS build complete!$(NC)"

build-ios-release: ## Build iOS app (release)
	@echo "$(BLUE)Building iOS app (release)...$(NC)"
	@$(FLUTTER) build ios --release
	@echo "$(GREEN)iOS build complete!$(NC)"

gen-codegen: ## Run code generation (freezed, json_serializable, etc.)
	@echo "$(BLUE)Running code generation...$(NC)"
	@$(FLUTTER) pub run build_runner build --delete-conflicting-outputs
	@echo "$(GREEN)Code generation complete!$(NC)"

gen-codegen-clean: ## Clean generated files
	@echo "$(YELLOW)Cleaning generated files...$(NC)"
	@$(FLUTTER) pub run build_runner clean
	@echo "$(GREEN)Clean complete!$(NC)"

watch: ## Watch for changes and run code generation
	@echo "$(BLUE)Watching for changes...$(NC)"
	@$(FLUTTER) pub run build_runner watch --delete-conflicting-outputs

install: setup ## Alias for setup

run: ## Run the app in debug mode
	@echo "$(BLUE)Running $(PROJECT_NAME)...$(NC)"
	@$(FLUTTER) run

run-android: ## Run on Android device/emulator
	@echo "$(BLUE)Running on Android...$(NC)"
	@$(FLUTTER) run -d android

run-ios: ## Run on iOS device/simulator
	@echo "$(BLUE)Running on iOS...$(NC)"
	@$(FLUTTER) run -d ios

doctor: ## Run Flutter doctor to check environment
	@echo "$(BLUE)Checking Flutter environment...$(NC)"
	@$(FLUTTER) doctor -v

clean-all: clean ## Deep clean including global cache
	@echo "$(YELLOW)Deep cleaning...$(NC)"
	@$(FLUTTER) clean
	@rm -rf ~/.pub-cache/hosted/pub.dev/*$(PROJECT_NAME)*
	@echo "$(GREEN)Deep clean complete!$(NC)"

# CI/CD helpers
ci: format-check analyze test ## Run all CI checks locally
	@echo "$(GREEN)CI checks passed!$(NC)"

pre-commit: format-check analyze test ## Run pre-commit checks
	@echo "$(GREEN)Pre-commit checks passed!$(NC)"

# Development helpers
dev-setup: setup gen-codegen ## Full development environment setup
	@echo "$(GREEN)Development environment ready!$(NC)"

release: ## Prepare for release (run all checks, build release)
	@echo "$(BLUE)Preparing release...$(NC)"
	@$(MAKE) ci
	@$(MAKE) build-android-release
	@$(MAKE) build-ios-release
	@echo "$(GREEN)Release ready!$(NC)"
