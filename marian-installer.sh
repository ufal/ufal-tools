# eman step for building marian

repo=https://github.com/marian-nmt/marian-dev.git

## EMAN IGNORE
# Any part of the code labelled like thisis not used by eman at all, you can
# use it when running this script directly
# A useful thing to do is to prevent 'eman' commands from doing anything
alias eman="echo"
function die() { echo "$@" >&2; exit 1; }

## EMAN INIT
# eman variables get defined here
eman \
  defvar BRANCH default='' help='which marian branch to use' \
  defvar BOOST help='which boost to use' \
    default='/net/me/merkur3/varis/boost/boost_1_56_0-py3.5-g++5.4' \
  defvar CMAKE help='which cmake to use' \
    default='' \
  defvar GCC help='which gcc to use' \
    default='/ha/opt/x86_64/tools/gcc/gcc-5.4.0' \
  defvar EMAN_QUEUE default='gpu.q' help="which queue to submit to" \
  defvar EMAN_GPUS default='1' help="need a machine with CUDA by default" \
  defvar EMAN_GPUMEM default='6g' help="one of UFAL's better machines" \
  defvar USE_CUDA default='yes' \
    help='compile Marian with CUDA support; the particular value of this variable is probably ignored but you can set it to empty to compile only non-GPU parts of Marian, i.e. marian-decoder with only CPU support' \
  defvar CUDA_HOME="/opt/cuda/10.1/"
#TODO - everything aboce this?
# another TODO - if we want AVX512VNNI (some new intel stuff for 8bit matrix operations, it is useful for small quantized student models), we need gcc > 8? maybe

# in ideal case, nvidia-smi exists and we want to use this version of CUDA
CUDA_VERSION=$(nvidia-smi | grep -oP "CUDA Version: \K...." )
USE_CUDA=yes
if [ -e /opt/cuda/$CUDA_VERSION/bin/nvcc ]
then
        CUDA_HOME="/opt/cuda/$CUDA_VERSION/"
elif [ -e /opt/cuda/10.1 ]
	then
	CUDA_HOME="/opt/cuda/10.1/"
	CUDA_VERSION=$("$CUDA_HOME/bin/nvcc" --version | grep -oP "release \K....")
else 
	USE_CUDA=no
fi

GCC=/usr/
MYDIR=/lnet/express/work/people/jon/

## EMAN PREPARE
# eman variables are usable here

# check if the desired branch exists (test works also with BRANCH == "")
if ! git ls-remote --heads "$repo" | grep "refs/heads/$BRANCH" -q; then \
  echo "The branch '$BRANCH' does not exist at $repo, assuming it is a commit"
fi

## EMAN RUN

set -ex # exit after any failure and show all commands run

# get cmake
if [ -z "$CMAKE" ]; then
  if [ ! -e cmake-3.19.6 ]; then
    wget https://cmake.org/files/v3.19/cmake-3.19.6.tar.gz
    tar xzf cmake-3.19.6.tar.gz
    cd cmake-3.19.6
    ./configure --prefix=.
    make -j16
    make install
    cd $MYDIR
  else
    echo "Will use the existing ./cmake-3.19.6"
  fi
  usecmake=$MYDIR/cmake-3.19.6
else
  usecmake=$CMAKE
fi
echo "Using cmake: $usecmake"

# get marian
if [ ! -e marian ]; then
  git clone "$repo" marian
  cd marian
  [ -z "$BRANCH" ] || git checkout "$BRANCH"
  cd $MYDIR
else
  echo "Will use the existing ./marian/"
fi

if [ ! x$USE_CUDA == xyes ]; then
  echo "Compiling Marian **without** GPU support."
  cuda_flag="-DCOMPILE_CUDA=off"
  n="CPUONLY"
else
  echo "Compiling Marian with this CUDA_HOME: $CUDA_HOME"
  cuda_flag="-DCUDA_TOOLKIT_ROOT_DIR=$CUDA_HOME"
  n="CUDA-$CUDA_VERSION"

fi

#hn=$(hostname)
if [ ! -e marian/build-$n ]; then
  echo "RUNNING BUILD in marian/build-$hn"
  mkdir marian/build-$n
  cd marian/build-$n

  # build marian
  $usecmake/bin/cmake \
    $cuda_flag \
    -DBOOST_ROOT=$BOOST/ \
    -DBOOST_INCLUDEDIR=$BOOST/include \
    -DBOOST_LIBRARYDIR=$BOOST/lib \
    -DCMAKE_C_COMPILER=$GCC/bin/gcc \
    -DCMAKE_CXX_COMPILER=$GCC/bin/g++ \
    -DCMAKE_MODULE_LINKER_FLAGS="-lutil -ldl" \
    -DCMAKE_EXE_LINKER_FLAGS="-lutil -ldl" \
    -DCMAKE_SHARED_LINKER_FLAGS="-lutil -ldl" \
    -DCMAKE_C_STANDARD_LIBRARIES="-lpthread" \
    -DCMAKE_REQUIRED_FLAGS="-lpthread" \
	-DUSE_SENTENCEPIECE=on \
	-DBUILD_CPU=on \
    -DBoost_DEBUG=1 ..
	
  # compile marian
  make -j16 VERBOSE=1
  # check if GPU version was compiled
  if [ ! x$USE_CUDA == xyes ]; then
    [ -x ./marian ] \
      || die "Marian was not compiled, probably failed to find CUDA?"
  fi
  # go back to our step dir
  cd $MYDIR
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
if [ -e $MYDIR/marian/build-\$hn ]; then
# exact build for the machine, probably may be useful for some exceptions
  need=\$hn
else
  # Guessing build from another machine at UFAL based on CUDA version
# First, try to parse nvidia-smi

CUDA_VERSION=\$(nvidia-smi | grep -oP "CUDA Version: \K...." )
  if [ -e $MYDIR/marian/build-CUDA-\$CUDA_VERSION/marian ]
	then
	need="CUDA-\$CUDA_VERSION"
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cuda/$CUDA_VERSION/lib64:/opt/cuda/$CUDA_VERSION/cudnn/$CUDNN/

  else
	if [ -e "/opt/cuda/11.1/bin/nvcc" ]
	then
	CUDNN=8.0
	CUDA_VERSION=11.1
        elif [ -e "/opt/cuda/11.0/bin/nvcc" ]
        then
        CUDNN=8.0
	CUDA_VERSION=11.0
        elif [ -e "/opt/cuda/10.2/bin/nvcc" ]
        then
        CUDNN=7.6
	CUDA_VERSION=10.2
        elif [ -e "/opt/cuda/10.1/bin/nvcc" ]
        then
	CUDNN=7.6
        CUDA_VERSION=10.1
        elif [ -e "/opt/cuda/9.2/bin/nvcc" ]
        then
        CUDNN=7.4
        CUDA_VERSION=9.2
	else
	echo "no suitable CUDA found, falling back to CPU-only (can't be used for training)"
	CUDA_VERSION=
	fi
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/cuda/$CUDA_VERSION/lib64:/opt/cuda/$CUDA_VERSION/cudnn/$CUDNN/
	need="CUDA-$CUDA_VERSION"
	if [[ ! -z "\$CUDA_VERSION" ]]
	then
	        need="CUDA-\$CUDA_VERSION"
	else
		need=CPUONLY
	fi
  fi
fi
guessed=\$( ls -d $MYDIR/marian/build-* \
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
