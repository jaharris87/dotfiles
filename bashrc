#!/bin/bash

## Use custom terminal prompt
yellow=$(tty -s && tput setaf 3)
white=$(tty -s && tput setaf 7)
black=$(tty -s && tput setaf 0)
bold=$(tty -s && tput bold)
reset=$(tty -s && tput sgr0)

function parse_git_branch {
   git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
#export PS1="\[$bold$yellow\]\u@\h\[$reset\]: \[$bold$white\]\w\[$reset\]\$(parse_git_branch)> "
export PS1="\[$bold$yellow\]\u@\h\[$reset\]: \[$bold$white\]\w\[$reset\]> "

## Export commands to history as they are executed (allows shared history between screen sessions)
#export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

## Compare version numbers
## source: https://stackoverflow.com/questions/4023830/how-to-compare-two-strings-in-dot-separated-version-format-in-bash
## question author: https://askubuntu.com/users/235/jorge-castro
## answer author: https://stackoverflow.com/users/26428/dennis-williamson
vercomp () {
    if [[ $1 == $2 ]]; then
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
if [[ $FQDN = *"summit.olcf.ornl.gov" ]]; then
    export HOST_SHORT="summit"
else
    export HOST_SHORT=$(echo ${HOSTNAME%%.*} | sed 's/\(-[a-zA-Z0-9]*\)\?[0-9]*$//')
fi

## Get computing facility name (e.g. NERSC, OLCF, ALCF, NCSA)
if [[ $FQDN = *"ornl.gov" ]]; then
    export FACILITY="OLCF"
elif [[ $FQDN = *"nersc.gov" ]]; then
    export FACILITY="NERSC"
elif [[ $FQDN = *"anl.gov" ]]; then
    export FACILITY="ALCF"
elif [[ $FQDN = *"illinois.edu" ]]; then
    export FACILITY="NCSA"
elif [[ $FQDN = *"tennessee.edu" ]]; then
    export FACILITY="NICS"
elif [[ $FQDN = "summitdev"* ]]; then
    export FACILITY="OLCF"
else
    export FACILITY="local"
fi

## Set default project ID
if [ $FACILITY == "OLCF" ]; then
    export PROJID="csc198"
    export PROJ_USERS=$(getent group $PROJID | sed 's/^.*://')
elif [ $FACILITY == "NERSC" ]; then
    export PROJID="chimera"
    export PROJ_USERS=$(getent group $PROJID | sed 's/^.*://')
elif [ $FACILITY == "ALCF" ]; then
    export PROJID=""
    export PROJ_USERS=""
elif [ $FACILITY == "NCSA" ]; then
    export PROJID="banp"
    export PROJ_USERS=$(getent group PRAC_$PROJID | sed 's/^.*://')
elif [ $FACILITY == "NICS" ]; then
    export PROJID="UT-MEZZ-AACE"
    export PROJ_USERS=""
else
    export PROJID=""
    export PROJ_USERS=""
fi

## Load custom aliases
if [ -f $HOME/.aliases.$HOST_SHORT ]; then
    source $HOME/.aliases.$HOST_SHORT
elif [ -f $HOME/.aliases ]; then
    source $HOME/.aliases
fi

## Check the window size after each command and, if necessary, update the values of LINES and COLUMNS.
shopt -s checkwinsize

## Do not add space after tab-complete of directory (only in versions of bash >= 4.2.29)
bashver=$(echo ${BASH_VERSINFO[@]:0:3} | tr ' ' '.')
vertest=$(vercomp $bashver 4.2.29)
vertestresult=$?
if [ $vertestresult -lt 2 ]; then
    shopt -s direxpand
fi
unset bashver vertest vertestresult

## Ignore duplicate history entries
export HISTCONTROL=ignoredups

## Limit to number of commands saved in history
export HISTFILESIZE=1000000
export HISTSIZE=1000000

## Default flags for less
export LESS=eFR

## Create lower-case PE_ENV (for use in modules)
if [ ! -z ${PE_ENV+x} ]; then
    export LC_PE_ENV=$(echo ${PE_ENV} | tr A-Z a-z)
fi

## Number of processors on this node
if [ -f /proc/cpuinfo ]; then
    export NPROC=$(grep "^core id" /proc/cpuinfo | sort -u | wc -l)
    export NPROCS=$(grep "^core id" /proc/cpuinfo | sort -u | wc -l)
fi

## Set facility/machine specific environment variables
if [ $FACILITY == "OLCF" ]; then
    ## Scratch directory environment variables for Summit/SummitDev are not yet created by default
    if [ $HOST_SHORT == "summitdev" ]; then
        export MEMBERWORK=/lustre/atlas/scratch/$USER
        export PROJWORK=/lustre/atlas/proj-shared
        export WORLDWORK=/lustre/atlas/world-shared
    elif [ $HOST_SHORT == "summit" ]; then
        export MEMBERWORK=/gpfs/alpinetds/scratch/$USER
        export PROJWORK=/gpfs/alpinetds/proj-shared
        export WORLDWORK=/gpfs/alpinetds/world-shared
    fi
    export WORKDIR=$MEMBERWORK/$PROJID
    export PROJHOME=/ccs/proj/$PROJID
    export PROJWORKDIR=$PROJWORK/$PROJID/$USER
    export HPSS_PROJDIR=/proj/$PROJID
elif [ $FACILITY == "NERSC" ]; then
    export WORKDIR=$CSCRATCH
    export PROJHOME=/project/projectdirs/$PROJID
    export PROJWORKDIR=$WORKDIR
    export HPSS_PROJDIR=/home/projects/$PROJID
    if [ $NERSC_HOST == "cori" ]; then
        module swap PrgEnv-$LC_PE_ENV PrgEnv-intel
        module swap craype-$CRAY_CPU_TARGET craype-mic-knl
    fi
    module unload darshan
elif [ $FACILITY == "NCSA" ]; then
    export WORKDIR=$SCRATCH
    export PROJHOME=/projects/sciteam/$PROJID
    export PROJWORKDIR=$WORKDIR
    export HPSS_PROJDIR=/projects/sciteam/$PROJID
elif [ $FACILITY == "local" ]; then
    export WORKDIR=$HOME
    export PROJHOME=$HOME
    export PROJWORKDIR=$WORKDIR
    export HPSS_PROJDIR=$PROJHOME

    ## Mac OS X
    if [ "$(uname)" == "Darwin" ]; then
        export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib/gcc/7:$LD_LIBRARY_PATH
        export GS_FONTPATH=$GS_FONTPATH:~/Library/Fonts

        ## Use GNU utils when available
        export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
        export MANPATH=/usr/local/opt/coreutils/libexec/gnuman:$MANPATH

        ## Add VisIt bin directory to PATH
        export PATH=/Applications/VisIt.app/Contents/Resources/bin:$PATH

        ## Add PGI to PATH
        export PGI=/opt/pgi
        export LM_LICENSE_FILE=$PGI/license.dat
        export PATH=$PGI/osx86-64/17.10/bin:$PATH

        ## Add PGI MPICH to PATH
        export PATH=$PGI/osx86-64/2017/mpi/mpich/bin:$PATH

        ## Compiler variables
        export CC=gcc-7
        export CXX=g++-7
        export CPP=cpp-7
        export CXXCPP=cpp-7
        export FC=gfortran-7

        ## Homebrew compilers
        export HOMEBREW_CC=gcc-7
        export HOMEBREW_CXX=g++-7
        export HOMEBREW_CPP=cpp-7
        export HOMEBREW_CXXCPP=cpp-7
        export HOMEBREW_FC=gfortran-7
        export HOMEBREW_VERBOSE=1

        ## HDF5
        export HDF5_DIR=/usr/local/Cellar/hdf5/1.10.0-patch1
        export HDF5_ROOT=$HDF5_DIR
        export HDF5_INCLUDE_DIRS=$HDF5_DIR/include
        export HDF5_INCLUDE_OPTS=$HDF5_INCLUDE_DIRS

        ## Pardiso
        export PARDISO_DIR=/usr/local/pardiso
     fi
fi

## Add local directories to environment
export PATH=$HOME/bin:$PATH
export MANPATH=$HOME/man:$MANPATH
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH

## Set global environment variables (same on all machines)
export CHIMERA=$HOME/chimera/trunk/Chimera
export DCHIMERA=$HOME/chimera/tags/D-production
export RADHYD=$HOME/chimera/trunk/RadHyd
export TRACER_READER=$HOME/chimera/trunk/Tools/tracer_reader
export INITIAL_MODELS=$HOME/chimera/trunk/Initial_Models
export SERIES_D=$HOME/chimera/trunk/Initial_Models/Series-D
export XNET=$HOME/xnet/trunk
export CHIMERA_EXE=$WORKDIR/chimera_execute
export XNET_EXE=$WORKDIR/xnet_execute
export TRACER_EXE=$WORDIR/tracer_reader
export MODEL_GENERATOR=$CHIMERA/Tools/Model_Generator

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

export BOXLIB_ROOT=$HOME/BoxLib-Codes
export BOXLIB_DIR=$BOXLIB_ROOT/BoxLib
export BOXLIB_HOME=$BOXLIB_ROOT/BoxLib
#export BOXLIB_USE_MPI_WRAPPERS=1

export FLASH_DIR=$PROJWORKDIR/FLASHOR
export XNET_FLASH=$FLASH_DIR/source/physics/sourceTerms/Burn/BurnMain/nuclearBurn/XNet

export MAGMA_DIR=$HOME/magma-2.3.0

export HYPRE_PATH=$HOME/hypre

export HELMHOLTZ_PATH=$HOME/helmholtz

export MESA_DIR=$HOME/mesa
export MESASDK_ROOT=$HOME/mesasdk
export PGPLOT_DIR=$HOME/mesasdk/pgplot
export MESA_CACHES_DIR=$WORKDIR/mesa_execute/data

## Do any extra local initialization
if [ -f $HOME/.bashrc.local ]; then
    source $HOME/.bashrc.local
fi

## Set appropriate colors
use_color=false
safe_term=${TERM//[^[:alnum:]]/?}
match_lhs=""
[[ -f ~/.dir_colors ]] && match_lhs="${match_lhs}$(<~/.dir_colors)"
[[ -f /etc/DIR_COLORS ]] && match_lhs="${match_lhs}$(</etc/DIR_COLORS)"
[[ -z ${match_lhs} ]] \
 && type -P dircolors >/dev/null \
 && match_lhs=$(dircolors --print-database)
[[ $'\n'${match_lhs} == *$'\n'"TERM "${safe_term}* ]] && use_color=true
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
