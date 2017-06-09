#!/bin/bash -e
. /etc/profile.d/modules.sh
# this is the build job for LLVM
# it only does clang for now.
LLVM_SOURCE_FILE=${NAME}-${VERSION}.src.tar.xz
CLANG_SOURCE_FILE=cfe-${VERSION}.src.tar.xz
CLANG_TOOLS_SOURCE_FILE=clang-tools-extra-${VERSION}.src.tar.xz

# We provide the base module which all jobs need to get their environment on the build slaves
module add ci
module add gcc
module add cmake
module add python/2.7.13

# Next, a bit of verbose description of the build environment. This is useful when debugging initial builds and you
# may want to remove it later.

# this tells you the main variables you can use which are set by the ci module
echo "REPO_DIR is "
echo $REPO_DIR
echo "SRC_DIR is "
echo $SRC_DIR
echo "WORKSPACE is "
echo $WORKSPACE
echo "SOFT_DIR is"
echo $SOFT_DIR


# In order to get started, we need to ensure that the following directories are available

# Workspace is the "home" directory of jenkins into which the project itself will be created and built.
mkdir -p ${WORKSPACE}
# SRC_DIR is the local directory to which all of the source code tarballs are downloaded. We cache them locally.
mkdir -p ${SRC_DIR}
# SOFT_DIR is the directory into which the application will be "installed"  : /apprepo/../name/version

################# Get LLVM #################################################
#  Download the source file if it's not available locally.
#  we were originally using ncurses as the test application
if [ ! -e ${SRC_DIR}/${LLVM_SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${LLVM_SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${LLVM_SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
  mkdir -p ${SRC_DIR}
# use local mirrors if you can. Remember - UFS has to pay for the bandwidth!
# http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz
  wget http://llvm.org/releases/${VERSION}/${NAME}-${VERSION}.src.tar.xz -O ${SRC_DIR}/${LLVM_SOURCE_FILE}
  echo "releasing lock"
  rm -v ${SRC_DIR}/${LLVM_SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${LLVM_SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${LLVM_SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${LLVM_SOURCE_FILE}
fi
################# Get CLANG #################################################
if [ ! -e ${SRC_DIR}/${CLANG_SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${CLANG_SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${CLANG_SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
# use local mirrors if you can. Remember - UFS has to pay for the bandwidth!
# http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz
  wget http://llvm.org/releases/${VERSION}/${CLANG_SOURCE_FILE} -O ${SRC_DIR}/${CLANG_SOURCE_FILE}
  echo "releasing clang lock"
  rm -v ${SRC_DIR}/${CLANG_SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${CLANG_SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${CLANG_SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${CLANG_SOURCE_FILE}
fi
################# Get CLANG tools #################################################
if [ ! -e ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE}.lock
  echo "seems like this is the first build - let's get the source"
# use local mirrors if you can. Remember - UFS has to pay for the bandwidth!
# http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz
  wget http://llvm.org/releases/${VERSION}/${CLANG_TOOLS_SOURCE_FILE} -O ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE}
  echo "releasing clang tools extra lock file"
  rm -v ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE}
fi


# now unpack it into the workspace
mkdir -p ${WORKSPACE}/${NAME}-${VERSION}/tools/clang-${VERSION}/tools/clang-tools-extra-${VERSION}

tar xf ${SRC_DIR}/${LLVM_SOURCE_FILE} -C ${WORKSPACE}/${NAME}-${VERSION} --strip-components=1 --skip-old-files

# Instructions at  http://clang.llvm.org/get_started.html
# Unpack clang into the llvm/tools directory ...
tar xf ${SRC_DIR}/${CLANG_SOURCE_FILE} -C ${WORKSPACE}/${NAME}-${VERSION}/tools/clang-${VERSION} --strip-components=1 --skip-old-files
# Now unpack the clang extra tools into the clang/tools dir
tar xf ${SRC_DIR}/${CLANG_TOOLS_SOURCE_FILE} -C ${WORKSPACE}/${NAME}-${VERSION}/tools/clang-${VERSION}/tools/clang-tools-extra-${VERSION} --strip-components=1 --skip-old-files

# We will be running configure and make in this directory
mkdir -p $WORKSPACE/${NAME}-${VERSION}/build-${BUILD_NUMBER}
cd $WORKSPACE/${NAME}-${VERSION}/build-${BUILD_NUMBER}
# Note that $SOFT_DIR is used as the target installation directory.

#  Cmake instructions for llvm at : http://llvm.org/docs/CMake.html
cmake ../ \
-G"Unix Makefiles" \
-DGCC_INSTALL_PREFIX=${GCC_DIR} \
-DCMAKE_INSTALL_PREFIX=${SOFT_DIR}
make
