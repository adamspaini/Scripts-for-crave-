#!/bin/bash

rm -rf .repo/local_manifests/
rm -rf prebuilts/clang/host/linux-x86

# Rom source repo
repo init --git-lfs --no-clone-bundle -u https://git@github.com/LineageOS/android.git -b refs/changes/42/436442/31
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

#rm -rf vendor/lineage
#git clone https://github.com/mayuresh2543/android_vendor_lineage.git --depth=1 vendor/lineage

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

# Build rom
m bacon
