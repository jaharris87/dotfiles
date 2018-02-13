## Use custom terminal prompt
yellow=$(tty -s && tput setaf 3)
white=$(tty -s && tput setaf 7)
black=$(tty -s && tput setaf 0)
bold=$(tty -s && tput bold)
reset=$(tty -s && tput sgr0)

export PS1="\[$bold$yellow\]\u@\h\[$reset\]: \[$bold$white\]\w\[$reset\]> "

## Export commands to history as they are executed (allows shared history between screen sessions)
#export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

## Ignore duplicate history entries
export HISTCONTROL=ignoredups

## Limit to number of commands saved in history
export HISTFILESIZE=1000000
export HISTSIZE=1000000

export USER=$(whoami)
export PROJID=csc198
export OLCF_HOST=$(echo $HOSTNAME | sed 's/\(-[a-zA-Z0-9]*\)\?[0-9]*$//')
if [ $OLCF_HOST == "login" ]; then
    export OLCF_HOST="summit"
elif [ $OLCF_HOST == "batch" ]; then
    export OLCF_HOST="summit"
fi

## Do not add space after tab-complete of directory
if [ $OLCF_HOST == "summit" -o $OLCF_HOST == "summitdev" ]; then
    shopt -s direxpand
fi

## Load PGI programming environment by default on titan
if [ $OLCF_HOST == "titan" ]; then
    if [ -n "$PE_ENV" ]; then
        export LC_PE_ENV=$(echo $PE_ENV | tr A-Z a-z)
        module swap PrgEnv-$LC_PE_ENV PrgEnv-pgi
    fi
    module load subversion
fi

## Load custom aliases
source $HOME/.aliases

## Scratch directory environment variables for Summit/SummitDev are not yet created by default
if [ $OLCF_HOST == "summitdev" ]; then
    export MEMBERWORK=/lustre/atlas/scratch/$USER
    export PROJWORK=/lustre/atlas/proj-shared
    export WORLDWORK=/lustre/atlas/world-shared
elif [ $OLCF_HOST == "summit" ]; then
    export MEMBERWORK=/gpfs/alpinetds/scratch/$USER
    export PROJWORK=/gpfs/alpinetds/proj-shared
    export WORLDWORK=/gpfs/alpinetds/world-shared
fi

## Add local directories to environment
export PATH=$HOME/bin:$PATH
export MANPATH=$HOME/man:$MANPATH
export LD_LIBRARY_PATH=$HOME/lib:$LD_LIBRARY_PATH

## Set machine=specific environment variables
export WORKDIR=$MEMBERWORK/$PROJID
export SCRATCH=$MEMBERWORK/$PROJID
export PROJHOME=/ccs/proj/$PROJID
export PROJWORKDIR=$PROJWORK/$PROJID
export PROJSCRATCH=$PROJWORK/$PROJID
export NPROC=$(grep "^core id" /proc/cpuinfo | sort -u | wc -l)

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

export FLASH_DIR=$PROJWORKDIR/$USER/FLASHOR
export XNET_FLASH=$FLASH_DIR/source/physics/sourceTerms/Burn/BurnMain/nuclearBurn/XNet

export MAGMA_DIR=$HOME/magma-2.3.0

export HYPRE_PATH=$HOME/hypre

export HELMHOLTZ_PATH=$HOME/helmholtz

export MESA_DIR=$HOME/mesa
export MESASDK_ROOT=$HOME/mesasdk
export PGPLOT_DIR=$HOME/mesasdk/pgplot

#export PARDISO_DIR=/usr/local/pardiso

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
