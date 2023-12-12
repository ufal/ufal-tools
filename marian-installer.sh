#!/bin/bash
# Installation of Marian NMT and prerequisites for UFAL cluster environment.
# Derived from eman seed for marian (http://ufal.mff.cuni.cz/eman)
# Ondrej Bojar and Josef Jon
# vim: tabstop=2 expandtab


marianrepo=https://github.com/marian-nmt/marian-dev.git

function die() { echo "$@" >&2; exit 1; }
function warn() { echo "$@" >&2; }
set -o pipefail


# These environment variables are recognized by the script:
#   defvar BRANCH default='' help='which marian branch to use' \
#   defvar BOOST help='which boost to use' \
#     default='/net/me/merkur3/varis/boost/boost_1_56_0-py3.5-g++5.4' \
#   defvar CMAKE help='which cmake to use' \
#     default='' \
#   defvar GCC help='which gcc to use' \
#     default='/ha/opt/x86_64/tools/gcc/gcc-5.4.0' \
#   defvar EMAN_QUEUE default='gpu.q' help="which queue to submit to" \
#   defvar EMAN_GPUS default='1' help="need a machine with CUDA by default" \
#   defvar EMAN_GPUMEM default='6g' help="one of UFAL's better machines" \
#   defvar USE_CUDA default='yes' \
#     help='compile Marian with CUDA support; the particular value of this variable is probably ignored but you can set it to empty to compile only non-GPU parts of Marian, i.e. marian-decoder with only CPU support' \
#   defvar CUDA_HOME="/opt/cuda/10.1/"
#TODO - everything aboce this?
# another TODO - if we want AVX512VNNI (some new intel stuff for 8bit matrix operations, it is useful for small quantized student models), we need gcc > 8? maybe


# Where to install/compile to:
# If the script is run without parameters, it assumes that it was already run
# before and that now we run it in the directory where it already is.


MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # get script directory
DESIREDDIR=$1
if [ -z "$DESIREDDIR" ]; then
  # no argument given
  if [ -e "guessmarian" ]; then
    # we were run in a directory where marian was already compiled
    # we just need to compile for this architecture
    TARGETDIR=$(pwd)
  else
    die "usage: $0 target-dir-to-create"
  fi
else
  if [ -e "$DESIREDDIR" ]; then
    warn "$DESIREDDIR already exists, not touching it."
    warn "If you want to add another compilation, do this:"
    warn "  cd $DESIREDDIR && ./compile-again-for-this-architecture.sh"
    exit 1
  fi
  mkdir -p "$DESIREDDIR" || die "Failed to create $DESIREDDIR"
  TARGETDIR=$(readlink -f "$DESIREDDIR")
  cp "${BASH_SOURCE[0]}" "$TARGETDIR/compile-again-for-this-architecture.sh" \
  || die "Failed to copy self to $TARGETDIR/compile-again-for-this-architecture.sh"
fi
warn "### Compiling marian for the CPU+GPU architecture of "$(hostname)" into $TARGETDIR"
cd "$TARGETDIR" || die "Failed to chdir to $TARGETDIR"

### If you have custom CUDA installation, put the path in here (auto-detection mostly works on systems with cuda installed through package manager, as well as Metacentrum and IT4I):
#UFAL:
CUDA_HOME=/opt/cuda/11.7

#Lingea:
CUDA_HOME=/usr/local/cuda-11.8/

### Environment-specific steps and settings
#Metacentrum (hostname list might not be exhaustive, please let the authors know if you end up with a node using another hostname)
hostname=$(hostname)
if [[ "$hostname" =~ metacentrum.cz ]] || [[ "$hostname" =~ grid.cesnet.cz ]] || [[ "$hostname" =~ cerit-sc.cz ]] || [[ "$hostname" =~ natur.cuni.cz ]] 
then
  # adan and doom
  module load gcc/8.3.0 cmake cuda/11.6 python/3.9.12-gcc-10.2.1-rg2lpmk
fi

#IT4I
if  [[ "$hostname" =~ it4i.cz ]]
then
        module load CMake/3.20.1-GCCcore-10.3.0 CUDA/11.7.0
fi

### Less environment specific steps

## CUDA
mkdir cuda_ver
cat << END > cuda_ver/CMakeLists.txt
cmake_minimum_required(VERSION 3.17)
project(cudaVer)
find_package(CUDA "9.0") 
if(CUDA_FOUND)
	message(STATUS "CUDA VERSION \${CUDA_VERSION}")
	message(STATUS "CUDA_TOOLKIT_ROOT_DIR \${CUDA_TOOLKIT_ROOT_DIR}")
endif()
END
cd cuda_ver
if [ ! -z $CUDA_HOME ];
then
	cmake -DCUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME . > cmake_out.log
else
	cmake . > cmake_out.log
fi
CUDA_VERSION=$(grep "CUDA VERSION" cmake_out.log | sed 's/.*CUDA VERSION //g')
if [ ! -z $CUDA_VERSION ];
then
USE_CUDA=yes
fi
cd ..




## MKL
mkdir mkl_ver
cat << END > mkl_ver/CMakeLists.txt
cmake_minimum_required(VERSION 3.17)
project(mklVer)
find_package(MKL)
message(STATUS "MKL ROOT \${MKL_ROOT}")
END
cd mkl_ver
if [ ! -z $MKL_ROOT ];
then
  cmake -DMKL_ROOT=$MKL_ROOT . > cmake_out.log
else
  cmake . > cmake_out.log
fi
MKL_ROOT=$(grep "MKL ROOT" cmake_out.log | sed 's/.*MKL ROOT //g')
cd ..





## Construct chipset fingerprint
instr=""
for kw in sse2 ssse3 avx avx2 avx512 avx512vnni; do
  if grep -q " $kw " /proc/cpuinfo; then
    instr="$instr-$kw"
  fi
done
instr=${instr:1:100}
  # strip the leading -

if [ ! x$USE_CUDA == xyes ]; then
  warn "Compiling Marian **without** GPU support."
  cuda_flag="-DCOMPILE_CUDA=off"
  fingerprint="CPUONLY-CPU-$instr"
else
  warn "Compiling Marian with this CUDA_HOME: $CUDA_HOME"
  cuda_flag="-DCUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME"
  fingerprint="CUDA-$CUDA_VERSION-CPU-$instr"
fi
warn "Compiling this version: $fingerprint"

# check if the desired branch exists (test works also with BRANCH == "")
if ! git ls-remote --heads "$marianrepo" | grep "refs/heads/$BRANCH" -q; then \
  echo "The branch '$BRANCH' does not exist at $marianrepo, assuming it is a commit"
fi

# get cmake
#CMAKE=/cvmfs/software.metacentrum.cz/spack1/software/cmake/linux-debian10-x86_64/3.17.3-intel-xadmgc/bin/cmake
CMAKE=$(which cmake)
if [ -z "$CMAKE" ]; then
  if [ ! -e cmake-3.19.6 ]; then
    wget https://cmake.org/files/v3.19/cmake-3.19.6.tar.gz
    tar xzf cmake-3.19.6.tar.gz
    cd cmake-3.19.6
    ./configure --prefix=.
    make -j16
    make install
    cd $TARGETDIR
  else
    warn "Will use the existing ./cmake-3.19.6"
  fi
  usecmake=$TARGETDIR/cmake-3.19.6/bin/cmake
else
  usecmake=$CMAKE
fi
warn "Using cmake: $usecmake"

# get marian
if [ ! -e marian ]; then
  git clone "$marianrepo" marian
  cd marian
  [ -z "$BRANCH" ] || git checkout "$BRANCH"
  cd $TARGETDIR
else
  warn "Will use the existing ./marian/"
fi

set -ex

#TODO check more possible MKL paths before downloading
if [ -z $MKL_ROOT ];then
   echo "### WARNING: Downloading MKL library from Intel, by using this installer you agree with the conditions of Intel's EULA here: https://software.intel.com/content/www/us/en/develop/articles/end-user-license-agreement.html"
  if [ -f ~/intel/installercache/intel.installer.oneapi.linux.installer/intel.oneapi.lin.onemkl.package,v=2021.2.0-296/state.json ];
  then
	 MKL_ROOT=$(cat ~/intel/installercache/intel.installer.oneapi.linux.installer/intel.oneapi.lin.onemkl.package,v=2021.2.0-296/state.json | grep installDir | head -n1 | sed 's/.*: //g' | sed 's/"//g' | sed 's/,//g')
	MKL_ROOT=$MKL_ROOT/mkl/2021.2.0/
	if [ ! -e $MKL_ROOT ]; then
	rm -rf  ~/intel/installercache/
	MKL_ROOT=
	fi
  fi
 if [ -z $MKL_ROOT ];then
  wget https://registrationcenter-download.intel.com/akdlm/irc_nas/17757/l_onemkl_p_2021.2.0.296_offline.sh
  bash l_onemkl_p_2021.2.0.296_offline.sh -a --action install  -s --eula accept --install-dir "$TARGETDIR"/mkl
#  install_exit_code=$?
 # if [ $install_exit_code -eq 1 ]; then
    MKL_ROOT="$TARGETDIR"/mkl/mkl/2021.2.0/
fi
    MKL_STRING=" -DMKL_INCLUDE_DIR=$MKL_ROOT/include/ -DMKL_ROOT=$MKL_ROOT "
  #else
  #  warn "MKL install failed"
  #fi
fi

if [ ! -e marian/build-$fingerprint ]; then
  warn "RUNNING BUILD in marian/build-$fingerprint"
  mkdir marian/build-$fingerprint
  cd marian/build-$fingerprint

  # build marian
  $usecmake \
    $cuda_flag $MKL_STRING \
    -DBOOST_ROOT=$BOOST/ \
    -DBOOST_INCLUDEDIR=$BOOST/include \
    -DBOOST_LIBRARYDIR=$BOOST/lib \
	-DUSE_SENTENCEPIECE=on \
	-DBUILD_CPU=on \
	-DUSE_DOXYGEN=off \
    -DBoost_DEBUG=1 ..
	
  # compile marian
  make -j16 VERBOSE=1
  # check if GPU version was compiled
  if [ ! x$USE_CUDA == xyes ]; then
    [ -x ./marian ] \
      || die "Marian was not compiled, probably failed to find CUDA?"
  fi
  # go back to our target dir
  cd $TARGETDIR
fi

# create the automatic guessing which build to use
if [ ! -e ./guessmarian ]; then
  cat << KONEC > ./guessmarian
#!/bin/bash
# run the appropriate compilation of marian(-decoder/-scorer)
# create a symlink to this script called guessmarian-decoder to get the
# decoder, etc.
function die() { echo "\$@" >&2; exit 1; }
hn=\$(hostname)
if [ -e $TARGETDIR/marian/build-\$hn ]; then
# exact build for the machine, probably may be useful for some exceptions
  need=\$hn
else
  # Guessing build based on CUDA version and chipset

  instr=""
  for kw in sse2 ssse3 avx avx2 avx512 avx512vnni; do
    if grep -q " \$kw " /proc/cpuinfo; then
      instr="\$instr-\$kw"
    fi
  done
  instr=\${instr:1:100}
    # strip the leading -

### If you have custom CUDA installation, put the path in here (auto-detection mostly works on systems with cuda installed through package manager, as well as Metacentrum and IT4I):
#UFAL:
CUDA_HOME=/opt/cuda/11.7

#Lingea:
CUDA_HOME=/usr/local/cuda-11.8/

### Environment-specific steps and settings
#Metacentrum (hostname list might not be exhaustive, please let the authors know if you end up with a node using another hostname)
hostname=\$(hostname)
if [[ "\$hostname" =~ metacentrum.cz ]] || [[ "\$hostname" =~ grid.cesnet.cz ]] || [[ "\$hostname" =~ cerit-sc.cz ]] || [[ "\$hostname" =~ natur.cuni.cz ]] 
then
  # adan and doom
  module load gcc/8.3.0 cmake cuda/11.6 python/3.9.12-gcc-10.2.1-rg2lpmk
fi

#IT4I
if  [[ "\$hostname" =~ it4i.cz ]]
then
        module load CMake/3.20.1-GCCcore-10.3.0 CUDA/11.7.0
fi

### Less environment specific steps

## CUDA
mkdir cuda_ver
cat << END > cuda_ver/CMakeLists.txt
cmake_minimum_required(VERSION 3.17)
project(cudaVer)
find_package(CUDA "9.0") 
if(CUDA_FOUND)
	message(STATUS "CUDA VERSION \\\${CUDA_VERSION}")
	message(STATUS "CUDA_TOOLKIT_ROOT_DIR \\\${CUDA_TOOLKIT_ROOT_DIR}")
endif()
END
cd cuda_ver
if [ ! -z \$CUDA_HOME ];
then
	cmake -DCUDA_TOOLKIT_ROOT_DIR=\$CUDA_HOME . > cmake_out.log
else
	cmake . > cmake_out.log
fi
CUDA_VERSION=\$(grep "CUDA VERSION" cmake_out.log | sed 's/.*CUDA VERSION //g')
if [ ! -z \$CUDA_VERSION ];
then
USE_CUDA=yes
fi
cd ..
if [ -e $TARGETDIR/marian/build-CUDA-\$CUDA_VERSION-CPU-\$instr/marian ]
  then
    need="CUDA-\$CUDA_VERSION-CPU-\$instr"
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cuda/$CUDA_VERSION/lib64:/opt/cuda/$CUDA_VERSION/cudnn/$CUDNN/
  else
      echo "no suitable CUDA found, falling back to CPU-only (can't be used for training)" >&2
      CUDA_VERSION=
    fi
    need="CUDA-$CUDA_VERSION"
    if [[ ! -z "\$CUDA_VERSION" ]]; then
      need="CUDA-\$CUDA_VERSION-CPU-\$instr"
    else
      need=CPUONLY-CPU-\$instr
    fi
  fi
guessed=\$( ls -d $TARGETDIR/marian/build-* \
            | grep "\$need" \
            | head -n 1 )
[ -d "\$guessed" ] || die "No matching build found: \$guessed (\$need)"
programname=\$(basename \$0 | sed 's/guess//')
MARIAN="\$guessed/\$programname"
echo "Guessed marian: \$MARIAN" >&2
export LD_LIBRARY_PATH=$GCC/lib64/:\$LD_LIBRARY_PATH
echo "========== guessmarian reports details: env" >&2
env >&2
echo "========== guessmarian reports details: ldd" >&2
ldd \$MARIAN >&2
echo "========== guessmarian runs:" >&2
set -x
\$MARIAN "\$@"
exit \$?
KONEC
  chmod 755 guessmarian
fi

[ -e ./guessmarian-decoder ] || ln -s ./guessmarian ./guessmarian-decoder
[ -e ./guessmarian-scorer ] || ln -s ./guessmarian ./guessmarian-scorer
