# Root Makefile for Flutter module projects such as:
#   mobileModule00/ex00
#   mobileModule00/calculator_app
#   mobileModule01/weather_app
#
# Usage examples:
#   make help
#   make version
#   make create MODULE_DIR=mobileModule01 APP=weather_app
#   make pubget MODULE_DIR=mobileModule00 APP=ex00
#   make run MODULE_DIR=mobileModule00 APP=ex00
#   make run MODULE_DIR=mobileModule00 APP=ex00 DEVICE=<id>
#   make chrome MODULE_DIR=mobileModule00 APP=ex00
#   make apk MODULE_DIR=mobileModule00 APP=calculator_app
#   make devices
#   make upgrade
#   make analyze MODULE_DIR=mobileModule00 APP=ex00
#   make doctor
#   make format MODULE_DIR=mobileModule00 APP=ex00
#   make clean MODULE_DIR=mobileModule00 APP=ex00

# --------------------------------------------------
# Config
# --------------------------------------------------

# Folder containing this root Makefile.
PROJECT_ROOT := $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Module folder to target, for example mobileModule00 or mobileModule01.
MODULE_DIR ?= mobileModule00

# App/project folder inside MODULE_DIR, for example ex00 or weather_app.
APP ?= ex00

# Optional Flutter device id, for example chrome, linux, or an Android serial.
DEVICE ?=

# Resolved module path. Absolute MODULE_DIR values are allowed.
MODULE_PATH := $(if $(filter /%,$(MODULE_DIR)),$(MODULE_DIR),$(PROJECT_ROOT)/$(MODULE_DIR))

# Resolved Flutter app path.
APP_DIR := $(MODULE_PATH)/$(APP)

# Optional format target path inside the app.
# Default is the common Flutter source folders.
FORMAT_PATH ?= lib test

# --------------------------------------------------
# Helpers
# --------------------------------------------------

.PHONY: help check version doctor upgrade devices create pubget chrome run web-server clean format analyze apk

help:
	@echo "Flutter root Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> MODULE_DIR=mobileModule00 APP=ex00"
	@echo ""
	@echo "Examples:"
	@echo "  make create MODULE_DIR=mobileModule01 APP=weather_app"
	@echo "  make pubget MODULE_DIR=mobileModule00 APP=ex00"
	@echo "  make run MODULE_DIR=mobileModule00 APP=ex00 DEVICE=<id>"
	@echo "  make chrome MODULE_DIR=mobileModule00 APP=ex00"
	@echo "  make apk MODULE_DIR=mobileModule00 APP=calculator_app"
	@echo ""
	@echo "Targets in logical order:"
	@echo "  version   - Show Flutter version"
	@echo "  doctor    - Check Flutter/toolchain setup"
	@echo "  upgrade   - Upgrade Flutter SDK"
	@echo "  devices   - List available devices"
	@echo "  create    - Create a new Flutter project at MODULE_DIR/APP"
	@echo "  pubget    - Fetch project dependencies"
	@echo "  run       - Run app, optionally with DEVICE=<id>"
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

# Create a new Flutter project at APP inside MODULE_DIR.
# Example:
#   make create MODULE_DIR=mobileModule01 APP=weather_app
#
# This fails if the folder already exists.
create:
	@if [ -e "$(APP_DIR)" ]; then \
		echo "Error: path already exists: $(APP_DIR)"; \
	else \
		mkdir -p "$(MODULE_PATH)"; \
		flutter create "$(APP_DIR)"; \
	fi

# --------------------------------------------------
# Project dependency / maintenance
# --------------------------------------------------

# Fetch project dependencies from pubspec.yaml.
pubget: check
	cd "$(APP_DIR)" && flutter pub get

# Format common source folders by default.
# Override with:
#   make format MODULE_DIR=mobileModule00 APP=ex00 FORMAT_PATH=lib
#   make format MODULE_DIR=mobileModule00 APP=ex00 FORMAT_PATH="lib test"
format: check
	cd "$(APP_DIR)" && dart format $(FORMAT_PATH)

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
# Override with:
#   make run MODULE_DIR=mobileModule00 APP=ex00 DEVICE=chrome
#   make run MODULE_DIR=mobileModule00 APP=ex00 DEVICE=<android-device-id>
run: check
	cd "$(APP_DIR)" && flutter pub get && flutter run $(if $(DEVICE),-d $(DEVICE),)

# Run on Chrome.
# Requires Flutter web support and Chrome/Chromium available in the VM.
# No issue in VM, but throws error when run from VS Code Terminal
chrome: check
	cd "$(APP_DIR)" && flutter pub get && flutter run -d chrome

# Run on web-server
# No issue running from VS Code Terminal or VM
# ---release, to avoid WebSocket error which is not included in release builds
web-server: check
	cd "$(APP_DIR)" && flutter run -d web-server \
    --web-hostname 0.0.0.0 \
    --web-port 8080 \
    --release

# --------------------------------------------------
# Build
# --------------------------------------------------

# Build an installable Android APK.
apk: check
	cd "$(APP_DIR)" && flutter pub get && flutter build apk
