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

version=5.1.4  # NB cannot install 2016 without using using C++11-compatible compiler / std lib.
cuda_vers=7.5.18
compiler=gcc
compiler_vers=4.8.2

filename=gromacs-$version.tar.gz
baseurl=ftp://ftp.gromacs.org/pub/gromacs/

build_dir=/scratch/${USER}/gromacs_build
export inst_dir=/usr/local/packages6/apps/${compiler}/${compiler_vers}/gromacs/${version}-cuda-${cuda_vers}

workers=4

################################################
# Signal handling for success and failure
################################################

handle_error () {
    errcode=$? # save the exit code as the first thing done in the trap function 
    echo "error $errorcode" 
    echo "the command executing at the time of the error was" echo "$BASH_COMMAND" 
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

module load mpi/gcc/openmpi/1.8.8
module load compilers/${compiler}/${compiler_vers}
module load compilers/cmake/3.3.0
module load libs/cuda/${cuda_vers}

################################################
# Create build and install dirs 
# and set permissions
################################################

mkdir -m 0700 -p ${build_dir}
mkdir -m 2775 -p ${inst_dir}

################################################
# Download, configure, compile and install app
################################################

pushd ${build_dir}

[[ -e ${filename} ]] || wget ${baseurl}/${filename}
tar -zxf ${filename}

cd gromacs-$version
[[ -d build ]] && rm -r build
mkdir build
cd build
cmake .. \
    -DCMAKE_INSTALL_PREFIX=${inst_dir} \
    -DGMX_MPI=on \
    -DGMX_FFT_LIBRARY=fftw3 \
    -DGMX_BUILD_OWN_FFTW=ON \
    -DGMX_GPU=on \
    -DGMX_SIMD=AVX2_256
#-DREGRESSIONTEST_DOWNLOAD \ # not needed?

make -j${workers} 
make check
make install

################################################
# Regression tests
################################################

git clone https://gerrit.gromacs.org/regressiontests
pushd regressiontests
source ${inst_dir}/bin/GMXRC
./gmxtest.pl all -noverbose
popd

popd

################################################
# Set ownership / permissions
################################################

chown -R ${USER}:app-admins ${inst_dir}
chmod -R g+w ${inst_dir}
