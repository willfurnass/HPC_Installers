#!/bin/bash

install_dir=/usr/local/packages6/libs/gcc/4.4.7/beagle/2.1.2

filename_root=beagle_release_2_1_2
filename=$filename_root.tar.gz

if [ -e $filename ]
then
  echo "Install tarball exists. Download not required."
else
  echo "Downloading  source"
  wget https://github.com/beagle-dev/beagle-lib/archive/$filename
fi


tar -xzf ./$filename
cd beagle-lib-beagle_release_2_1_2
./autogen.sh
./configure --prefix=$install_dir

make
make check 2>&1 | tee checklog_$filename_root.log
make install

#Copy the test log to the install directory
mv ./checklog_$filename_root.log $install_dir


