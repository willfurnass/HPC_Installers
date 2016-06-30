#!/bin/bash

install_dir=/usr/local/packages6/apps/gcc/4.8.2/JAGS/4.2
version=4.2.0

mkdir -p $install_dir

#Compile with GCC 4.8.2
module load compilers/gcc/4.8.2


tar -xvzf ./JAGS-$version.tar.gz
cd JAGS-$version
./configure --prefix=$install_dir --libdir=$install_dir/lib64
make
make install
