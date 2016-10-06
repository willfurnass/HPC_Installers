#!/bin/bash

######################################################
# Install Macaulay2 software on UoS Iceberg HPC system
#
# Will Furnass
# University of Sheffield
######################################################

################################################
# Variables
################################################

m2_vers=1.9.2
m2_repo_url="https://github.com/Macaulay2/M2"
# The tagged '1.9.2' release of Macaulay2 has problems with the build and
# self-check process so install a very slightly newer version (which is stil
# 1.9.2.x) that includes fixes to the install process.
m2_commit=aedebfc1e6326416cb01598e09e8b4dbdc76c178

# Docs recommend at least GCC 4.8.3
# Could not get it to compile gmp++ using Intel 15.0.3 compiler
compiler=gcc
compiler_vers=5.3

workers=4

build_dir=/scratch/${USER}/macaulay2_build
inst_dir=/usr/local/packages6/apps/macaulay2/${m2_vers}/${compiler}-${compiler_vers}/

################################################
# Signal handling for failure
################################################

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
    rsync -ar --delete ${build_dir} /data/${USER}/
    exit $errcode  # or use some other value or do return instead 
} 
trap handle_error ERR

################################################
# Download and unpack app
################################################

mkdir -p ${build_dir}
chmod 700 ${build_dir}
pushd ${build_dir}

mkdir -p install
pushd install

module load apps/gcc/5.2/git/2.5

if [[ ! -d M2 ]]; then
    git clone ${m2_repo_url}
fi
pushd M2
git checkout ${m2_commit}
popd

################################################
# Enable / install dependencies and compilers
################################################
#
# Prerequisite RPMs (according to installation instructions for those using
# Scientific Linux 7.x)
# 
# Provided by OS:
#
# - bison 
# - flex 
# - libxml2-devel 
# - mpfr-devel 
# - ncurses-devel 
# - readline-devel 
# - zlib-devel 
# - gdbm-devel 
#
# Packages implicitly installed from tarballs by the Macaulay2 Makefile
# - autoconf
# - libtool
# - libatomic_ops-devel?
# - gc-devel?
# - glpk-devel?
# - gmp-devel?
#
# Packages provided using Environment Modules: 
#
# - boost-devel
# - gcc-c++
# - gcc-gfortran
# - lapack-devel
# - xz-devel

# Load modules
# NB 'module load' will (annoyingly) not error if the requested module does not exist
module load compilers/${compiler}/${compiler_vers}
module load libs/gcc/5.2/boost/1.59 
module load libs/gcc/lapack/3.3.0 
module load apps/gcc/4.4.7/xzutils/5.2.2 

# Macaulay2 requires and provides newer versions of m4, autoconf, automake, and libtool
pushd M2/M2
make get-tools 

################################################
# Configure, compile and install Macaulay2
################################################

# Macaulay2 complains if CFLAGS is set
export CPPFLAGS="$CPPFLAGS $CFLAGS"
export CFLAGS= 
make # run `autoconf` to create the `configure` script and run `autoheader` to create `include/config.h.in`
mkdir -p ${inst_dir}
./configure --enable-download --enable-ntl-wizard --prefix=${inst_dir}
make -j${workers}
make check
make install
popd
popd
popd
chown -R ${USER}:app-admins ${inst_dir} 
chmod -R g+w ${inst_dir} 
