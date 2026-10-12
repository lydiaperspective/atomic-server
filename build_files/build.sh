#!/bin/bash

set -ouex pipefail

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

### Install packages

# Packages can be installed from any enabled yum repo on the image.
# RPMfusion repos are available by default in ublue main images
# List of rpmfusion packages can be found here:
# https://mirrors.rpmfusion.org/mirrorlist?path=free/fedora/updates/43/x86_64/repoview/index.html&protocol=https&redirect=1

# Install Nvidia Open Drivers
## Add Repos
dnf5 install -y \
    dnf5-plugins \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

# Add the official NVIDIA container toolkit repo for Fedora/RHEL
dnf5 config-manager addrepo --from-repofile=https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo

# NVIDIA Host Driver & CUDA Packages (GTX 1650 support)
dnf5 install -y \
    akmod-nvidia \
    xorg-x11-drv-nvidia-cuda

# Podman & NVIDIA Container Toolkit (for container GPU passthrough)
dnf5 install -y \
    podman \
    cockpit-podman \
    podman-compose \
    nvidia-container-toolkit

# this installs a package from fedora repos
dnf5 install -y tmux htop git rsync tcpdump pciutils usbutils wireguard-tools firewalld

# Cockpit Web UI Packages
dnf5 install -y cockpit cockpit-files cockpit-networkmanager cockpit-storaged cockpit-system cockpit-ws cockpit-ws-selinux cockpit-bridge cockpit-machines cockpit-ostree

# Storage Support
dnf5 install -y udisks2-lvm2 udisks2-btrfs smartmontools

# Samba file server
dnf5 install -y samba samba-common-tools

### Pre-generate CDI spec for Podman GPU Passthrough
# This generates /etc/cdi/nvidia.yaml so Podman can access the GTX 1650 via --device nvidia.com/gpu=all
mkdir -p /etc/cdi
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

### Add firewall rules
firewall-offline-cmd --add-service=cockpit
firewall-offline-cmd --add-service=samba

# Use a COPR Example:
#
# dnf5 -y copr enable ublue-os/staging
# dnf5 -y install package
# Disable COPRs so they don't end up enabled on the final image:
# dnf5 -y copr disable ublue-os/staging

#### Example for enabling a System Unit File

systemctl enable podman.socket
systemctl enable cockpit.socket
systemctl enable firewalld.service
systemctl enable smb.service

dnf5 clean all
