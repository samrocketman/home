#!/bin/bash
# Created by Sam Gleske
# Created Wed Jan  5 20:41:52 EST 2022
# MIT License - https://github.com/samrocketman/home

# DESCRIPTION
# Finds launchers and creates the same launcher with "Low Priority" in the
# name.  This will customize the launcher so that it launchers processes with
# lower priority (nice value 10 by default) and restrict the process with CPU
# affinity to one physical core (but all threads on the core; typically 2
# threads).
#
# Alternate can print CPU affinity mask for taskset command and exit.

# USAGE
#     Create a low priority launcher for multiple applications.  Add more
#     applications as arguments to create multiple launchers.
#         create-low-priority-launcher.sh Firefox Discord Slack "OBS Studio"
#
#     Print CPU affinity 1 physical CPU core.
#         create-low-priority-launcher.sh -p
#
#     Print CPU affinity for all other physical cores other than the 1 core
#     printed.
#         create-low-priority-launcher.sh -p -v

# DEVELOPMENT ENVIRONMMENT
# Ubuntu 18.04.6 LTS
# Linux 5.4.0-92-generic x86_64
# GNU bash, version 4.4.20(1)-release (x86_64-pc-linux-gnu)
# cat (GNU coreutils) 8.28
# sed (GNU sed) 4.4
# GNU Awk 4.1.4, API: 1.1 (GNU MPFR 4.0.1, GNU MP 6.1.2)
# tac (GNU coreutils) 8.28
# tr (GNU coreutils) 8.28
# bc 1.07.1
# find (GNU findutils) 4.7.0-git
# xargs (GNU findutils) 4.7.0-git
# cp (GNU coreutils) 8.28


if [ $# -eq 0 ]; then
  echo 'Must provide the launcher name.' >&2
  echo 'Multiple launcher names can be provided as arguments' >&2
  exit 1
fi

# Reads /proc/cpuinfo and creates a binary mask for calculating CPU affinity.
function cpu_cores_to_binary() {
  cat /proc/cpuinfo | \
  sed 's/[\t ]//g' | \
  awk -F: '$1 == "processor" {printf $0":"}; $1 == "coreid" {print}' | \
  tac | \
  awk -F: 'BEGIN { id="" }; id == "" {id=$4}; $4 == id { printf "1"; next }; { printf "0"};END { printf "\n" }'
}

# Prints a hex mask for CPU affinity; meant for the taskset command
function get_default_cpu_affinity() {
  if [ "${invert_affinity}" = true ]; then
    echo "obase=16; ibase=2; $(cpu_cores_to_binary | tr '10' '01' )" | bc
  else
    echo "obase=16; ibase=2; $(cpu_cores_to_binary)" | bc
  fi
}

function printhelp() {
cat >&2 <<EOF
SYNOPSIS
  ${0##*/} [-n NICENESS] [-t MASK] [-v] LAUNCHER [LAUNCHER...]
  ${0##*/} -p [-v]

DESCRIPTION
  Finds launchers and creates the same launcher with "Low Priority" in the
  name.  This will customize the launcher so that it launches processes with
  lower process priority (nice value 10 by default) and restrict the process
  with CPU affinity to one physical core (but all threads on the core;
  typically 2 threads).

ARGUMENTS
  LAUNCHER
    The launcher name to find *.desktop shortcuts to create a duplicate
    launcher which launches the same program but with low process priority and
    limit CPUs used by the program.  This argument is required unless
    --print-affinity option is passed.

OPTIONS:
  -n NICENESS or --nice-value NICENESS
      Customize how nice the launcher should be.  Provide a value between 1 and
      19 to set lower priority niceness.
      Default: 10
  -t MASK or --taskset-mask MASK
      A hexidecimal mask provided to taskset for CPU affinity.
      Default: Mask is automatically detected to 1 core (2 threads)
  -v or --invert-taskset-default
      Inverts the --taskset-mask default so that the default mask is N-1 CPU
      cores insted of 1 core.  Also called binary complement.
      Default: Not inverted.
  -p or --print-affinity
      Instead of configuring launchers the default taskset mask is printed.
      The mask used by taskset will set the CPU affinity which is why this
      option is named print affinity.  No launchers will be configured and the
      program will exit when printing.

EXAMPLES
  Create a low priority launcher for multiple applications.  Add more
  applications as arguments to create multiple launchers.

      ${0##*/} Firefox Discord Slack 'OBS Studio'

  Print CPU affinity 1 physical CPU core.

      ${0##*/} -p

  Print CPU affinity for all other physical cores other than the 1 core
  printed.

      ${0##*/} -p -v
EOF
}

launchers=()
niceargs=""
invert_affinity=false
print_affinity=false
while [ $# -gt 0 ]; do
  case "$1" in
    -n|--nice-value)
      niceargs="-n $2"
      shift
      shift
      ;;
    -t|--taskset-mask)
      tasksetargs="$2"
      shift
      shift
      ;;
    -v|--invert-taskset-default)
      invert_affinity=true
      shift
      ;;
    -p|--print-affinity)
      print_affinity=true
      shift
      ;;
    -h|--help)
      printhelp
      exit 1
      ;;
    *)
      launchers+=( "$1" )
      shift
      ;;
  esac
done

if [ -z "${tasksetargs:-}" ]; then
  tasksetargs="$(get_default_cpu_affinity)"
fi

if [ "${print_affinity}" = true ]; then
  echo "${tasksetargs}"
  exit
fi

launcher_dirs=( /usr/share/applications )
if [ -d /var/lib/snapd/desktop/applications ]; then
  launcher_dirs+=( /var/lib/snapd/desktop/applications )
fi
created=false
for launchertext in "${launchers[@]}"; do
  low_priority_cmd="taskset ${tasksetargs} nice"
  if [ -n "${niceargs:-}" ]; then
    low_priority_cmd+=" ${niceargs}"
  fi
  find "${launcher_dirs[@]}" -maxdepth 1 -type f -name '*.desktop' | \
    xargs -- grep -l -- "${launchertext}" | while read launcher; do
      destination="${HOME}/.local/share/applications/nice-${launcher##*/}"
      cp -f "${launcher}" "${destination}"
      sed -i \
        -e 's/^Name=/Name=Low Priority /' \
        -e "s/^Exec=/Exec=${low_priority_cmd} /" \
        -- "${destination}"
      echo "Created: ${destination}" >&2
      created=true
    done
done
if [ "${created}" = true ] ; then
  echo 'You can edit the files to customize or run this command again.' >&2
else
  echo 'No launchers found; nothing created.' >&2
fi
