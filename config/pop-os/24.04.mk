DISTRO_NAME=Pop_OS

ifeq ($(NVIDIA),1)
DISTRO_VOLUME_LABEL=$(DISTRO_NAME) $(DISTRO_VERSION) $(DISTRO_ARCH) NVIDIA
else
DISTRO_VOLUME_LABEL=$(DISTRO_NAME) $(DISTRO_VERSION) $(DISTRO_ARCH)
endif

# Show splash screen
#TODO DISTRO_PARAMS+=quiet splash

GNOME_INITIAL_SETUP_STAMP=21.04

# DEB822 format system repositories, comment out to disable
DEB822:=1
APPS_URI:=http://apt.pop-os.org/proprietary
APPS_KEY=/etc/apt/trusted.gpg.d/pop-keyring-2017-archive.gpg

# Repositories to be present in installed system
RELEASE_URI:=http://apt.pop-os.org/release
RELEASE_KEY=/etc/apt/trusted.gpg.d/pop-keyring-2017-archive.gpg

# Use proposed repositories instead, if requested
ifeq ($(PROPOSED),1)
RELEASE_URI:=http://apt.pop-os.org/staging/master
endif

# Packages to install
#TODO: cosmic-term is before pop-desktop to ensure it fulfills all x-terminal-emulator depends
#TODO: linux-system76 is added since pop-server depends on linux-raspi for arm64
DISTRO_PKGS=\
	systemd \
	cosmic-term \
	linux-system76 \
	pop-desktop

# Packages to install after (to avoid dependency issues)
# Packages to install after (to avoid dependency issues)
ifeq ($(DISTRO_ARCH),amd64)
POST_DISTRO_PKGS=\  
    system76-acpi-dkms \
    system76-dkms \
    system76-io-dkms \
    torch \
    tensorflow
else
POST_DISTRO_PKGS=\  
    torch \
    tensorflow
endif


# DKMS packages on Pop try to build with gcc-12, and it needs to be installed
#TODO: figure out why this is not already a dependency
POST_DISTRO_PKGS+=gcc-14

#TODO: rsync is added because it is not depended on by anything except distinst
# When distinst is removed from the installation, rsync is not available for
# syncing the recovery partition
POST_DISTRO_PKGS+=rsync

#TODO: systemd-boot is added because it is not depended on by anything
# This was broken out from the systemd package for 24.04 and should be
# added to pop-desktop and/or kernelstub
POST_DISTRO_PKGS+=systemd-boot

#TODO: revisit whether these kernel params need to be explicitly invoked
# This has been hard-set as a short term fix tied to the Nvidia ISOs'
# inability to successfully reach a GUI session with the state of
# COSMIC in the alpha ISO release.
ifeq ($(NVIDIA),1)
DISTRO_PARAMS+=modules_load=nvidia
DISTRO_PARAMS+=nvidia-drm.modeset=1
POST_DISTRO_PKGS+=nvidia-driver-570-open
ifeq ($(DISTRO_ARCH),amd64)
POST_DISTRO_PKGS+=amd-ppt-bin
endif
endif

# Staging branches to use when building ISO.
# No values is the same as building from release
# `branch-name` is equivalent to `apt-manage add popdev:branch-name -y`
STAGING_BRANCHES=

# Packages to have in live instance
LIVE_PKGS=\
	casper \
	distinst \
	expect \
	gparted \
	pop-installer \
	pop-installer-casper

# Packages to remove from installed system (usually installed as Recommends)
RM_PKGS=\
	ibus-mozc \
	imagemagick-6.q16 \
	irqbalance \
	mozc-utils-gui \
	pop-installer-session \
	snapd \
	ubuntu-advantage-tools \
	ubuntu-minimal \
	ubuntu-session \
	ubuntu-wallpapers \
	unattended-upgrades \
	xul-ext-ubufox \
	yaru-theme-gnome-shell

# Packages not installed, but that may need to be discovered by the installer
ifeq ($(DISTRO_ARCH),amd64)
MAIN_POOL=\
	at \
	dfu-programmer \
	efibootmgr \
	ethtool \
	grub-efi-amd64 \
	grub-efi-amd64-bin \
	grub-efi-amd64-signed \
	grub-pc \
	grub-pc-bin \
	grub-gfxpayload-lists \
	hdparm \
	kernelstub \
	libfl2 \
	libx86-1 \
	lm-sensors \
	pm-utils \
	pop-hp-vendor \
	pop-hp-vendor-dkms \
	pop-hp-wallpapers \
	postfix \
	powermgmt-base \
	python3-debian \
	python3-distro \
	python3-evdev \
	python3-systemd \
	system76-driver \
	system76-firmware-daemon \
	system76-oled \
	system76-wallpapers \
	vbetool \
	xbacklight
# TODO: system76-driver deps should be revisited: https://github.com/pop-os/system76-driver/issues/292
MAIN_POOL+=\
	firmware-manager \
	firmware-manager-notify \
	firmware-manager-shared \
	gir1.2-notify-0.7 \
	gnome-shell-extension-system76-power \
	hidpi-daemon \
	python3-pydbus \
	python3-xlib \
	system76-power
else ifeq ($(DISTRO_ARCH),arm64)
MAIN_POOL=\
	efibootmgr \
	grub-efi-arm64 \
	grub-efi-arm64-bin \
	grub-efi-arm64-signed \
	kernelstub
else
MAIN_POOL=
endif

ifeq ($(NVIDIA),1)
MAIN_POOL+=\
	system76-driver-nvidia
endif

# Additional pool packages from the restricted set of packages
ifeq ($(DISTRO_ARCH),amd64)
RESTRICTED_POOL=\
	amd64-microcode \
	intel-microcode \
	iucode-tool
else
RESTRICTED_POOL=
endif

# Extra packages to install in the pool for use by iso creation
POOL_PKGS=\
	grub-efi-$(DISTRO_ARCH)-bin \
	grub-efi-$(DISTRO_ARCH)-signed \
	shim-signed

ifeq ($(HP),1)
DISTRO_VOLUME_LABEL=$(DISTRO_NAME) $(DISTRO_VERSION) $(DISTRO_ARCH) HP
POST_DISTRO_PKGS+=\
	pop-hp-vendor \
	pop-hp-vendor-dkms \
	pop-hp-wallpapers
RM_PKGS+=\
	pop-wallpapers
LIVE_PKGS+=\
	dbus-x11
endif
