#!/bin/bash

rm -rf .repo/local_manifests/

# Rom source repo
repo init -u https://github.com/LineageOS/android.git -b lineage-22.2 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Clone local_manifests repository
git clone -b lineage-15 https://github.com/Mayuresh2543/local_manifests.git .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Sync the repositories
/opt/crave/resync.sh
echo "============================"

rm -rf packages/apps/Updater
git clone https://github.com/mayuresh2543/lineage_a15_packages_apps_Updater.git --depth=1 packages/apps/Updater

rm -rf packages/apps/Trebuchet
git clone https://github.com/mayuresh2543/lineage_a15_packages_apps_Trebuchet.git --depth=1 packages/apps/Trebuchet

rm -rf art
git clone https://github.com/mayuresh2543/lineage_a15_art.git --depth=1 art

rm -rf frameworks/base
git clone https://github.com/mayuresh2543/lineage_a15_frameworks_base.git --depth=1 frameworks/base

rm -rf frameworks/native
git clone https://github.com/mayuresh2543/lineage_a15_frameworks_native.git --depth=1 frameworks/native

rm -rf bionic
git clone https://github.com/mayuresh2543/lineage_a15_bionic.git --depth=1 bionic

rm -rf frameworks/libs/systemui
git clone https://github.com/mayuresh2543/lineage_a15_frameworks_libs_systemui.git --depth=1 frameworks/libs/systemui

rm -rf build/soong
git clone https://github.com/mayuresh2543/lineage_a15_build_soong.git --depth=1 build/soong

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
lunch lineage_stone-bp1a-userdebug
echo "============="

# Install clean
m installclean

# Build rom
m bacon
