#!/bin/bash

################################################
# Install Gromacs software on UoS HPC systems
#
# Will Furnass
# University of Sheffield
################################################

################################################
# Variables
################################################

version=5.1.2  # NB cannot install 2016 without using using C++11-compatible compiler / std lib.

filename=gromacs-$version.tar.gz
baseurl=ftp://ftp.gromacs.org/pub/gromacs/

build_dir=/scratch/${USER}/gromacs_build
inst_dir=/usr/local/packages6/apps/intel/15/gromacs/${version}-cuda-7.5.18

workers=8

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
# Enable / install dependencies and compilers
################################################

module load mpi/intel/openmpi/1.10.0
module load compilers/cmake/3.3.0
module load libs/cuda/7.5.18

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
# Download, configure, compile and install app
################################################

pushd ${build_dir}

[[ -e ${filename} ]] || wget ${baseurl}/${filename}
tar -zxf ${filename}

cd gromacs-$version
[[ -d build ]] && rm -r build
mkdir -p build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${inst_dir} \
    -DGMX_MPI=on \
    -DGMX_FFT_LIBRARY="mkl" \
    -DGMX_GPU=on

make -j${workers} 
make check
make install

popd
