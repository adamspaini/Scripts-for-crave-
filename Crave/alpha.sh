#!/bin/bash

rm -rf .repo/local_manifests/

# Rom source repo
repo init -u https://github.com/alphadroid-project/manifest -b alpha-16.2 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Clone local_manifests repository
git clone -b lineage-16 https://github.com/prabhu992/local_manifests.git .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Sync the repositories
/opt/crave/resync.sh
echo "============================"

# Clone device tree repository 
git clone https://github.com/prabhu992/device_xiaomi_stone_new
echo "============================"
echo "Device tree clone success"
echo "============================"

# Signing keys
rm -rf vendor/alpha-priv/keys
git clone https://github.com/alphadroid-project/vendor_alpha-priv_keys vendor/alpha-priv/keys
echo "============================"

# Export
export BUILD_USERNAME=NeoPrabhX
export BUILD_HOSTNAME=crave
export TZ="Asia/Kolkata"
export ALPHA_MAINTAINER="NeoPrabhX"
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

# Brunch
brunch stone
echo "============="
