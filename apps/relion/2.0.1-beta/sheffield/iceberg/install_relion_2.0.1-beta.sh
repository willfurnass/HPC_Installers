#!/bin/bash

# This is a template script for building and installing software on iceberg.
# You should use it to document how you install things.
# You will need to configure any module loads the build needs and then 
# configure the variables for the build.
# This script will then create the directories you need and download and unzip
# the source in to the build dir.

##############################################################################
# Variable setup
#
name=relion
version=2.0.1-beta
git_repo_url=https://bitbucket.org/tcblab/relion2-beta.git
commit=a6225608e270ac68af463ec3ba7567dbbbc4a4a0
compiler=gcc
compiler_vers=4.4.7  # Default on this system
prefix="/usr/local/packages6/apps/$compiler/$compiler_vers/$name/$version"
build_dir=/scratch/$USER/$name
workers=4

##############################################################################
# Signal handling for failure
#
handle_error () {
    errcode=$? # save the exit code as the first thing done in the trap function 
    echo "error $errorcode" 
    echo "the command executing at the
    time of the error was" echo "$BASH_COMMAND" 
    echo "on line ${BASH_LINENO[0]}"
    # do some error handling, cleanup, logging, notification $BASH_COMMAND
    # contains the command that was being executed at the time of the trap
    # ${BASH_LINENO[0]} contains the line number in the script of that command
    # exit the script or return to try again, etc.
    exit $errcode  # or use some other value or do return instead 
}
trap handle_error ERR

##############################################################################
# Modules
#
# Activate latest OpenMPI
module load mpi/gcc/openmpi/1.10.1
# Activate CUDA 7.5 (so must use older GCC i.e. 4.4.7 (system GCC); 
# CUDA 8.0 not recommended yet)
module load libs/cuda/7.5.18
# Activate FFTW
module load libs/gcc/5.2/fftw/3.3.4
# Activate GUI toolkit
module load libs/gcc/5.2/fltk/1.3.3
module unload compilers/gcc/5.2  # temporary fix; GCC 5.2 is activated by the above line

##############################################################################
# Create the build and install dirs
#
[[ -d $build_dir ]] || mkdir -p $build_dir
cd $build_dir

[[ -d $prefix ]] || mkdir -m 2775 -p $prefix
chown -R $USER:app-admins $prefix

##############################################################################
# Clone git repo and checkout commit
#
mkdir -p $build_dir
pushd $build_dir
if [[ -d relion2-beta/.git ]]; then
    pushd relion2-beta
    git fetch
else
    git clone $git_repo_url
    pushd relion2-beta
fi
git checkout $commit

##############################################################################
# Build 
#
[[ -d build ]] && rm -r build
mkdir -p build
pushd build
cmake ..
make -j$workers
popd

##############################################################################
# Install
#
cp -r build/{bin,lib,tests} $prefix/
cp scripts/* $prefix/bin/
chmod +x $prefix/bin/star*
mkdir $prefix/include
cp relion.h $prefix/include

popd
popd
