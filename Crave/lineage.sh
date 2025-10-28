#!/bin/bash

rm -rf .repo/local_manifests/
rm -rf vendor/lineage

# Rom source repo
repo init -u https://github.com/LineageOS/android.git -b lineage-23.0 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Clone local_manifests repository
git clone -b lineage-16 https://github.com/Mayuresh2543/local_manifests.git .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Sync the repositories
/opt/crave/resync.sh
echo "============================"

rm -rf vendor/lineage
git clone https://github.com/mayuresh2543/android_vendor_lineage.git --depth=1 vendor/lineage

rm -rf packages/apps/Updater
git clone https://github.com/mayuresh-releases/lineage_packages_apps_Updater.git --depth=1 packages/apps/Updater

rm -rf packages/apps/Launcher3
git clone https://github.com/mayuresh2543/lineage_packages_apps_Launcher3.git --depth=1 packages/apps/Launcher3

rm -rf frameworks/av
git clone https://github.com/mayuresh2543/lineage_frameworks_av.git --depth=1 frameworks/av

rm -rf device/xiaomi/stone
git clone https://github.com/mayuresh2543/device_xiaomi_stone_rebase.git device/xiaomi/stone

rm -rf kernel/xiaomi/stone
git clone https://github.com/mayuresh2543/kernel_xiaomi_stone_rebase.git --depth=1 kernel/xiaomi/stone

echo "Custom sources synced"

# Export
export BUILD_USERNAME=mayuresh
export BUILD_HOSTNAME=crave
export TZ="Asia/India"
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

# Lunch
lunch lineage_stone-bp2a-userdebug
echo "============="

# Install clean
m installclean

# Build rom
m bacon
