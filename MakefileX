# Root-level Makefile for Flutter exercises such as:
#   mobileModule00/ex00
#   mobileModule00/ex01
#
# Usage examples:
#   make help
#   make version
#   make doctor
#   make create APP=ex00
#   make pubget APP=ex00
#   make chrome APP=ex00
#   make run APP=ex00
#   make devices
#   make analyze APP=ex00
#   make format APP=ex00
#   make clean APP=ex00
#   make apk APP=ex00
#   make upgrade

# --------------------------------------------------
# Config
# --------------------------------------------------

# Exercise folder to target, for example ex00 or ex01.
APP ?= ex00

# Parent folder containing all exercise projects.
MODULE_DIR ?= mobileModule00

# Resolved Flutter app path.
APP_DIR := $(MODULE_DIR)/$(APP)

# Optional format target path inside the app.
# Default is the common Flutter source folders.
FORMAT_PATH ?= lib test

# --------------------------------------------------
# Helpers
# --------------------------------------------------

.PHONY: help check version doctor upgrade devices create pubget chrome run clean format analyze apk

help:
	@echo "Flutter Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> APP=ex00"
	@echo ""
	@echo "Examples:"
	@echo "  make create APP=ex00"
	@echo "  make pubget APP=ex00"
	@echo "  make chrome APP=ex00"
	@echo "  make apk APP=ex00"
	@echo ""
	@echo "Targets in logical order:"
	@echo "  version   - Show Flutter version"
	@echo "  doctor    - Check Flutter/toolchain setup"
	@echo "  upgrade   - Upgrade Flutter SDK"
	@echo "  devices   - List available devices"
	@echo "  create    - Create a new Flutter project at MODULE_DIR/APP"
	@echo "  pubget    - Fetch project dependencies"
	@echo "  run       - Run app with default selected device"
	@echo "  chrome    - Run app on Chrome"
	@echo "  format    - Format source files"
	@echo "  analyze   - Run static analysis"
	@echo "  clean     - Remove build artifacts"
	@echo "  apk       - Build installable Android APK"

# Verify that the selected app folder exists and contains pubspec.yaml.
check:
	@test -d "$(APP_DIR)" || (echo "Error: folder not found: $(APP_DIR)"; exit 1)
	@test -f "$(APP_DIR)/pubspec.yaml" || (echo "Error: pubspec.yaml not found in $(APP_DIR)"; exit 1)

# --------------------------------------------------
# SDK / Environment
# --------------------------------------------------

# Show Flutter SDK version.
version:
	flutter --version

# Check Flutter installation and platform tooling.
doctor:
	flutter doctor

# Upgrade Flutter SDK.
upgrade:
	flutter upgrade

# List detected devices, including Chrome if web support is available.
devices:
	flutter devices

# --------------------------------------------------
# Project creation
# --------------------------------------------------

# Create a new Flutter project at MODULE_DIR/APP.
# Example:
#   make create APP=ex02
#
# This fails if the folder already exists.
create:
	@test ! -e "$(APP_DIR)" || (echo "Error: path already exists: $(APP_DIR)"; exit 1)
	mkdir -p "$(MODULE_DIR)"
	flutter create "$(APP_DIR)"

# --------------------------------------------------
# Project dependency / maintenance
# --------------------------------------------------

# Fetch project dependencies from pubspec.yaml.
pubget: check
	cd "$(APP_DIR)" && flutter pub get

# Format common source folders by default.
# Override with:
#   make format APP=ex00 FORMAT_PATH=lib
#   make format APP=ex00 FORMAT_PATH="lib test"
format: check
	cd "$(APP_DIR)" && flutter format $(FORMAT_PATH)

# Analyze the project for issues.
analyze: check
	cd "$(APP_DIR)" && flutter analyze

# Remove generated build artifacts.
clean: check
	cd "$(APP_DIR)" && flutter clean

# --------------------------------------------------
# Running
# --------------------------------------------------

# Run with Flutter's default selected device.
# Useful if only one device is available.
run: check
	cd "$(APP_DIR)" && flutter pub get && flutter run

# Run specifically on Chrome.
# Requires Flutter web support and Chrome/Chromium available in the VM.
chrome: check
	cd "$(APP_DIR)" && flutter pub get && flutter run -d chrome

# --------------------------------------------------
# Build
# --------------------------------------------------

# Build an installable Android APK.
apk: check
	cd "$(APP_DIR)" && flutter pub get && flutter build apk
