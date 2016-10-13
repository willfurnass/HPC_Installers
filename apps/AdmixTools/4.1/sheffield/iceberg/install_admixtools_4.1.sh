#!/bin/bash

# variables
workers=8
admixtools_version=4.1
compiler_version=15.0.3
compiler_short_version=15
gsl_version=2.2
start_dir="$(pwd)"
scratch_dir="/scratch/${USER}/"
build_dir="${scratch_dir}/AdmixTools"
inst_dir="/usr/local/packages6/apps/intel/${compiler_short_version}/AdmixTools/${admixtools_version}"
env_mod_dir="/usr/local/modulefiles/apps/intel/${compiler_short_version}/AdmixTools/"

# Create and set permissions on installation dir and environment module dir
# (sudo only needed here)
for d in "${inst_dir}" "${env_mod_dir}"; do
    mkdir -m 2775 -p $d
    chgrp app-admins $d
    chmod g+x $d
done

# Enable the use of the Intel compiler and MKL (which provides MKL versions of BLAS and LAPACK)
module load compilers/intel/${compiler_version}

export CPATH=${build_dir}/include:${CPATH}
export LD_LIBRARY_PATH=${build_dir}/lib:${LD_LIBRARY_PATH}

# Create a build and installation directory
[[ -d ${scratch_dir} ]] || mkdir -p ${scratch_dir}

# Clone and checkout a particular revision of AdmixTools
[[ -d ${build_dir} ]] || git clone https://github.com/DReichLab/AdmixTools ${build_dir}
pushd ${build_dir}
git checkout def3c5d75d1b10fd3270631f5c64adbf3af04d4d

# Install dependency: GNU Scientific library (GSL)
[[ -d gsl-${gsl_version} ]] || curl http://ftp.heanet.ie/mirrors/gnu/gsl/gsl-${gsl_version}.tar.gz | tar -zx
pushd gsl-${gsl_version}
./configure --prefix=$(pwd)/../ || echo 'Could not configure GSL prior to compilation' 1>&2 && exit -1
make -j${workers} || echo 'Could not compile GSL' 1>&2 && exit -1
make install || echo 'Could not locally install GSL' 1>&2 && exit -1
popd

# Build AdmixTools
pushd src
# Use makefile ammended so that it links against Intel libifcore rather than gfortran and uses MKL for BLAS and LAPACK functions
cp "${start_dir}/Makefile" .
make clobber 
make all -j${workers} || echo 'Could not compile AdmixTools' 1>&2 && exit -1
make install -j${workers}  
# ...puts executables put in ../bin
popd

# Download data needed to run examples (creates 'data' dir)
curl https://genetics.med.harvard.edu/reich/Reich_Lab/Software_files/AdmixTools_Example_Data.tar.gz | tar -zx
pushd examples
./mklog || echo 'Could not build examples' 1>&2 && exit -1
popd

# Move everything in the build dir to the installation dir
mv * .git .gitignore ${inst_dir}
popd
chgrp -R app-admins ${inst_dir}
chmod -R g+x ${inst_dir}

# Install the Environment Module
cp "${start_dir}/admixtools_env_mod_${admixtools_version}" "${env_mod_dir}/${admixtools_version}"
