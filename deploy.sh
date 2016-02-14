#!/bin/bash -e
. /etc/profile.d/modules.sh
# this is the build job for LLVM
module add deploy
module add zlib
echo "Tests have passed - configuring to deploy into ${SOFT_DIR} "
cd $WORKSPACE/${NAME}-${VERSION}.src/build-${BUILD_NUMBER}
echo "Cleaning out CI build"
rm -rf *
echo "Configuring deploy"
../configure \
--prefix=${SOFT_DIR} \
--enable-shared \
--enable-zlib

echo "Building deploy"
make -j2

echo "Deploy build has completed - installing into ${SOFT_DIR}"
make install

echo "Creating deploy modulefile"

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
setenv       LLVM_DIR           $::env(CVMFS_DIR)/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION
prepend-path PATH               $::env(LLVM_DIR)/bin
prepend-path LD_LIBRARY_PATH    $::env(LLVM_DIR)/lib
prepend-path CFLAGS             "-I$::env(LLVM_DIR)/include"
prepend-path LDFLAGS            "-L$::env(LLVM_DIR)/lib"
MODULE_FILE
) > modules/$VERSION

mkdir -p ${COMPILERS_MODULES}/${NAME}
cp modules/$VERSION ${COMPILERS_MODULES}/${NAME}
