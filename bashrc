## Use custom terminal prompt
yellow=$(tty -s && tput setaf 3)
white=$(tty -s && tput setaf 7)
black=$(tty -s && tput setaf 0)
bold=$(tty -s && tput bold)
reset=$(tty -s && tput sgr0)

export PS1="\[$bold$yellow\]\u@\h\[$reset\]: \[$bold$white\]\w\[$reset\]> "

## Export commands to history as they are executed (allows shared history between screen sessions)
#export PROMPT_COMMAND="history -a; history -c; history -r; ${PROMPT_COMMAND}"

## Who am I?
export USER=$(whoami)

## Get full hostname, including domain (i.e. Fully Qualified Domain Name)
export FQDN=$(hostname -f)

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
fi

## Trim extras off HOSTNAME (e.g. -ext2, edison05, cori10)
if [[ $FQDN = *"summit.olcf.ornl.gov" ]]; then
    export HOST_SHORT="summit"
else
    export HOST_SHORT=$(echo $HOSTNAME | sed 's/\(-[a-zA-Z0-9]*\)\?[0-9]*$//')
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

## Do not add space after tab-complete of directory
shopt -s direxpand

## Ignore duplicate history entries
export HISTCONTROL=ignoredups

## Limit to number of commands saved in history
export HISTFILESIZE=1000000
export HISTSIZE=1000000

## Create lower-case PE_ENV (for use in modules)
if [ ! -z ${PE_ENV+x} ]; then
    export LC_PE_ENV=$(echo ${PE_ENV} | tr A-Z a-z)
fi

## Number of processors on this node
export NPROC=$(grep "^core id" /proc/cpuinfo | sort -u | wc -l)

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
