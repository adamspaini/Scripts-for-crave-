#!/bin/bash

rm -rf .repo/local_manifests/

# Rom source repo
repo init -u https://github.com/yaap/manifest.git -b sixteen --git-lfs
echo "=================="
echo "Repo init success"
echo "=================="

# Clone local_manifests repository
git clone -b yaap-16 https://github.com/Mayuresh2543/local_manifests.git .repo/local_manifests
echo "============================"
echo "Local manifest clone success"
echo "============================"

# Sync the repositories
/opt/crave/resync.sh
echo "============================"

export CLANG_PATH=$PWD/prebuilts/clang/host/linux-x86/clang-r547379/bin
export PATH=$CLANG_PATH:$PATH
alias clang=$CLANG_PATH/clang
alias clang++=$CLANG_PATH/clang++
alias ld.lld=$CLANG_PATH/ld.lld
export CC=$CLANG_PATH/clang
export CXX=$CLANG_PATH/clang++
export LD=$CLANG_PATH/ld.lld

# Export
export BUILD_USERNAME=mayuresh
export BUILD_HOSTNAME=crave
export TZ="Asia/India"
echo "======= Export Done ======"

# Set up build environment
. build/envsetup.sh
echo "====== Envsetup Done ======="

# Lunch
lunch yaap_stone-userdebug
echo "============="

# Build rom
m yaap
