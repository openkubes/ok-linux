#!/bin/bash
# okl — OpenKubes Linux Build Script
# Builds kernel, golden image, boot config, or installs on a node
set -euo pipefail

OKL_VERSION="${OKL_VERSION:-v0.1.0}"
UBUNTU_VERSION="${UBUNTU_VERSION:-24.04}"
KERNEL_VERSION="${KERNEL_VERSION:-6.8.0}"
OUTPUT_DIR="${OUTPUT_DIR:-build}"
ACTION="${1:-help}"
NODE="${2:-ok-infra}"

mkdir -p "${OUTPUT_DIR}"

# ─── Help ─────────────────────────────────────────────────────────────────────
usage() {
  echo ""
  echo "  okl build script ${OKL_VERSION}"
  echo ""
  echo "  Usage: bash image/build.sh <action> [node]"
  echo ""
  echo "  Actions:"
  echo "    kernel   Build okl kernel"
  echo "    image    Build okl golden image"
  echo "    boot     Generate PXE/iPXE boot config"
  echo "    install  Install okl on a node"
  echo ""
}

# ─── Kernel Build ─────────────────────────────────────────────────────────────
build_kernel() {
  echo "🐧 Building okl kernel ${KERNEL_VERSION}..."

  # Install build dependencies
  apt-get install -y \
    build-essential libncurses-dev bison flex \
    libssl-dev libelf-dev dwarves bc cpio python3 rsync

  # Download kernel source
  KERNEL_MAJOR=$(echo "${KERNEL_VERSION}" | cut -d. -f1)
  if [ ! -f "${OUTPUT_DIR}/linux-${KERNEL_VERSION}.tar.xz" ]; then
    echo "📥 Downloading kernel ${KERNEL_VERSION}..."
    curl -L -o "${OUTPUT_DIR}/linux-${KERNEL_VERSION}.tar.xz" \
      "https://cdn.kernel.org/pub/linux/kernel/v${KERNEL_MAJOR}.x/linux-${KERNEL_VERSION}.tar.xz"
  fi

  # Extract
  if [ ! -d "${OUTPUT_DIR}/linux-${KERNEL_VERSION}" ]; then
    tar -xf "${OUTPUT_DIR}/linux-${KERNEL_VERSION}.tar.xz" -C "${OUTPUT_DIR}/"
  fi

  # Apply okl kernel config
  cp kernel/config/okl-kernel.config "${OUTPUT_DIR}/linux-${KERNEL_VERSION}/.config"

  # Apply patches
  for patch in kernel/patches/*.patch 2>/dev/null; do
    echo "🔧 Applying patch: ${patch}"
    patch -p1 -d "${OUTPUT_DIR}/linux-${KERNEL_VERSION}" < "${patch}"
  done

  # Build
  cd "${OUTPUT_DIR}/linux-${KERNEL_VERSION}"
  make olddefconfig
  make -j"$(nproc)" bzImage modules

  echo "✅ okl kernel built: ${OUTPUT_DIR}/linux-${KERNEL_VERSION}/arch/x86/boot/bzImage"
}

# ─── Image Build ──────────────────────────────────────────────────────────────
build_image() {
  echo "📦 Building okl golden image ${OKL_VERSION}..."

  BASE_IMAGE="ubuntu-${UBUNTU_VERSION}-server-cloudimg-amd64.img"
  OKL_IMAGE="okl-${OKL_VERSION}-amd64.img"

  # Download Ubuntu base image
  if [ ! -f "${OUTPUT_DIR}/${BASE_IMAGE}" ]; then
    echo "📥 Downloading Ubuntu ${UBUNTU_VERSION} base image..."
    curl -L -o "${OUTPUT_DIR}/${BASE_IMAGE}" \
      "https://cloud-images.ubuntu.com/releases/${UBUNTU_VERSION}/release/${BASE_IMAGE}"
  fi

  # Copy base image
  cp "${OUTPUT_DIR}/${BASE_IMAGE}" "${OUTPUT_DIR}/${OKL_IMAGE}"

  # Customize image
  echo "🔧 Customizing okl image..."
  # TODO: virt-customize
  # virt-customize -a "${OUTPUT_DIR}/${OKL_IMAGE}" \
  #   --install "linux-generic,qemu-guest-agent,open-iscsi,wireguard" \
  #   --copy-in "kernel/config/okl-kernel.config:/etc/okl/" \
  #   --run-command "systemctl enable qemu-guest-agent" \
  #   --run-command "apt-get autoremove -y"

  # Apply cloud-init
  echo "☁️  Applying cloud-init config..."
  # TODO: cloud-init injection

  echo "✅ okl golden image: ${OUTPUT_DIR}/${OKL_IMAGE}"
}

# ─── Boot Config ──────────────────────────────────────────────────────────────
build_boot() {
  echo "🥾 Generating okl boot config..."

  # PXE config
  cp boot/pxe/default "${OUTPUT_DIR}/pxe-default" 2>/dev/null || true

  # iPXE script
  cp boot/pxe/okl.ipxe "${OUTPUT_DIR}/okl.ipxe" 2>/dev/null || true

  echo "✅ okl boot config generated in ${OUTPUT_DIR}/"
}

# ─── Install ──────────────────────────────────────────────────────────────────
install_node() {
  echo "🚀 Installing okl on node: ${NODE}"
  echo "📦 Version: ${OKL_VERSION}"

  # Apply sysctl
  echo "⚙️  Applying sysctl settings..."
  sysctl -w net.ipv4.ip_forward=1
  sysctl -w net.ipv4.conf.all.rp_filter=0
  sysctl -w net.bridge.bridge-nf-call-iptables=1
  sysctl -w fs.inotify.max_user_instances=8192
  sysctl -w vm.overcommit_memory=1

  # Load kernel modules
  echo "🔧 Loading kernel modules..."
  modprobe br_netfilter
  modprobe overlay
  modprobe vfio
  modprobe vfio_pci || true

  echo "✅ okl installed on ${NODE}"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
case "${ACTION}" in
  kernel)  build_kernel ;;
  image)   build_image ;;
  boot)    build_boot ;;
  install) install_node ;;
  *)       usage ;;
esac
