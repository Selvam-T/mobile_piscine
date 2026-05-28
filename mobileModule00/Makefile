# Makefile for Flutter exercises such as:
#   ex00
#   ex01
#
# Usage examples:
#   make help
#   make version
#   make create APP=ex00     		---> creates ex00
#   make pubget APP=ex00     		---> refresh dependencies (ex: after flutter create)
#   make run APP=ex00        		---> runs ex00 in default device
#   make run APP=ex00 DEVICE=<id> 	---> runs ex00 in specified device
#   make chrome APP=ex00     		---> runs ex00 in Chrome
#   make apk APP=ex00        		---> builds the APK for that exercise
#   make devices             		---> to see list of recognized devices
#   make upgrade             		---> update the SDK to the latest version
#   make analyze APP=ex00    		---> perform static analysis of Dart source code
#   make doctor              		---> diagnose health of flutter development environment
#   make format APP=ex00     		---> format all .dart files recursively under that dir
#   make clean APP=ex00      		---> only when you want to rebuild

# --------------------------------------------------
# Config
# --------------------------------------------------

# Exercise folder to target, for example ex00 or ex01.
APP ?= ex00

# Optional Flutter device id, for example chrome, linux, or an Android serial.
DEVICE ?=

# Folder containing this Makefile and all exercise projects.
MODULE_DIR ?= $(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))

# Resolved Flutter app path.
APP_DIR := $(MODULE_DIR)/$(APP)

# Optional format target path inside the app.
# Default is the common Flutter source folders.
FORMAT_PATH ?= lib test

# --------------------------------------------------
# Helpers
# --------------------------------------------------

.PHONY: help check version doctor upgrade devices create pubget chrome run web-server clean format analyze apk

help:
	@echo "Flutter Makefile"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> APP=ex00"
	@echo ""
	@echo "Examples:"
	@echo "  make create APP=ex00"
	@echo "  make pubget APP=ex00"
	@echo "  make run APP=ex00 DEVICE=<id>"
	@echo "  make chrome APP=ex00"
	@echo "  make apk APP=ex00"
	@echo ""
	@echo "Targets in logical order:"
	@echo "  version   - Show Flutter version"
	@echo "  doctor    - Check Flutter/toolchain setup"
	@echo "  upgrade   - Upgrade Flutter SDK"
	@echo "  devices   - List available devices"
	@echo "  create    - Create a new Flutter project at APP"
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

# Create a new Flutter project at APP inside this module folder.
# Example:
#   make create APP=ex02
#
# This fails if the folder already exists.
create:
	@if [ -e "$(APP_DIR)" ]; then \
		echo "Error: path already exists: $(APP_DIR)"; \
	else \
		mkdir -p "$(MODULE_DIR)"; \
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
#   make format APP=ex00 FORMAT_PATH=lib
#   make format APP=ex00 FORMAT_PATH="lib test"
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
#   make run APP=ex00 DEVICE=chrome
#   make run APP=ex00 DEVICE=<android-device-id>
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
