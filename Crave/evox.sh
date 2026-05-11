#!/bin/bash

rm -rf .repo/local_manifests/

# Rom source repo
repo init -u https://github.com/Evolution-X/manifest -b bq2 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Clone Device sources
git clone https://github.com/Digimend-X-Rodin/android_device_xiaomi_rodin.git device/xiaomi/rodin
git clone --depth=1 https://gitlab.com/ram-unlok/vendor_xiaomi_rodin.git vendor/xiaomi/rodin
git clone https://github.com/Digimend-X-Rodin/android_device_xiaomi_rodin-kernel.git device/xiaomi/rodin-kernel
git clone https://github.com/swiitch-OFF-Lab/hardware_dolby.git -b sony-1.5 hardware/dolby
git clone https://github.com/Digimend-X-Rodin/android_hardware_xiaomi.git hardware/xiaomi
git clone https://github.com/Digimend-X-Rodin/android_hardware_mediatek.git hardware/mediatek
git clone https://github.com/Digimend-X-Rodin/android_device_mediatek_sepolicy_vndr.git device/mediatek/sepolicy_vndr
git clone https://gitlab.com/ram-unlok/bcr.git vendor/bcr
git clone https://gitlab.com/ram-unlok/vendor_PixelPlay.git vendor/PixelPlay
git clone https://rakmoparte@bitbucket.org/ram-unlok/vendor_gcam.git vendor/gcam

# Sync the repositories
/opt/crave/resync.sh
echo "============================"

# Export
export BUILD_USERNAME=Adam
export BUILD_HOSTNAME=crave
export TZ="Asia/India"
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

# Lunch
lunch lineage_rodin-bp4a-userdebug
echo "============="

# Install clean
m installclean

# Build rom
m evolution
