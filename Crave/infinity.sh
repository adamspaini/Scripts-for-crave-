#!/bin/bash

rm -rf .repo/local_manifests/

# Rom source repo
repo init --no-repo-verify --git-lfs -u https://github.com/ProjectInfinity-X/manifest -b 16-QPR2 -g default,-mips,-darwin,-notdefault
echo "=================="
echo "Repo init success"
echo "=================="

# Remove existing sources
rm -rf vendor/xiaomi/stone
rm -rf hardware/dolby
rm -rf hardware/xiaomi
rm -rf packages/apps/ViPER4AndroidFX

# Clone Device sources
#git clone https://github.com/Infinity-X-Devices/device_xiaomi_stone.git --depth=1 device/xiaomi/stone
git clone https://github.com/mayuresh2543/vendor_xiaomi_stone.git -b 16.2 --depth=1 vendor/xiaomi/stone
#git clone https://github.com/mayuresh2543/kernel_xiaomi_stone_rebase.git -b 16 --depth=1 kernel/xiaomi/stone
git clone https://github.com/mayuresh-sources/hardware_dolby.git -b sony-1.0 --depth=1 hardware/dolby
git clone https://github.com/LineageOS/android_hardware_xiaomi.git -b lineage-23.2 --depth=1 hardware/xiaomi
git clone https://github.com/mayuresh-sources/packages_apps_ViPER4AndroidFX.git --depth=1 packages/apps/ViPER4AndroidFX
echo "============================"
echo "Device sources clone success"
echo "============================"

# Sync the repositories
/opt/crave/resync.sh
echo "============================"

# Export
export BUILD_USERNAME=mayuresh
export BUILD_HOSTNAME=crave
export TZ="Asia/India"
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

# Lunch
lunch infinity_stone-userdebug
echo "============="

# Install clean
m installclean

# Build rom
m bacon
