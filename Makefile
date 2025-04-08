# Configuration settings
DISTRO_CODE?=pop-os
DISTRO_VERSION?=22.04
DISTRO_ARCH?=$(shell dpkg --print-architecture)

DISTRO_EPOCH?=$(shell date +%s)
DISTRO_DATE?=$(shell date +%Y%m%d)

DISTRO_PARAMS?=

ISO_NAME?=$(DISTRO_CODE)_$(DISTRO_VERSION)_$(DISTRO_ARCH)

GPG_NAME?=`id -un`

PROPOSED?=0
NVIDIA?=0
HP?=0

# Include automatic variables
include mk/automatic.mk

# Include Ubuntu definitions
include mk/ubuntu.mk

# Language packages
include mk/language.mk

# Include configuration file
include config/$(DISTRO_CODE)/$(DISTRO_VERSION).mk

# Standard target - build the ISO
iso: $(ISO)
	@echo "Installing CUDA and PyTorch with CUDA support"
	sudo apt-get update
	sudo apt-get install -y cuda

	@echo "Installing GPU Monitor dependencies"
	sudo apt-get install -y python3-tk python3-pip
	pip install pynvml matplotlib

	@echo "Copying GPU Monitor files to ISO build"
	sudo mkdir -p $(BUILD_DIR)/opt/gpu-monitor
	sudo cp path/to/gpu.py $(BUILD_DIR)/opt/gpu-monitor/
	sudo cp path/to/gpu.png $(BUILD_DIR)/opt/gpu-monitor/  # optional icon

	@echo "Creating .desktop shortcut"
	sudo mkdir -p $(BUILD_DIR)/usr/share/applications
	echo "[Desktop Entry]\n\
Name=GPU Monitor\n\
Exec=python3 /opt/gpu-monitor/gpu.py\n\
Icon=/opt/gpu-monitor/gpu.png\n\
Type=Application\n\
Categories=Utility;" | sudo tee $(BUILD_DIR)/usr/share/applications/gpu-monitor.desktop

	@echo "Set executable permission for script"
	sudo chmod +x $(BUILD_DIR)/opt/gpu-monitor/gpu.py

tar: $(TAR)

usb: $(USB)

# Complete target - build zsync file, SHA256SUMS, and GPG signature
all: $(ISO) $(ISO).zsync $(BUILD)/SHA256SUMS $(BUILD)/SHA256SUMS.gpg

serve: all
	cd $(BUILD) && python3 -m http.server 8909

# Popsicle target
popsicle: $(ISO)
	sudo popsicle-gtk "$(ISO)"

# Clean target
include mk/clean.mk

# Germinate target
include mk/germinate.mk

# QEMU targets
include mk/qemu.mk

# Chroot targets
include mk/chroot.mk

# Update targets
include mk/update.mk

# ISO targets
include mk/iso.mk

# Force target
FORCE:
