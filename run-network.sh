##
# Author: Nikolaus Mayer
##

#!/usr/bin/env bash

## Fail if any command fails (use "|| true" if a command is ok to fail)
set -e
## Treat unset variables as error
set -u

## Exit with error code
fun__die () {
  exit `false`;
}

## Print usage help
fun__print_usage () {
  printf "###################################################################\n";
  printf "#                                                                 #\n";
  printf "###################################################################\n";
  printf "\n";
  printf "Usage: ./run-network.sh -n network [-g gpu] [-v|vv] first-input second-input output\n";
  printf "\n";
  printf "where 'first-input' and 'second-input' are either both images (in which\n";
  printf "case 'output' is interpreted as output file) or both files of newline-\n";
  printf "separated filepaths (in which case the output argument must be a file\n";
  printf "of newline-separated output filenames). All files must have the exact\n";
  printf "same number of lines (one output per input pair).\n";
  printf "For disparity estimation, the first/second inputs are the left/right\n";
  printf "camera views. The estimated disparity maps are valid for the first (left)\n";
  printf "camera. For optical flow estimation, the estimated flow maps the first\n";
  printf "input to the second input (i.e. 'first'==t, 'second'==t+1).\n";
  printf "The input files must be within the current directory. All input and\n";
  printf "output filenames will be treated as relative to this directory.\n";
  printf "\n";
  printf "The 'gpu' argument is the numeric index of the GPU you want to use.\n";
  printf "This only makes sense on a multi-GPU system.\n";
  printf "\n";
  printf "By default, only errors are printed. Single verbosity (-v) prints\n";
  printf "debug outputs, and double verbosity (-vv) also prints whatever the\n";
  printf "docker container prints to stdout\n";
  printf "\n";
  printf "Available 'network' values:\n";
  printf "  DispNet: Simple single-stream disparity net\n";
  printf "  DispNet-K: Simple single-stream disparity net (finetuned for KITTI)\n";
  printf "  DispNetCorr1D: Two-stream disparity net with explicit correlation\n";
  printf "  DispNetCorr1D-K: Two-stream disparity net with explicit correlation\n";
  printf "                   (finetuned for KITTI)\n";
  printf "  FlowNetS: Simple single-stream disparity net\n";
  printf "  FlowNetC: Optical flow net with explicit correlation\n";
  printf "  FlowNetS_smalldisp: Simple single-stream disparity net (optimized\n";
  printf "                      for small motions)\n";
}

## Parameters (some hardcoded, others user-settable)
GPU_IDX=0;
CONTAINER="dispflownet";
NETWORK="";
VERBOSITY=0;

## Verbosity-controlled "printf" wrapper for ERROR
fun__error_printf () {
  if test $VERBOSITY -ge 0; then
    printf "%s\n" "$@";
  fi
}
## Verbosity-controlled "printf" wrapper for DEBUG
fun__debug_printf () {
  if test $VERBOSITY -ge 1; then
    printf "%s\n" "$@";
  fi
}

## Parse arguments into parameters
while getopts g:n:vh OPTION; do
  case "${OPTION}" in
    g) GPU_IDX=$OPTARG;;
    n) NETWORK=$OPTARG;;
    v) VERBOSITY=`expr $VERBOSITY + 1`;;
    h) fun__print_usage; exit `:`;;
    [?]) fun__print_usage; fun__die;;
  esac
done
shift `expr $OPTIND - 1`;

## Isolate network inputs
FIRST_INPUT="";
SECOND_INPUT="";
OUTPUT="";
if test "$#" -ne 3; then
  fun__error_printf "! Missing input or output arguments";
  fun__die;
else
  FIRST_INPUT="$1";
  SECOND_INPUT="$2";
  OUTPUT="$3";
fi

## Check if input files exist
if test ! -f "${FIRST_INPUT}"; then
  fun__error_printf "First input '${FIRST_INPUT}' is unreadable or does not exist.";
  fun__die;
fi
if test ! -f "${SECOND_INPUT}"; then
  fun__error_printf "Second input '${SECOND_INPUT}' is unreadable or does not exist.";
  fun__die;
fi


## Check and use "-n" input argument
BASEDIR="/dispflownet/dispflownet-release/models";
WORKDIR="";
case "${NETWORK}" in
  DispNet)            WORKDIR="${BASEDIR}/DispNet";;
  DispNet-K)          WORKDIR="${BASEDIR}/DispNet-K";;
  DispNetCorr1D)      WORKDIR="${BASEDIR}/DispNetCorr1D";;
  DispNetCorr1D-K)    WORKDIR="${BASEDIR}/DispNetCorr1D-K";;
  FlowNetS)           WORKDIR="${BASEDIR}/FlowNetS";;
  FlowNetC)           WORKDIR="${BASEDIR}/FlowNetC";;
  FlowNetS_smalldisp) WORKDIR="${BASEDIR}/FlowNetS_smalldisp";;
  *) fun__error_printf "Unknown network: ${NETWORK} (run with -h to print available networks)";
     fun__die;;
esac

## (Debug output)
fun__debug_printf "Using GPU:       ${GPU_IDX}";
fun__debug_printf "Running network: ${NETWORK}";
fun__debug_printf "Working dir:     ${WORKDIR}";
fun__debug_printf "First input:     ${FIRST_INPUT}";
fun__debug_printf "Second input:    ${SECOND_INPUT}";
fun__debug_printf "Output:          ${OUTPUT}";

## Run docker container
#  - "--device" lines map a specified host GPU into the contained
#  - "-v" allows the container the read from/write to the current $PWD
#  - "-w" executes "cd" in the container (each network has a folder)
## Note: The ugly conditional only switches stdout on/off.
if test $VERBOSITY -ge 2; then
  nvidia-docker run \
    --rm \
    --volume "${PWD}:/input-output:rw" \
    --workdir "${WORKDIR}" \
    -it "$CONTAINER" python demo.py "${FIRST_INPUT}" "${SECOND_INPUT}" "${OUTPUT}" "${GPU_IDX}";
else
  nvidia-docker run \
    --rm \
    --volume "${PWD}:/input-output:rw" \
    --workdir "${WORKDIR}" \
    -it "$CONTAINER" python demo.py "${FIRST_INPUT}" "${SECOND_INPUT}" "${OUTPUT}" "${GPU_IDX}" \
    > /dev/null;
fi

## Bye!
fun__debug_printf "Done!";
exit `:`;

