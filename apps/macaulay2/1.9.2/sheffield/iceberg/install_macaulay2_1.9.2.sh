#!/bin/bash

################################################
# Install Macaulay2 software on UoS HPC systems
#
# Will Furnass
# University of Sheffield
################################################

################################################
# Variables
################################################

m2_vers=1.9.2
m2_repo_url="https://github.com/Macaulay2/M2"

# Docs recommend at least GCC 4.8.3
# Could not get it to compile gmp++ using Intel 15.0.3 compiler
compiler=gcc
compiler_vers=5.3

workers=8

build_dir=/scratch/${USER}/macaulay2_build
inst_dir=/usr/local/packages6/apps/macaulay2/${m2_vers}/${compiler}-${compiler_vers}/

################################################
# Signal handling for success and failure
################################################

cleanup_if_success() {
    rm -rf ${build_dir}
}
trap cleanup_if_success EXIT QUIT

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

################################################
# Create build and install dirs 
# and set ownership / permissions
################################################

mkdir -p ${build_dir}
chmod 700 ${build_dir}

sudo mkdir -p ${inst_dir} 
sudo chgrp -R app-admins ${inst_dir} 
sudo chmod -R g+w ${inst_dir} 

################################################
# Download and unpack app
################################################

pushd ${build_dir}

mkdir -p install
pushd install

if [[ ! -d M2 ]]; then
    git clone ${m2_repo_url}
fi
pushd M2
git checkout version-${m2_vers}
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
# Packages explicitly installed from tarballs by this script:
#
# - libatomic_ops-devel  
# - gc-devel 
# - glpk-devel 
# - gmp-devel 
#  
# Packages implicitly installed from tarballs by the Macaulay2 Makefile
# - autoconf
# - libtool
#
# Packages provided using Environment Modules: 
#
# - boost-devel
# - gcc-c++
# - gcc-gfortran
# - lapack-devel
# - xz-devel

module load compilers/${compiler}/${compiler_vers}
module load libs/${compiler}/${compiler_vers}/boost/1.59
module load libs/gcc/lapack/3.3.0
module load apps/gcc/4.4.7/xzutils/5.2.2

# Atomic operations library
atomic_ops_vers="7.4.4"
curl "http://www.ivmaisoft.com/_bin/atomic_ops/libatomic_ops-${atomic_ops_vers}.tar.gz" | tar -zx
pushd "libatomic_ops-${atomic_ops_vers}"
./configure --prefix=${build_dir} 
make -j${workers} 
make -j${workers} check 
make install 
popd

# GNU Multiple Precision Arithmetic Library (used by GLPK; see below)
gmp_vers="6.1.1"
curl "https://gmplib.org/download/gmp/gmp-${gmp_vers}.tar.xz" | tar -Jx
pushd "gmp-${gmp_vers}"
./configure --prefix=${build_dir} 
make -j${workers} 
make -j${workers} check 
make install 
popd

glpk_vers="4.60"
curl "http://ftp.gnu.org/gnu/glpk/glpk-${glpk_vers}.tar.gz" | tar -zx
pushd "glpk-${glpk_vers}"
./configure --prefix=${build_dir} --with-gmp --with-zlib 
make -j${workers} 
make -j${workers} check 
make install 
popd

# Boehm-Demers-Weiser conservative C/C++ Garbage Collector 
gc_vers="7_6_0"
curl "https://codeload.github.com/ivmai/bdwgc/tar.gz/gc${gc_vers}" | tar -zx
pushd "bdwgc-gc${gc_vers}"
ln -sf "../libatomic_ops-${atomic_ops_vers}" libatomic_ops
autoreconf -vif 
automake --add-missing 
./configure --prefix=${build_dir} 
make -j${workers} 
make -j${workers} check 
make install 
popd

################################################
# Configure, compile and install Macaulay2
################################################

export CPPFLAGS="-I$(pwd)/deps/usr/local/include ${CPPFLAGS}" 
export LDFLAGS="-L$(pwd)/deps/usr/lib64 ${LDFLAGS}" 
# Macaulay2 complains if CFLAGS is set
export CFLAGS= 

pushd M2/M2
make get-tools # Download newer versions of m4, autoconf, automake, and libtool
make # run `autoconf` to create the `configure` script and run `autoheader` to create `include/config.h.in`
./configure --enable-download --enable-ntl-wizard --prefix=${inst_dir}
make -j${workers}
make check
make install
popd
popd
popd
