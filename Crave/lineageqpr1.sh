#!/bin/bash

rm -rf .repo/local_manifests/

# Rom source repo
repo init -u https://github.com/LineageOS/android.git -b lineage-23.1 --git-lfs
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

rm -rf packages/apps/Updater
git clone https://github.com/mayuresh-sources/lineage_packages_apps_Updater.git --depth=1 packages/apps/Updater

rm -rf packages/apps/Launcher3
git clone https://github.com/mayuresh2543/lineage-qpr1_packages_apps_Launcher3.git --depth=1 packages/apps/Launcher3

rm -rf frameworks/base
git clone https://github.com/mayuresh2543/lineage-qpr1_frameworks_base.git --depth=1 frameworks/base

rm -rf packages/apps/Settings
git clone https://github.com/mayuresh2543/lineage-qpr1_packages_apps_Settings.git --depth=1 packages/apps/Settings

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
lunch lineage_stone-bp3a-userdebug
echo "============="

# Install clean
m installclean

# Build rom
m bacon
