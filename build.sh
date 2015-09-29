#!/bin/bash -e
source /usr/share/modules/init/bash
# this is the build job for LLVM
# it only does clang for now.
SOURCE_FILE=$NAME-$VERSION.src.tar.xz

# We provide the base module which all jobs need to get their environment on the build slaves
module load ci
module add gcc/4.9.2


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
mkdir -p $WORKSPACE
# SRC_DIR is the local directory to which all of the source code tarballs are downloaded. We cache them locally.
mkdir -p $SRC_DIR
# SOFT_DIR is the directory into which the application will be "installed"
mkdir -p $SOFT_DIR

#  Download the source file if it's not available locally.
#  we were originally using ncurses as the test application
if [[ ! -s $SRC_DIR/$SOURCE_FILE ]] ; then
  echo "seems like this is the first build - let's get the source"
  mkdir -p $SRC_DIR
# use local mirrors if you can. Remember - UFS has to pay for the bandwidth!
# http://llvm.org/releases/3.7.0/llvm-3.7.0.src.tar.xz
  wget http://llvm.org/releases/${VERSION}/${NAME}-${VERSION}.src.tar.xz $SOURCE_FILE -O $SRC_DIR/$SOURCE_FILE
else
  echo "continuing from previous builds, using source at " $SRC_DIR/$SOURCE_FILE
fi

# now unpack it into the workspace
tar -xvzf $SRC_DIR/$SOURCE_FILE -C $WORKSPACE

#  generally tarballs will unpack into the NAME-VERSION directory structure. If this is not the case for your application
#  ie, if it unpacks into a different default directory, either use the relevant tar commands, or change
#  the next lines

# We will be running configure and make in this directory
mkdir -p $WORKSPACE/${NAME-$VERSION}.src/build
cd $WORKSPACE/${NAME-$VERSION}.src/build
# Note that $SOFT_DIR is used as the target installation directory.
../configure --prefix $SOFT_DIR

# The build nodes have 8 core jobs. jobs are blocking, which means you can build with at least 8 core parallelism.
# this might cause instability in the builds, so it's up to you.
make
