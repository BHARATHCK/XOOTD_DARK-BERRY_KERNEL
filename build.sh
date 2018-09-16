#
# Copyright © 2018, "Atman" <masteratman@gmail.com>
# Copyright © 2016, Kunal Kene "kunalkene1797" <kunalkene1797@gmail.com>
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

# Script V1.1

# Use: ./build_kernel.sh (clang|gcc) (stable|alpha)
# Set Defaults to Clang and Alpha
compiler_build=${1:-clang}
build_type=${2:-alpha}

# Kernel
KERNEL_DIR=$PWD
KERNEL="Image.gz-dtb"
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb

#Home
export HOME=~/BHARATH
# Build Start [needed for calculating time]
BUILD_START=$(date +"%s")

# AnyKernel2 Dir
ANYKERNEL_DIR=/home/bharath/Downloads/DB-v4

# Export Zip Here
EXPORT_DIR=/home/bharath/Downloads/flashables/

# Zip Name [Changes before Release if parameter is stable]
# CURRENT_VERSION is a file which defines CURRENT VERSION

# If param stable is provided use it to compile with filename TwistLoop-V-xyz.zip
# If param alppha is provided use it to compile with filename TwistLoop-Alpha-dd-mm-yy.zip

ZIP_NAME="DB-v5"
if [[ -f version_stable && $build_type == "stable" ]]; then
  CURRENT_VERSION=$(<version_stable)
  ZIP_NAME+="V-"
  ZIP_NAME+=$CURRENT_VERSION
fi

if [[ $build_type == "alpha" ]]; then
  ZIP_NAME+="Alpha-"
  DASH_DATE=`echo $(date +'%d/%m/%Y') | sed 's/\//-/g'`
  ZIP_NAME+=$DASH_DATE
fi

# Arch
export ARCH=arm64
export SUBARCH=arm64

# Change the Paths [if needed]
export CROSS_COMPILE="/home/bharath/Downloads/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"

# RegEx the KBUILD_COMPILER_STRING to keep things crisp and clear
export KBUILD_COMPILER_STRING=$(/home/bharath/Downloads/linux-x86-master-clang-r328903/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')

# Set User and Host
export KBUILD_BUILD_USER="BHARATH"
export KBUILD_BUILD_HOST="darkberry"

# Branding DARKBERRY

echo "-----------------------------------------------"
echo "  Initializing build to compile Ver: $ZIP_NAME "
echo "-----------------------------------------------"

echo -e "***********************************************"
echo     "         Creating Output Directory: out       "
echo -e "***********************************************"

# Create Out
mkdir -p out

echo -e "************************************************"
echo     "          Initialising DB_defconfig     "
echo -e "************************************************"

# Init Defconfig
make O=out ARCH=arm64 DB_defconfig

echo -e "***********************************************"
echo    "          Cooking DARK-BERRY                   "
echo -e "***********************************************"

# make
if [[ $compiler_build == "clang" ]]; then
  make -j$(nproc --all) O=out ARCH=arm64 \
                              CC="/home/bharath/Downloads/linux-x86-master-clang-r328903/bin/clang" \
                              CROSS_COMPILE="/home/bharath/Downloads/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"\
                              CLANG_TRIPLE="aarch64-linux-gnu-"
fi

if [[ $compiler_build == "gcc" ]]; then
  make -j$(nproc --all) O=out ARCH=arm64 \
                              CROSS_COMPILE="/home/bharath/Downloads/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/aarch64-linux-gnu-"
fi

# If the above was successful
if [ -a $KERN_IMG ]; then
   BUILD_RESULT_STRING="BUILD SUCCESSFUL"

echo -e "***********************************************"
echo    "            Making Flashable Zip               "
echo -e "***********************************************"
   # AnyKernel2 Magic Begins!
   # Make the zip file
   echo "MAKING FLASHABLE ZIP"

   # Move the zImage to AnyKernel2 dir
   cp -vr ${KERN_IMG} ${ANYKERNEL_DIR}/zImage
   cd ${ANYKERNEL_DIR}
   zip -r9 ${ZIP_NAME}.zip * -x README ${ZIP_NAME}.zip

else
   BUILD_RESULT_STRING="BUILD FAILED"
fi

# Export Zip
NOW=$(date +"%m-%d")
ZIP_LOCATION=${ANYKERNEL_DIR}/${ZIP_NAME}.zip
ZIP_EXPORT=${EXPORT_DIR}/${NOW}
ZIP_EXPORT_LOCATION=${EXPORT_DIR}/${NOW}/${ZIP_NAME}.zip

rm -rf ${ZIP_EXPORT}
mkdir ${ZIP_EXPORT}
mv ${ZIP_LOCATION} ${ZIP_EXPORT}
cd ${HOME}

echo ""

if [[ -e $ZIP_EXPORT_LOCATION ]]; then
transfer_sh="https://transfer.sh/"${ZIP_NAME}.zip
echo "------------------------------"
curl --upload-file $ZIP_EXPORT_LOCATION $transfer_sh
echo -e "\n------------------------------"
fi

echo ""

# End the script
echo "${BUILD_RESULT_STRING}!"

# End the Build and Print the Compilation Time
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds."
