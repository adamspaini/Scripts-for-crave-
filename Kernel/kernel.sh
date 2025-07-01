#!/bin/bash
#
# Stone Kernel Compile Script
# Modified from original by @enamulhasanabid
# Enhanced for clean output and readable code structure
#

set -e

# ---------------------------------------------
# Configuration Variables
# ---------------------------------------------
DEFAULT_CLANG_URL="https://gitlab.com/crdroidandroid/android_prebuilts_clang_host_linux-x86_clang-r547379/-/archive/15.0/android_prebuilts_clang_host_linux-x86_clang-r547379-15.0.tar.gz"
ANYKERNEL_REPO="https://github.com/osm0sis/AnyKernel3.git"

# Directory paths
SCRIPT_DIR="$(pwd)"
KERNEL_DIR="${SCRIPT_DIR}/kernel_source"
ANYKERNEL_DIR="${SCRIPT_DIR}/AnyKernel3"
OUTPUT_DIR="${SCRIPT_DIR}/out"
CLANG_DIR="${SCRIPT_DIR}/clang"
ZIP_NAME="stone-kernel-$(date +%Y%m%d-%H%M).zip"

# Build environment
export KBUILD_BUILD_USER="android-build"
export KBUILD_BUILD_HOST="localhost"
export SOURCE_DATE_EPOCH=$(date +%s)
export BUILD_REPRODUCIBLE=1

# CPU allocation (80% of cores)
TOTAL_CORES=$(nproc)
JOBS=$(( TOTAL_CORES * 8 / 10 ))
JOBS=$(( JOBS < 1 ? 1 : JOBS ))

# AnyKernel3 settings
AK3_KERNEL_STRING="Darkmoon"
AK3_DO_DEVICECHECK=1
AK3_DEVICE_NAME1="moonstone"
AK3_DEVICE_NAME2="sunstone"
AK3_DEVICE_NAME3="stone"
AK3_DO_CLEANUP=1

# Start build timer
START_TIME=$(date +%s)

# ---------------------------------------------
# User Input Prompts
# ---------------------------------------------
echo "============================================="
echo " Stone Kernel Build Script"
echo "============================================="
echo
echo "Enter Clang toolchain URL (press Enter for default):"
echo "Default: $DEFAULT_CLANG_URL"
read -r CLANG_URL
CLANG_URL=${CLANG_URL:-$DEFAULT_CLANG_URL}
if [ -z "$CLANG_URL" ]; then
    echo "Error: Clang URL cannot be empty!"
    exit 1
fi

echo
echo "Enter kernel repository URL (e.g., https://github.com/user/kernel.git):"
read -r KERNEL_REPO
if [ -z "$KERNEL_REPO" ]; then
    echo "Error: Kernel repository URL cannot be empty!"
    exit 1
fi

echo
echo "Enter kernel branch (e.g., main):"
read -r KERNEL_BRANCH
if [ -z "$KERNEL_BRANCH" ]; then
    echo "Error: Kernel branch cannot be empty!"
    exit 1
fi

echo
echo "Enter kernel directory name (e.g., my_kernel):"
read -r KERNEL_DIR_NAME
if [ -z "$KERNEL_DIR_NAME" ]; then
    echo "Error: Kernel directory name cannot be empty!"
    exit 1
fi
KERNEL_DIR="${SCRIPT_DIR}/${KERNEL_DIR_NAME}"

# ---------------------------------------------
# Build Setup
# ---------------------------------------------
echo
echo "============================================="
echo " Build Information"
echo "============================================="
echo "Device: stone"
echo "CPU Cores: $JOBS / $TOTAL_CORES"
echo "Build User: $KBUILD_BUILD_USER"
echo "Build Host: $KBUILD_BUILD_HOST"
echo "Output ZIP: $ZIP_NAME"
echo "============================================="

# Check required commands
for cmd in git curl tar unzip ldconfig make; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' not found."
        exit 1
    fi
done

# Clean previous builds
echo
echo "Cleaning previous build artifacts..."
rm -rf "$OUTPUT_DIR" "$ANYKERNEL_DIR"
mkdir -p "$OUTPUT_DIR"

# ---------------------------------------------
# Toolchain Setup
# ---------------------------------------------
echo
echo "============================================="
echo " Setting Up Toolchain"
echo "============================================="
if [ ! -d "$CLANG_DIR" ]; then
    echo "Downloading and extracting Clang toolchain..."
    mkdir -p "$CLANG_DIR"
    if [[ "$CLANG_URL" == *.tar.gz ]]; then
        curl -L "$CLANG_URL" | tar xz -C "$CLANG_DIR" --strip-components=1
    elif [[ "$CLANG_URL" == *.zip ]]; then
        temp_zip="${CLANG_DIR}/clang.zip"
        curl -L "$CLANG_URL" -o "$temp_zip"
        unzip "$temp_zip" -d "$CLANG_DIR/temp"
        mv "$CLANG_DIR"/temp/*/* "$CLANG_DIR/"
        rm -rf "$temp_zip" "$CLANG_DIR/temp"
    fi
fi

# Verify toolchain binaries
echo "Verifying Clang toolchain..."
for tool in clang ld.lld llvm-ar llvm-nm llvm-strip llvm-objcopy llvm-objdump; do
    if [ ! -f "$CLANG_DIR/bin/$tool" ]; then
        echo "Error: $tool not found in $CLANG_DIR/bin!"
        exit 1
    fi
done
export PATH="$CLANG_DIR/bin:$PATH"
echo "Toolchain path: $CLANG_DIR"

# ---------------------------------------------
# Kernel Source Setup
# ---------------------------------------------
echo
echo "============================================="
echo " Preparing Kernel Source"
echo "============================================="
if [ ! -d "$KERNEL_DIR" ]; then
    echo "Cloning kernel source from $KERNEL_REPO (branch: $KERNEL_BRANCH)..."
    git clone --depth=1 -b "$KERNEL_BRANCH" "$KERNEL_REPO" "$KERNEL_DIR"
else
    echo "Updating kernel source..."
    cd "$KERNEL_DIR"
    git fetch origin "$KERNEL_BRANCH"
    git reset --hard origin/"$KERNEL_BRANCH"
    git clean -fdx
    cd ..
fi

# ---------------------------------------------
# AnyKernel3 Setup
# ---------------------------------------------
echo
echo "============================================="
echo " Configuring AnyKernel3"
echo "============================================="
echo "Cloning AnyKernel3 repository..."
git clone --depth=1 "$ANYKERNEL_REPO" "$ANYKERNEL_DIR"

echo "Generating AnyKernel3 configuration..."
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

# ---------------------------------------------
# Kernel Compilation
# ---------------------------------------------
echo
echo "============================================="
echo " Building Kernel"
echo "============================================="
cd "$KERNEL_DIR"
echo "Configuring kernel..."
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

make O="$OUTPUT_DIR" distclean
make O="$OUTPUT_DIR" mrproper
git clean -fdx
git reset --hard
make O="$OUTPUT_DIR" stone_defconfig
echo 'CONFIG_LOCALVERSION="-secure"' >> "$OUTPUT_DIR/.config"

echo "Compiling kernel with $JOBS cores..."
make O="$OUTPUT_DIR" -j"$JOBS" \
    LOCALVERSION= \
    KBUILD_BUILD_USER="$KBUILD_BUILD_USER" \
    KBUILD_BUILD_HOST="$KBUILD_BUILD_HOST"

# Verify build
IMAGE="$OUTPUT_DIR/arch/arm64/boot/Image"
if [ ! -f "$IMAGE" ]; then
    echo "Error: Kernel Image not found!"
    exit 1
fi

# ---------------------------------------------
# Packaging
# ---------------------------------------------
echo
echo "============================================="
echo " Creating Flashable ZIP"
echo "============================================="
echo "Copying build artifacts..."
cp "$IMAGE" "$ANYKERNEL_DIR/"
[ -f "$OUTPUT_DIR/arch/arm64/boot/dtbo.img" ] && cp "$OUTPUT_DIR/arch/arm64/boot/dtbo.img" "$ANYKERNEL_DIR/"
[ -f "$OUTPUT_DIR/arch/arm64/boot/dtb.img" ] && cp "$OUTPUT_DIR/arch/arm64/boot/dtb.img" "$ANYKERNEL_DIR/"

echo "Packaging flashable ZIP..."
cd "$ANYKERNEL_DIR"
zip -r9 "../$ZIP_NAME" * -x '*.git*' '*.md' '*.placeholder'
cd ..

# ---------------------------------------------
# Completion
# ---------------------------------------------
BUILD_DURATION=$(( $(date +%s) - START_TIME ))
echo
echo "============================================="
echo " Build Completed Successfully"
echo "============================================="
echo "Flashable ZIP: $ZIP_NAME"
echo "Location: $SCRIPT_DIR/$ZIP_NAME"
echo "Cores Utilized: $JOBS"
echo "Build Duration: $BUILD_DURATION seconds"
echo "============================================="