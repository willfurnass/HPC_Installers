#!/bin/bash
#Install script used to install gcc 6.2 on iceberg
#This does both the download and the install

# Set some env variables for convenience
export INSTALL_ROOT_DIR=/usr/local/packages6/compilers/gcc
export GVER=6.2.0
export INSTALL_DIR=$INSTALL_ROOT_DIR/$GVER
export SOURCE_DIR=/scratch/${USER}/gcc/${GVER}/source
export BUILD_DIR=/scratch/${USER}/gcc/${GVER}/build

# Make directories and set permissions on the install dir
mkdir -p $INSTALL_DIR
chown -R ${USER}:app-admins ${INSTALL_DIR}
chmod -R g+w ${INSTALL_DIR}

mkdir -p $SOURCE_DIR
mkdir -p $BUILD_DIR

# Download gcc
cd $SOURCE_DIR
[[ -e gcc-$GVER.tar.gz ]] || wget ftp://ftp.mirrorservice.org/sites/sourceware.org/pub/gcc/releases/gcc-${GVER}/gcc-${GVER}.tar.gz

# Untar source
if [[ -e ./gcc-$GVER/untar_complete ]]; then
    echo "Directory already untarred. Moving on"
else
    echo "Untarring gcc"
    time tar xzf ./gcc-$GVER.tar.gz
    touch ./gcc-$GVER/untar_complete
fi

# Download pre-reqs
cd $SOURCE_DIR/gcc-${GVER}
$SOURCE_DIR/gcc-${GVER}/contrib/download_prerequisites

#Enter build dir and configure
cd $BUILD_DIR
$SOURCE_DIR/gcc-${GVER}/configure --prefix=$INSTALL_DIR --enable-languages=c,c++,fortran,go --disable-multilib 2>&1 | tee config-gcc${GVER}.log

# Run compilation on 4 cores (optional) - it takes for ever otherwise
make -j 4 2>&1 | tee make-gcc${GVER}.log
make install 2>&1 | tee make-install-gcc${GVER}.log

