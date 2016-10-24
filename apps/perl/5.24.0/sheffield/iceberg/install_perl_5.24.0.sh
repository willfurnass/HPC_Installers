#!/bin/bash

perl5_vers=5.24.0
perl5_tarball="perl-${perl5_vers}.tar.gz"
perl5_tarball_url="http://www.cpan.org/src/5.0/${perl5_tarball}"
compiler=gcc
compiler_vers=4.4.7

scratch_dir="/scratch/${USER}/perl/"

prefix="/usr/local/packages6/apps/${compiler}/${compiler_vers}/perl/${perl5_vers}/"

this_script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
modulefile_src="${this_script_dir}/perl_${perl5_vers}_modulefile"
modulefile_root="/usr/local/modulefiles/"
modulefile_string="apps/${compiler}/${compiler_vers}/perl/${perl5_vers}"
modulefile_dest="${modulefile_root}/${modulefile_string}"

workers=4

# Signal handling for failure
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

mkdir -p ${scratch_dir}
cd ${scratch_dir}

# Download and unpack tarball
[[ -f $perl5_tarball ]] || wget $perl5_tarball_url
if ! [[ -f .perl5_${perl5_vers}_tarball_unpacked ]]; then
    tar -zxf ${perl5_tarball}
    touch .perl5_${perl5_vers}_tarball_unpacked 
fi

# Create install and modulefile dirs
for d in $prefix $(dirname $modulefile_dest); do
    mkdir -m 2775 -p $d
done

# Build and install Perl itself
pushd perl-${perl5_vers}
./Configure -des -Dprefix=${prefix}
make -j${workers}
#make test
make install
popd

# Install modulefile
cp ${modulefile_src} ${modulefile_dest}

# Upgrade CPAN and install several useful modules
module load ${modulefile_string}
if [[ "$(which perl)" != "/usr/bin/perl" ]]; then 
    # Set CPAN config to defaults
    (echo y;echo o conf prerequisites_policy follow;echo o conf commit) | cpan
    # Upgrade CPAN
    perl -MCPAN -e 'install CPAN'
    # Install cpanm package manager
    perl -MCPAN -e 'install App::cpanminus'
    cpanm Term::ReadKey
    cpanm Term::ReadLine::Gnu
    cpanm inc::latest
    cpanm Module::Build
    cpanm local::lib
    cpanm CJFIELDS/BioPerl-1.007000.tar.gz  # aka v1.7?
fi

# Set permissions and ownership
for d in $prefix $(dirname $modulefile_dest); do
    chmod -R g+w $d
    chown -R ${USER}:app-admins $d
done
