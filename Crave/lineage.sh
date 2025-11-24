#!/bin/bash

rm -rf .repo/local_manifests/

# Rom source repo
repo init -u https://github.com/ProjectMatrixx/android.git -b 16.0 --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Clone local_manifests repository
git clone -b 16-vanilla https://github.com/buildbot-stone-devs/local_manifest_matrixx.git .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Sync the repositories
/opt/crave/resync.sh
echo "============================"

rm -rf packages/apps/Settings
git clone https://github.com/mayuresh2543/matrixx_packages_apps_Settings.git packages/apps/Settings

# Export
export BUILD_USERNAME=mayureshxKhnome
export BUILD_HOSTNAME=nobody
export TZ="Europe/Vilnius"
echo "======= Export Done ======"

# Sign
cd vendor/lineage-priv/keys
chmod +x ./syslink.sh
././syslink.sh
cd ../../..
echo "Signing success"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

lunch lineage_stone-bp2a-userdebug

m installclean

m bacon

WITH_GMS=true WITH_QS=true m bacon
