#!/bin/bash
#Install script used to install gcc 6.2 on iceberg
#This does both the download and the install

# Set some env variables for convenience
export INSTALL_ROOT_DIR=/usr/local/packages6/compilers/gcc
export GVER=6.2.0
export INSTALL_DIR=$INSTALL_ROOT_DIR/$GVER
export SOURCE_DIR=/scratch/${USER}/gcc/${GVER}/source
export BUILD_DIR=/scratch/${USER}/gcc/${GVER}/build
workers=4

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
make -j ${workers} 2>&1 | tee make-gcc${GVER}.log
make install 2>&1 | tee make-install-gcc${GVER}.log

