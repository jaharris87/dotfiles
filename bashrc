#!/bin/bash

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

## If not running interactively, don't do anything
[[ $- = *i* ]] || return

## Use custom terminal prompt
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
white=$(tput setaf 7)
black=$(tput setaf 0)
bold=$(tput bold)
reset=$(tput sgr0)

if [[ -f $HOME/.git-prompt.sh ]]; then
    . $HOME/.git-prompt.sh
    export GIT_PS1_SHOWDIRTYSTATE=1
    export PROMPT_COMMAND='__git_ps1 "\[$bold$yellow\]\u@\h\[$reset\]:\[$bold$green\]" "\[$reset\] \[$bold$white\]\w\[$reset\]> "'
    #export PS1="\[$bold$yellow\]\u@\h\[$reset\]:\[$bold$blue\]$(__git_ps1 " (%s)")\[$reset\] \[$bold$white\]\w\[$reset\]> "
else
    function parse_git_branch {
       git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
    }
    export PS1="\[$bold$yellow\]\u@\h\[$reset\]: \[$bold$white\]\w\[$reset\]\$(parse_git_branch)> "
fi

if [[ -f $HOME/.git-completion.bash ]]; then
    . $HOME/.git-completion.bash
fi

#if [[ -f $HOME/.vim-completion.bash ]]; then
#    . $HOME/.vim-completion.bash
#fi

#export PS1="\[$bold$yellow\]\u@\h\[$reset\]: \[$bold$white\]\w\[$reset\]> "

## Export commands to history as they are executed (allows shared history between screen sessions)
#export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

## Compare version numbers
## source: https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
## question author: https://askubuntu.com/users/235/jorge-castro
## answer author: https://stackoverflow.com/users/26428/dennis-williamson
vercomp () {
    if [[ $1 = $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

## Who am I?
export USER=$(whoami)

## Get full hostname, including domain (i.e. Fully Qualified Domain Name)
export FQDN=$(hostname -f)

## Trim extras off HOSTNAME (e.g. -ext2, edison05, cori10)
if [[ ! -z ${LMOD_SYSTEM_NAME+x} ]]; then
  export HOST_SHORT=${LMOD_SYSTEM_NAME}
else
  export HOST_SHORT="$(echo ${FQDN} | \
      sed -e 's/\.\(olcf\|ccs\)\..*//' \
          -e 's/[-]\?\(login\|ext\|batch\|[a-z][0-9]\+n[0-9]\+\)[^\.]*[\.]\?//' \
          -e 's/[-0-9]*\([\.][^\.]\+\)\?$//' \
          -e 's/\..*$//')"
fi

## Get computing facility name (e.g. NERSC, OLCF, ALCF, NCSA)
if [[ $FQDN = *"ornl.gov" || \
      $HOST_SHORT = "lyra" ]]; then
    export FACILITY="OLCF"
elif [[ $FQDN = *"cm.cluster" || \
        $FQDN = *"cray.com" ]]; then
    export FACILITY="CRAY"
elif [[ ! -z ${NERSC_HOST+x} ]]; then
    HOST_SHORT=$NERSC_HOST
    export FACILITY="NERSC"
elif [[ $FQDN = *"anl.gov" ]]; then
    export FACILITY="ALCF"
elif [[ $FQDN = *"tennessee.edu" ]]; then
    export FACILITY="NICS"
else
    export FACILITY="local"
fi

## Set default project IDs
if [[ ! "$(uname)" = "Darwin" ]]; then
  export PROJIDS=$(groups | grep -o '\<[a-z]\+[0-9]\+\>')
  if [[ $FACILITY = "OLCF" ]]; then
      if [[ $HOST_SHORT = "ascent" ]]; then
          export PROJID="gen109"
      elif [[ $HOST_SHORT = "summit" ]]; then
          export PROJID="ast203"
      elif [[ $HOST_SHORT = "spock" || $HOST_SHORT = "borg" || $HOST_SHORT = "crusher" ]]; then
          export PROJID="stf006"
      elif [[ $HOST_SHORT = "frontier" ]]; then
          export PROJID="ast137"
      else
          export PROJID="stf006"
      fi
  elif [[ $FACILITY = "CRAY" ]]; then
      export PROJID=""
  elif [[ $FACILITY = "NERSC" ]]; then
      export PROJID="m1373"
  elif [[ $FACILITY = "ALCF" ]]; then
      export PROJID=""
  else
      export PROJID=""
  fi
  for PID in $PROJIDS; do
      PID_UC=$(echo $PID | tr '[:lower:]' '[:upper:]')
      export ${PID_UC}_USERS=$(getent group $PID | sed 's/^.*://')
  done
  export PROJ_USERS=$(getent group $PROJID | sed 's/^.*://')
fi

## Load custom aliases
if [[ -f $HOME/.aliases.$HOST_SHORT ]]; then
    . $HOME/.aliases.$HOST_SHORT
elif [[ -f $HOME/.aliases ]]; then
    . $HOME/.aliases
fi

## Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

## Enable extended globbing
shopt -s extglob

## Do not add space after tab-complete of directory (only in versions of bash >= 4.2.29)
bashver=$(echo ${BASH_VERSINFO[@]:0:3} | tr ' ' '.')
vertest=$(vercomp $bashver 4.2.29)
vertestresult=$?
[[ $vertestresult -lt 2 ]] && shopt -s direxpand
unset bashver vertest vertestresult

## Ignore duplicate history entries
#export HISTCONTROL=ignoredups

## Ignore duplicate history entries AND entries beginning with a space
export HISTCONTROL=ignoreboth

## Limit to number of commands saved in history
export HISTFILESIZE=1000000
export HISTSIZE=1000000

## Set default editor
export EDITOR=vim

## Useful flags for 'less' (including color support)
export LESS="--ignore-case --status-column --RAW-CONTROL-CHARS -F $LESS"
# Use colors for less, man, etc.
[[ -f ~/.LESS_TERMCAP ]] && . ~/.LESS_TERMCAP

## Create lower-case PE_ENV (for use in modules)
[[ ! -z ${PE_ENV+x} ]] && export LC_PE_ENV=$(echo ${PE_ENV} | tr A-Z a-z)

## Number of processors on this node
#if [[ -f /proc/cpuinfo ]]; then
#    export NPROC=$(grep "^core id" /proc/cpuinfo | sort -u | wc -l)
#    export NPROCS=$(grep "^core id" /proc/cpuinfo | sort -u | wc -l)
#fi

## Set facility/machine specific environment variables
if [[ $FACILITY = "OLCF" ]]; then
    ## Scratch directory environment variables for Summit/SummitDev are not yet created by default
    if [[ -d /lustre/orion ]]; then
        ## Frontier
        export MEMBERWORK=/lustre/orion/scratch/$USER
        export PROJWORK=/lustre/orion/proj-shared
        export WORLDWORK=/lustre/orion/world-shared
        #export MEMBERWORK=/lustre/orion/$PROJID/scratch/$USER
        #export PROJWORK=/lustre/orion/$PROJID/proj-shared/$USER
        #export WORLDWORK=/lustre/orion/$PROJID/world-shared/$USER
    elif [[ -d /gpfs/alpine2 ]]; then
        ## Summit, SummitDev, Peak, Rhea
        export MEMBERWORK=/gpfs/alpine2/scratch/$USER
        export PROJWORK=/gpfs/alpine2/proj-shared
        export WORLDWORK=/gpfs/alpine2/world-shared
    elif [[ -d /gpfs/alpinetds ]]; then
        ## Ascent
        export MEMBERWORK=/gpfs/alpinetds/scratch/$USER
        export PROJWORK=/gpfs/alpinetds/proj-shared
        export WORLDWORK=/gpfs/alpinetds/world-shared
    elif [[ -d /gpfs/wolf ]]; then
        ## Ascent
        export MEMBERWORK=/gpfs/wolf/scratch/$USER
        export PROJWORK=/gpfs/wolf/proj-shared
        export WORLDWORK=/gpfs/wolf/world-shared
    else
        ## Lyra, home, hub, dtn, ...
        export MEMBERWORK=$HOME
        export PROJWORK=$HOME
        export WORLDWORK=$HOME
    fi
    [[ -d $MEMBERWORK/$PROJID ]] && export WORKDIR=$MEMBERWORK/$PROJID || export WORKDIR=$MEMBERWORK/stf006

    ## Project-specific directories
    [[ -d $PROJWORK/$PROJID/$USER ]] && export PROJWORKDIR=$PROJWORK/$PROJID/$USER || export PROJWORKDIR=$WORKDIR
    [[ -d /ccs/proj/$PROJID ]] && export PROJHOME=/ccs/proj/$PROJID || export PROJHOME=/ccs/proj/stf006
    export HPSS_PROJDIR=/proj/$PROJID
    for PID in $PROJIDS; do
        PID_UC=$(echo $PID | tr '[:lower:]' '[:upper:]')
        [[ -d $PROJWORK/$PID/$USER ]] && export ${PID_UC}_WORKDIR=$PROJWORK/${PID}/$USER || export ${PID_UC}_WORKDIR=$WORKDIR
        [[ -d /ccs/proj/${PID} ]] && export ${PID_UC}_HOME=/ccs/proj/${PID} || export ${PID_UC}_HOME=$PROJHOME
        export HPSS_${PID_UC}_DIR=/proj/$PID
    done

    ## If system has Lmod ...
    if [[ ! -z ${LMOD_CMD+x} ]]; then
        ## ... Add custom modules to path
        ## `module use` command will prefer whichever path was added most recently,
        ## and we want the order of preference to be user > project > world
        for PID in $PROJIDS; do
            PID_UC=$(echo $PID | tr '[:lower:]' '[:upper:]')
            PID_HOME=${PID_UC}_HOME
            [[ -d $WORLDWORK/$PID/modulefiles/$HOST_SHORT ]] && module use $WORLDWORK/$PID/modulefiles/$HOST_SHORT
        done
        for PID in $PROJIDS; do
            PID_UC=$(echo $PID | tr '[:lower:]' '[:upper:]')
            PID_HOME=${PID_UC}_HOME
            [[ -d /ccs/proj/${PID}/modulefiles/$HOST_SHORT ]] && module use /ccs/proj/${PID}/modulefiles/$HOST_SHORT
        done
        [[ -d $HOME/modulefiles/$HOST_SHORT ]] && module use $HOME/modulefiles/$HOST_SHORT
        ## Load newer git
        module try-load git
        ## Load newer subversion
        module try-load subversion
        ## Load python
        module try-load python
    fi
    ## Add manually built diffutils to paths
    if [[ -d $HOME/sw/$HOST_SHORT/diffutils ]]; then
        export PATH=$HOME/sw/$HOST_SHORT/diffutils/bin:$PATH
        export MANPATH=$HOME/sw/$HOST_SHORT/diffutils/share/man:$MANPATH
        export INFOPATH=$HOME/sw/$HOST_SHORT/diffutils/share/info:$MANPATH
    fi
    ## Add manually built VIM to paths
    if [[ -d $HOME/sw/$HOST_SHORT/vim ]]; then
        export PATH=$HOME/sw/$HOST_SHORT/vim/bin:$PATH
        export MANPATH=$HOME/sw/$HOST_SHORT/vim/share/man:$MANPATH
    fi
    ## Add manually built makedepf90 to paths
    if [[ -d $HOME/sw/$HOST_SHORT/makedepf90 ]]; then
        export PATH=$HOME/sw/$HOST_SHORT/makedepf90/bin:$PATH
        export MANPATH=$HOME/sw/$HOST_SHORT/makedepf90/share/man:$MANPATH
    fi
    ## Add manually built pbzip2 to paths
    if [[ -d $HOME/sw/$HOST_SHORT/pbzip2 ]]; then
        export PATH=$HOME/sw/$HOST_SHORT/pbzip2/bin:$PATH
        export MANPATH=$HOME/sw/$HOST_SHORT/pbzip2/share/man:$MANPATH
    fi
    ## Add manually built screen to paths
    if [[ -d $HOME/sw/$HOST_SHORT/screen ]]; then
        export PATH=$HOME/sw/$HOST_SHORT/screen/bin:$PATH
        export MANPATH=$HOME/sw/$HOST_SHORT/screen/share/man:$MANPATH
        export INFOPATH=$HOME/sw/$HOST_SHORT/screen/share/info:$MANPATH
    fi
    ## Default machine for weaklib/thornado
    export WEAKLIB_MACHINE=${HOST_SHORT}_${LMOD_FAMILY_COMPILER}
    export THORNADO_MACHINE=${HOST_SHORT}_${LMOD_FAMILY_COMPILER}
elif [[ $FACILITY = "CRAY" ]]; then
    export WORKDIR=$HOME
    export PROJHOME=$HOME
    export PROJWORKDIR=$WORKDIR
    export HPSS_PROJDIR=$PROJHOME
    #module load PrgEnv-cray
    if [[ ! -z ${LMOD_CMD+x} ]]; then
      ## ... Add custom modules to path
      [[ -d $HOME/modulefiles/$HOST_SHORT ]] && module use $HOME/modulefiles/$HOST_SHORT
    fi
    export WEAKLIB_MACHINE=${HOST_SHORT}_${LMOD_FAMILY_COMPILER}
    export THORNADO_MACHINE=${HOST_SHORT}_${LMOD_FAMILY_COMPILER}
elif [[ $FACILITY = "NERSC" ]]; then
    export WORKDIR=$SCRATCH
    export PROJHOME=$CFS/$PROJID
    export PROJWORKDIR=$CFS/$PROJID/$USER
    export HPSS_PROJDIR=/home/projects/$PROJID

    shopt -u progcomp

    ### KNL by default
    #if [[ $NERSC_HOST = "cori" ]]; then
    #    module swap PrgEnv-$LC_PE_ENV PrgEnv-intel
    #    module swap craype-$CRAY_CPU_TARGET craype-mic-knl
    #fi
    ### Load newer subversion
    #module load subversion
    ### Unlaod darhsan
    #module unload darshan

    ## If system has Lmod ...
    if [[ ! -z ${LMOD_CMD+x} ]]; then
      ## ... Add custom modules to path
      [[ -d /global/common/software/m1373/modulefiles/$HOST_SHORT ]] && module use /global/common/software/m1373/modulefiles/$HOST_SHORT
      [[ -d /global/common/software/m3961/modulefiles/$HOST_SHORT ]] && module use /global/common/software/m3961/modulefiles/$HOST_SHORT
      [[ -d /global/common/software/chimera/modulefiles/$HOST_SHORT ]] && module use /global/common/software/chimera/modulefiles/$HOST_SHORT
      [[ -d $HOME/modulefiles/$HOST_SHORT ]] && module use $HOME/modulefiles/$HOST_SHORT
      ## Load newer git
      module try-load git
      ## Load newer subversion
      module try-load subversion
    fi
elif [[ $FACILITY = "local" ]]; then
    export WORKDIR=$HOME
    export PROJHOME=$HOME
    export PROJWORKDIR=$WORKDIR
    export HPSS_PROJDIR=$PROJHOME

    ## Mac OS X
    if [[ "$(uname)" = "Darwin" ]]; then

        [[ -z ${HOMEBREW_PREFIX+x} ]] && export HOMEBREW_PREFIX="$(brew --prefix)"
        [[ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]] && . "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"

        if type brew &>/dev/null
        then
          if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]
          then
            source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
          else
            for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*
            do
              [[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
            done
          fi
        fi

        export LD_LIBRARY_PATH=$HOMEBREW_PREFIX/lib:$LD_LIBRARY_PATH
        export MANPATH=$HOMEBREW_PREFIX/share/man:$MANPATH
        export GS_FONTPATH=$GS_FONTPATH:~/Library/Fonts

        ## Use GNU utils when available
        export PATH=$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin:$PATH
        export PATH=$HOMEBREW_PREFIX/opt/findutils/libexec/gnubin:$PATH
        export PATH=$HOMEBREW_PREFIX/opt/gawk/libexec/gnubin:$PATH
        export PATH=$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnubin:$PATH
        export PATH=$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnubin:$PATH
        export PATH=$HOMEBREW_PREFIX/opt/gnu-which/libexec/gnubin:$PATH
        export PATH=$HOMEBREW_PREFIX/opt/grep/libexec/gnubin:$PATH
        export PATH=$HOMEBREW_PREFIX/opt/make/libexec/gnubin:$PATH

        export MANPATH=$HOMEBREW_PREFIX/opt/coreutils/libexec/gnuman:$MANPATH
        export MANPATH=$HOMEBREW_PREFIX/opt/findutils/libexec/gnuman:$MANPATH
        export MANPATH=$HOMEBREW_PREFIX/opt/gawk/libexec/gnuman:$MANPATH
        export MANPATH=$HOMEBREW_PREFIX/opt/gnu-sed/libexec/gnuman:$MANPATH
        export MANPATH=$HOMEBREW_PREFIX/opt/gnu-tar/libexec/gnuman:$MANPATH
        export MANPATH=$HOMEBREW_PREFIX/opt/gnu-which/libexec/gnuman:$MANPATH
        export MANPATH=$HOMEBREW_PREFIX/opt/grep/libexec/gnuman:$MANPATH
        export MANPATH=$HOMEBREW_PREFIX/opt/make/libexec/gnuman:$MANPATH

        ## Use Homebrew python3 as default python
        #export PATH=$HOMEBREW_PREFIX/opt/python/libexec/bin:$PATH

        ## Add VisIt bin directory to PATH
        export PATH=/Applications/VisIt.app/Contents/Resources/bin:$PATH

        ## Add PGI to PATH
        export PGI=/opt/pgi
        export LM_LICENSE_FILE=$PGI/license.dat
        export PATH=$PGI/osx86-64/19.4/bin:$PATH

        ## Add PGI MPICH to PATH
        #export PATH=$PGI/osx86-64/2018/mpi/mpich/bin:$PATH

        ## Compiler variables
        #export CC=gcc-9
        #export CXX=g++-9
        #export CPP=cpp-9
        #export CXXCPP=cpp-9
        #export FC=gfortran-9

        ## Homebrew compilers
        export HOMEBREW_CC=gcc-14
        export HOMEBREW_CXX=g++-14
        export HOMEBREW_CPP=cpp-14
        export HOMEBREW_CXXCPP=cpp-14
        export HOMEBREW_FC=gfortran-14
        export HOMEBREW_VERBOSE=1

        ## Open-MPI
        export OMPI_DIR=$HOMEBREW_PREFIX
        export OMPI_ROOT=$OMPI_DIR
        export OMPI_CC=gcc-14
        export OMPI_CXX=g++-14
        export OMPI_FC=gfortran-14

        ## HDF5
        export HDF5_DIR=$HOMEBREW_PREFIX/Cellar/hdf5-parallel/1.14.6
        export HDF5_ROOT=$HDF5_DIR
        export HDF5_INCLUDE_DIRS=$HDF5_DIR/include
        export HDF5_INCLUDE_OPTS=$HDF5_INCLUDE_DIRS
        export PATH=$HDF5_DIR/bin:$PATH

        ## Pardiso
        export PARDISO_DIR=/usr/local/pardiso
        export PARDISO_LIC_PATH=$PARDISO_DIR
        export PARDISOLICMESSAGE=1

        ## Default machine for weaklib/thornado
        export WEAKLIB_MACHINE=mac_gnu
        export THORNADO_MACHINE=mac_gnu

        ## Android SDK
        export ANDROID_HOME=/Users/$USER/Library/Android/sdk
        export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH

        export BOOST_ROOT=$HOMEBREW_PREFIX/Cellar/boost/1.76.0/include
        export QTDIR=$HOMEBREW_PREFIX/Cellar/qt@5/5.15.2

        export PATH=$QTDIR/bin:$PATH

        export CMAKE_MODULE_PATH=$QTDIR/lib/cmake
        export CMAKE_C_COMPILER=gcc-14
        export CMAKE_CXX_COMPILER=g++-14
        export CMAKE_FC_COMPILER=gfortran-14
     elif [[ "$(uname)" = "Linux" ]]; then

        ## Add VisIt bin directory to PATH
        export PATH=/usr/local/visit/bin:$PATH

        ## Add Spack to PATH
        #export SPACK_ROOT=/home/hrh/spack
        #. $SPACK_ROOT/share/spack/setup-env.sh

        ## Add PGI to PATH
        export PGI=/opt/pgi
        export PATH=$PGI/linux86-64/19.10/bin:$PATH
        export LD_LIBRARY_PATH=$PGI/linux86-64/19.10/lib:$LD_LIBRARY_PATH
        export MANPATH=$PGI/linux86-64/19.10/man:$MANPATH
        export LM_LICENSE_FILE=$PGI/license.dat:$LM_LICENSE_FILE

        ## Add Intel to PATH
        #export INTEL_PATH=/opt/intel/compilers_and_libraries_2020/linux
        ##export PATH=$INTEL_PATH/bin/intel64:$PATH
        ##export MANPATH=$MANPATH:$INTEL_PATH/man/common
        ##export MKLROOT=$INTEL_PATH/mkl
        #. $INTEL_PATH/bin/compilervars.sh intel64

        if [[ $HOST_SHORT = "etacar" ]]; then

          ## Open-MPI
          export OMPI_DIR=$HOME/sw/etacar/gcc/11.1.0/openmpi-4.0.3
          export OMPI_ROOT=$OMPI_DIR
          export PATH=$OMPI_DIR/bin:$PATH

          ## MPICH
          #export MPICH_DIR=/usr/lib/mpich
          #export MPICH_ROOT=$MPICH_DIR

          ## HDF5
          export HDF5_DIR=$HOME/sw/etacar/gcc/11.1.0/hdf5-openmpi-1.12.2
          export HDF5_ROOT=$HDF5_DIR
          export HDF5_INCLUDE_DIRS=$HDF5_DIR/include
          export HDF5_INCLUDE_OPTS=$HDF5_INCLUDE_DIRS
          export PATH=$HDF5_DIR/bin:$PATH

        fi
    fi
fi

## Add local bin to path
if [[ -d $HOME/.local/bin ]]; then
    export PATH=$HOME/.local/bin:$PATH
fi

## Add local directories to environment
export PATH=$HOME/bin:$PATH
export MANPATH=$HOME/share/man:$MANPATH
export INFOPATH=$HOME/share/info:$MANPATH
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH

## Set global environment variables (same on all machines)
export CHIMERA=$HOME/chimera/trunk/Chimera
export DCHIMERA=$HOME/chimera/tags/D-production
export FCHIMERA=$HOME/chimera/tags/F-production
export GCHIMERA=$HOME/chimera/tags/G-production
export TRACER_READER=$HOME/chimera/trunk/Tools/tracer_reader
export INITIAL_MODELS=$HOME/chimera/trunk/Initial_Models
export MODEL_GENERATOR=$INITIAL_MODELS/Model_Generator

export WEAKLIB_DIR=$HOME/weaklib
export WEAKLIB_HOME=$WEAKLIB_DIR

export THORNADO_DIR=$HOME/thornado
export THORNADO_HOME=$THORNADO_DIR

export AMREX_ROOT=$HOME/AMReX-Codes
export AMREX_DIR=$AMREX_ROOT/amrex
export AMREX_HOME=$AMREX_DIR

export AMREX_ASTRO_ROOT=$HOME/AMReX-Astro
export CASTRO_DIR=$AMREX_ASTRO_ROOT/Castro
export MAESTRO_DIR=$AMREX_ASTRO_ROOT/MAESTRO
export CASTRO_HOME=$CASTRO_DIR
export MAESTRO_HOME=$MAESTRO_DIR

export STARKILLER_ROOT=$HOME/starkiller-astro
export MICROPHYSICS_DIR=$STARKILLER_ROOT/Microphysics
export MICROPHYSICS_HOME=$MICROPHYSICS_DIR

export XNET_DIR=$STARKILLER_ROOT/XNet
export XNET_HOME=$XNET_DIR
export XNET=$XNET_DIR

export BOXLIB_ROOT=$HOME/BoxLib-Codes
export BOXLIB_DIR=$BOXLIB_ROOT/BoxLib
export BOXLIB_HOME=$BOXLIB_ROOT/BoxLib
#export BOXLIB_USE_MPI_WRAPPERS=1

[[ -d $AST136_WORKDIR ]] && export WEAKLIB_TABLES=$AST136_WORKDIR/weaklib-tables || export WEAKLIB_TABLES=$PROJWORKDIR/weaklib-tables

[[ -d $AST136_HOME/$USER ]] && export FLASH_ROOT=$AST136_HOME/$USER || export FLASH_ROOT=$PROJHOME/$USER
[[ -d $AST136_WORKDIR ]] && export FLASH_RUN_ROOT=$AST136_WORKDIR || export FLASH_RUN_ROOT=$PROJWORKDIR
[[ ! -d $FLASH_ROOT ]] && export FLASH_ROOT=$HOME
[[ ! -d $FLASH_RUN_ROOT ]] && export FLASH_RUN_ROOT=$HOME

export FLASHOR=$FLASH_ROOT/FLASHOR
export FLASHOR_RUN=$FLASH_RUN_ROOT/FLASHOR_run
export XNET_FLASHOR=$FLASHOR/source/physics/sourceTerms/Burn/BurnMain/nuclearBurn/XNet
export HELMHOLTZ_FLASHOR=$FLASHOR/source/physics/Eos/EosMain/Helmholtz

export FLASH5=$FLASH_ROOT/FLASH5
export FLASH5_RUN=$FLASH_RUN_ROOT/FLASH5_run
export XNET_FLASH5=$FLASH5/source/physics/sourceTerms/Burn/BurnMain/nuclearBurn/XNet
export HELMHOLTZ_FLASH5=$FLASH5/source/physics/Eos/EosMain/Helmholtz

export FLASHX=$FLASH_ROOT/Flash-X
export FLASHX_RUN=$FLASH_RUN_ROOT/Flash-X_run

export FLASH_DIR=$FLASHX
export FLASH_RUN=$FLASHX_RUN
export XNET_FLASH=$FLASH_DIR/source/physics/sourceTerms/Burn/BurnMain/nuclearBurn/XNet
export HELMHOLTZ_FLASH=$FLASH_DIR/source/physics/Eos/EosMain/Helmholtz
export WEAKLIB_FLASH=$FLASH_DIR/source/physics/Eos/EosMain/WeakLib
export RADTRANS_FLASH=$FLASH_DIR/source/physics/RadTrans/RadTransMain
export THORNADO_FLASH=$FLASH_DIR/source/physics/RadTrans/RadTransMain/TwoMoment/Thornado
export SPARK_FLASH=$FLASH_DIR/source/physics/Hydro/HydroMain/Spark
export SIM_FLASH=$FLASH_DIR/source/Simulation/SimulationMain

[[ -d $HOME/magma ]] && export MAGMA_DIR=$HOME/magma
[[ -d $HOME/hypre ]] && export HYPRE_DIR=$HOME/hypre
[[ ! -z ${MAGMA_DIR} ]] && export MAGMA_ROOT=$MAGMA_DIR
[[ ! -z ${HYPRE_DIR} ]] && export HYPRE_ROOT=$HYPRE_DIR

export HELMHOLTZ_PATH=$HOME/helmholtz

export MESA_DIR=$HOME/mesa
export MESASDK_ROOT=$HOME/mesasdk
export PGPLOT_DIR=$HOME/mesasdk/pgplot
export MESA_CACHES_DIR=$WORKDIR/mesa_execute/data

## Do any extra local initialization
[[ -f $HOME/.bashrc.local ]] && . $HOME/.bashrc.local

## Set appropriate colors
use_color=false
safe_term=${TERM//[^[:alnum:]]/?}
match_lhs=""
[[ -f ~/.dir_colors ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs} ]] \
 && type -P dircolors >/dev/null \
 && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} = *$'\n'"TERM "${safe_term}* ]] && use_color=true
if ${use_color} ; then
 if type -P dircolors >/dev/null ; then
     if [[ -f ~/.dir_colors ]] ; then
         eval $(dircolors -b ~/.dir_colors)
     elif [[ -f /etc/DIR_COLORS ]] ; then
         eval $(dircolors -b /etc/DIR_COLORS)
     else
         eval $(dircolors)
     fi
 fi
fi
unset use_color safe_term match_lhs
