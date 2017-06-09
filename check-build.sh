#!/bin/bash -e
# Check build file for llvm
. /etc/profile.d/modules.sh
module load ci
module add gcc
module add cmake
module add  python/2.7.13

cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
make check
make test
echo $?
mkdir -p ${SOFT_DIR}
make install
mkdir -p modules
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
    puts stderr "       This module does nothing but alert the user"
    puts stderr "       that the [module-info name] module is not available"
}

module-whatis   "$NAME $VERSION."
setenv       LLVM_VERSION       $VERSION
setenv       LLVM_DIR           /data/ci-build/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION
prepend-path PATH               $::env(LLVM_DIR)/bin
prepend-path LD_LIBRARY_PATH    $::env(LLVM_DIR)/lib
prepend-path CFLAGS             "-I$::env(LLVM_DIR)/include"
prepend-path LDFLAGS            "-L$::env(LLVM_DIR)/lib"
MODULE_FILE
) > modules/$VERSION

mkdir -p ${COMPILERS}/${NAME}
cp modules/$VERSION ${COMPILERS}/${NAME}
