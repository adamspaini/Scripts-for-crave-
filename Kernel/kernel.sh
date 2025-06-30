#!/bin/bash
#
# Compile script for Stone Kernel
# Credits to @enamulhasanabid for base script

set -e

# =============================================
# CONFIGURATION
# =============================================
KERNEL_REPO="https://github.com/kamikaonashi/private_kernel_stone.git"
KERNEL_BRANCH="16"
KERNEL_DIR="private_kernel_stone"

ANYKERNEL_REPO="https://github.com/osm0sis/AnyKernel3.git"
ANYKERNEL_DIR="$(pwd)/AnyKernel3"

DEVICE="stone"
OUTPUT_DIR="$(pwd)/out"
ZIP_NAME="stone-kernel-$(date +%Y%m%d-%H%M).zip"

# Toolchain (AOSP Clang 21+ for Android 15)
CLANG_URL="https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379/-/archive/15.0/android_prebuilts_clang_host_linux-x86_clang-r547379-15.0.tar.gz"
CLANG_DIR="$(pwd)/clang"

# Configuration
export KBUILD_BUILD_USER="android-build"
export KBUILD_BUILD_HOST="localhost"
export SOURCE_DATE_EPOCH=$(date +%s)
export BUILD_REPRODUCIBLE=1

# Safer CPU allocation (80% of available cores)
TOTAL_CORES=$(nproc)
JOBS=$(( TOTAL_CORES * 8 / 10 ))
JOBS=$(( JOBS < 1 ? 1 : JOBS ))  # Ensure at least 1 job

# AnyKernel3 Configuration Variables
AK3_KERNEL_STRING="Darkmoon"
AK3_DO_DEVICECHECK=1
AK3_DEVICE_NAME1="moonstone"
AK3_DEVICE_NAME2="sunstone"
AK3_DEVICE_NAME3="gemstone"
AK3_DEVICE_NAME4="stone"
AK3_DO_CLEANUP=1

# =============================================
# PRE-BUILD SETUP
# =============================================
echo "=== Kernel Build Script ==="
echo "Device: $DEVICE"
echo "Using CPU Cores: $JOBS / $TOTAL_CORES"
echo "Build User: $KBUILD_BUILD_USER"
echo "Build Host: $KBUILD_BUILD_HOST"

# libxml2 workaround
if ! ldconfig -p | grep -q "libxml2.so.2"; then
    echo "Applying libxml2 workaround..."
    sudo ln -sf /usr/lib/libxml2.so.16 /usr/lib/libxml2.so.2
    sudo ldconfig
fi

# Clean previous builds
echo "Cleaning previous builds..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

[ -d "$ANYKERNEL_DIR" ] && rm -rf "$ANYKERNEL_DIR"

# =============================================
# TOOLCHAIN
# =============================================
if [ ! -d "$CLANG_DIR" ]; then
    echo "Downloading and extracting Clang toolchain..."
    mkdir -p "$CLANG_DIR"
    curl -L "$CLANG_URL" | tar xz -C "$CLANG_DIR" --strip-components=1
fi

export PATH="$CLANG_DIR/bin:$PATH"
echo "Toolchain path: $CLANG_DIR"

# =============================================
# KERNEL SOURCE
# =============================================
if [ ! -d "$KERNEL_DIR" ]; then
    echo "Cloning kernel source..."
    git clone --depth=1 -b "$KERNEL_BRANCH" "$KERNEL_REPO" "$KERNEL_DIR"
else
    echo "Updating kernel source..."
    cd "$KERNEL_DIR"
    git reset --hard
    git clean -fdx
    git pull
    cd ..
fi

# =============================================
# ANYKERNEL3 SETUP
# =============================================
echo "Setting up AnyKernel3..."
git clone --depth=1 "$ANYKERNEL_REPO" "$ANYKERNEL_DIR"

echo "Configuring anykernel.sh..."
cat > "$ANYKERNEL_DIR/anykernel.sh" <<EOF
#!/bin/bash

### AnyKernel3 Ramdisk Mod Script
## osm0sis @ xda-developers

### AnyKernel setup
properties() { '
kernel.string=$AK3_KERNEL_STRING
do.devicecheck=$AK3_DO_DEVICECHECK
device.name1=$AK3_DEVICE_NAME1
device.name2=$AK3_DEVICE_NAME2
device.name3=$AK3_DEVICE_NAME3
device.name4=$AK3_DEVICE_NAME4
do.cleanup=$AK3_DO_CLEANUP
'; }

block=boot;
is_slot_device=auto;
no_block_display=1;

. tools/ak3-core.sh;

split_boot;
flash_boot;
EOF

chmod +x "$ANYKERNEL_DIR/anykernel.sh"

# =============================================
# BUILD CONFIGURATION
# =============================================
cd "$KERNEL_DIR"
echo "Configuring kernel..."

make ARCH=arm64 distclean
make ARCH=arm64 mrproper
git clean -fdx
git reset --hard

export ARCH=arm64
export SUBARCH=arm64
export LLVM=1
export LLVM_IAS=1
export CC="clang"
export LD="ld.lld"
export AR="llvm-ar"
export NM="llvm-nm"
export STRIP="llvm-strip"
export OBJCOPY="llvm-objcopy"
export OBJDUMP="llvm-objdump"
export CLANG_TRIPLE="aarch64-linux-gnu-"
export CROSS_COMPILE="aarch64-linux-gnu-"
export CROSS_COMPILE_ARM32="arm-linux-gnueabi-"

# Use defconfig and optionally tweak
make O="$OUTPUT_DIR" stone_defconfig
echo 'CONFIG_LOCALVERSION="-secure"' >> "$OUTPUT_DIR/.config"

# =============================================
# COMPILATION
# =============================================
echo "Starting kernel compilation..."
make O="$OUTPUT_DIR" -j"$JOBS" \
    LOCALVERSION= \
    KBUILD_BUILD_USER="$KBUILD_BUILD_USER" \
    KBUILD_BUILD_HOST="$KBUILD_BUILD_HOST"

# Check for Image
IMAGE="$OUTPUT_DIR/arch/arm64/boot/Image"
DTBO="$OUTPUT_DIR/arch/arm64/boot/dtbo.img"
DTB="$OUTPUT_DIR/arch/arm64/boot/dtb.img"

if [ ! -f "$IMAGE" ]; then
    echo "❌ Kernel Image not found!"
    exit 1
fi

# =============================================
# PACKAGE
# =============================================
echo "Preparing flashable package..."

cp -v "$IMAGE" "$ANYKERNEL_DIR/"
[ -f "$DTBO" ] && cp -v "$DTBO" "$ANYKERNEL_DIR/"
[ -f "$DTB" ] && cp -v "$DTB" "$ANYKERNEL_DIR/"

cd "$ANYKERNEL_DIR"
zip -r9 "../$ZIP_NAME" * -x '*.git*' '*.md' '*.placeholder'
cd ..

echo "✅ Build Complete!"
echo "Flashable zip: $ZIP_NAME"
echo "Built using: $JOBS core(s)"
