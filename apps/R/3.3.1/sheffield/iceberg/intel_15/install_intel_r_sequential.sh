#!/bin/bash
#$ -l rmem=8G -l mem=8G
#$ -P radiant

module load compilers/intel/15.0.3
module load compilers/gcc/5.2
module load libs/gcc/4.4.7/curl/7.47.1
module load libs/gcc/4.4.7/zlib/1.2.8
#Load the new bzip2 module
module load libs/gcc/4.4.7/bzip2/1.0.6
export LDFLAGS="-L/usr/local/packages6/libs/gcc/4.4.7/bzip2/1.0.6/lib/"
#Load the new xzutils module
module load apps/gcc/4.4.7/xzutils/5.2.2
#load pcre module
module load libs/gcc/4.4.7/pcre/8.37


#Set up environment variables and create directories
version=3.3.1
install_dir=/usr/local/packages6/apps/intel/15/R/sequential-$version
build_dir=~/R-intel_build_$version
mkdir -p $build_dir
mkdir -p $install_dir

cd $build_dir
#Download, untar and enter build directory
wget https://cran.r-project.org/src/base/R-3/R-$version.tar.gz
tar -xzf ./R-$version.tar.gz
cd R-$version

export CC=icc
export CFLAGS="-O3 -xHOST -axCORE-AVX-I,CORE-AVX2 -fp-model precise"
export FC=ifort
export F77=ifort
export FFLAGS="-O3 -xHOST -axCORE-AVX-I,CORE-AVX2 -fp-model precise"
export FCFLAGS="-O3 -xHOST -axCORE-AVX-I,CORE-AVX2 -fp-model precise"
export CXX=icpc
export CXXFLAGS="-std=c++11 -O3 -xHOST -axCORE-AVX-I,CORE-AVX2 -fp-model precise"
 
./configure --prefix=$install_dir --with-blas=-mkl=sequential --with-lapack=-mkl=sequential --enable-R-shlib | tee config-R-$version.log
make 2>&1 | tee make-R-$version.log

#Check
make check 2>&1 | tee make_check-R-$version.log
make install 2>&1 | tee make_check-R-$version.log

#Tests
make install-tests
cd tests
../bin/R CMD make check 2>&1 | tee make_install_tests-R-$version.log
