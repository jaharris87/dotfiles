#!/bin/bash


## If not running interactively, don't do anything
[[ $- == *i* ]] || return

## Use custom terminal prompt
yellow=$(tput setaf 3)
white=$(tput setaf 7)
black=$(tput setaf 0)
bold=$(tput bold)
reset=$(tput sgr0)

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
elif [[ $FQDN = *"ascent.olcf.ornl.gov" ]]; then
    export HOST_SHORT="ascent"
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
    if [ $HOST_SHORT == "ascent" ]; then
        export PROJID="gen109"
    else
        export PROJID="csc198"
    fi
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

## Enable extended globbing
shopt -s extglob

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

## Set default editor
export EDITOR=vim

## Useful flags for 'less' (including color support)
export LESS="--ignore-case --status-column --RAW-CONTROL-CHARS"
# Use colors for less, man, etc.
[[ -f ~/.LESS_TERMCAP ]] && . ~/.LESS_TERMCAP

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
if [ $HOST_SHORT == "ascent" ]; then
    export MEMBERWORK=/gpfs/wolf/scratch/$USER
    export PROJWORK=/gpfs/wolf/proj-shared
    export WORLDWORK=/gpfs/wolf/world-shared
    export WORKDIR=$MEMBERWORK/$PROJID
    export PROJHOME=/ccs/proj/$PROJID
    export PROJWORKDIR=$PROJWORK/$PROJID/$USER
    ## Load newer git (titan already does this in system-wide init)
    module load git
    ## Load newer subversion
    module load subversion
    ## Add manually built diffutils to paths
    export PATH=$HOME/sw/diffutils_$HOST_SHORT/bin:$PATH
    export MANPATH=$HOME/sw/diffutils_$HOST_SHORT/share/man:$MANPATH
    export INFOPATH=$HOME/sw/diffutils_$HOST_SHORT/share/info:$MANPATH
elif [ $FACILITY == "OLCF" ]; then
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
    if [ $HOST_SHORT == "titan" ]; then
        ## Load newer version of VIM that supports undofile
       module load vim
       ## Load newer subversion
       module load subversion
    fi
    if [ $HOST_SHORT == "summit" -o $HOST_SHORT == "summitdev" ]; then
       ## Load newer git (titan already does this in system-wide init)
       module load git
       ## Load newer subversion
       module load subversion
    fi
    ## Add manually built diffutils to paths
    export PATH=$HOME/sw/diffutils_$HOST_SHORT/bin:$PATH
    export MANPATH=$HOME/sw/diffutils_$HOST_SHORT/share/man:$MANPATH
    export INFOPATH=$HOME/sw/diffutils_$HOST_SHORT/share/info:$MANPATH
elif [ $FACILITY == "NERSC" ]; then
    export WORKDIR=$CSCRATCH
    export PROJHOME=/project/projectdirs/$PROJID
    export PROJWORKDIR=$WORKDIR
    export HPSS_PROJDIR=/home/projects/$PROJID
    ## KNL by default
    if [ $NERSC_HOST == "cori" ]; then
        module swap PrgEnv-$LC_PE_ENV PrgEnv-intel
        module swap craype-$CRAY_CPU_TARGET craype-mic-knl
        ## Load newer subversion
        module load subversion
    elif [ $NERSC_HOST == "edison" ]; then
        module swap PrgEnv-$LC_PE_ENV PrgEnv-intel
        ## Load newer subversion
        module load subversion
    fi
    ## Unlaod darhsan
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
        export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib/gcc/8:$LD_LIBRARY_PATH
        export GS_FONTPATH=$GS_FONTPATH:~/Library/Fonts

        ## Use GNU utils when available
        export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
        export MANPATH=/usr/local/opt/coreutils/libexec/gnuman:$MANPATH

        ## Add VisIt bin directory to PATH
        export PATH=/Applications/VisIt.app/Contents/Resources/bin:$PATH

        ## Add PGI to PATH
        export PGI=/opt/pgi
        export LM_LICENSE_FILE=$PGI/license.dat
        export PATH=$PGI/osx86-64/18.4/bin:$PATH

        ## Add PGI MPICH to PATH
        #export PATH=$PGI/osx86-64/2018/mpi/mpich/bin:$PATH

        ## Compiler variables
        export CC=gcc-8
        export CXX=g++-8
        export CPP=cpp-8
        export CXXCPP=cpp-8
        export FC=gfortran-8

        ## Homebrew compilers
        export HOMEBREW_CC=gcc-8
        export HOMEBREW_CXX=g++-8
        export HOMEBREW_CPP=cpp-8
        export HOMEBREW_CXXCPP=cpp-8
        export HOMEBREW_FC=gfortran-8
        export HOMEBREW_VERBOSE=1

        ## Open-MPI
        export OMPI_DIR=/usr/local/Cellar/open-mpi/3.1.2
        export OMPI_ROOT=$OMPI_DIR

        ## HDF5
        export HDF5_DIR=/usr/local/Cellar/hdf5/1.10.3
        export HDF5_ROOT=$HDF5_DIR
        export HDF5_INCLUDE_DIRS=$HDF5_DIR/include
        export HDF5_INCLUDE_OPTS=$HDF5_INCLUDE_DIRS

        ## Pardiso
        export PARDISO_DIR=/usr/local/pardiso
        export PARDISO_LIC_PATH=$PARDISO_DIR
        export PARDISOLICMESSAGE=1
     fi
fi

## Add local directories to environment
export PATH=$HOME/bin:$PATH
export MANPATH=$HOME/share/man:$MANPATH
export INFOPATH=$HOME/share/info:$MANPATH
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
export MODEL_GENERATOR=$INITIAL_MODELS/Model_Generator

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

export MAGMA_DIR=$HOME/magma
export MAGMA_ROOT=$MAGMA_DIR

export HYPRE_DIR=$HOME/hypre
export HYPRE_ROOT=$HYPRE_DIR

export HELMHOLTZ_PATH=$HOME/helmholtz

export MESA_DIR=$HOME/mesa
export MESASDK_ROOT=$HOME/mesasdk
export PGPLOT_DIR=$HOME/mesasdk/pgplot
export MESA_CACHES_DIR=$WORKDIR/mesa_execute/data

export HACKATHON=$MEMBERWORK/gen109/gpuhackathon

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
