#!/bin/bash

#I ran these commands manually

tar -xvzf ./mrbayes-3.2.6.tar.gz 
cd mrbayes-3.2.6
autoconf
./configure --with-beagle=/usr/local/packages6/libs/gcc/4.4.7/beagle/2.1.2 --prefix=/usr/local/packages6/apps/gcc/4.4.7/mrbayes/3.2.6/
make
make install
