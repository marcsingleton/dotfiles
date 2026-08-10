#!/bin/bash

# Interweave FASTA pair with record annotating pairwise identities with |

# | is placed where non-gap symbols match
# The following metadata is reported
#   len: full length of seq
#   ngap: number of gaps in seq
#   naln: number of aligned positions (excluding gap/gap pairs)
#   nident: number of identities at aligned positions

set -e

print_usage() {
  printf "usage: %s [-w <width>] [<file>]\n" "${0##*/}" > /dev/stderr
}

write_fasta_record() {
  local header="$1"
  local seq="$2"
  local width="$3"

  printf ">%s\n" "$header"
  for ((i = 0; i < ${#seq}; i += $width)); do
    printf "%s\n" "${seq:$i:$width}"
  done
}

is_gap() {
  local sym=$1

  if [ "$sym" = "-" -o "$sym" = "." ]; then
    return 0
  else
    return 1
  fi
}

# Default args
width=80

# Parse args
while getopts "w:h" opt; do
  case $opt in
    w)
      width="$OPTARG"
      ;;
    h | *)
      print_usage
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1)) # Shift to get the file argument

# Validate args
if [ $# -eq 0 ]; then
  input_file="/dev/stdin" # Read from STDIN if no file is provided
elif [ $# -eq 1 ]; then
  input_file="$1"
else
  printf "%s: More than one input file provided.\n" "${0##*/}" > /dev/stderr
  exit 1
fi

# Awk FASTA parsing command with the specified output delimiter
SEP=$'\31' # Use unit separator control character to avoid collisions
program='
BEGIN {RS=">"; FS="\n"; ORS="\n"; OFS=""}
NR==1 {next}
{$1=$1 SEP; print}
'

# Parse records
exec 3< <(awk -v SEP="$SEP" "$program" "$input_file") # Open on fd 3
IFS="$SEP" read -u 3 header1 seq1
IFS="$SEP" read -u 3 header2 seq2
exec 3>&- # Close fd 3

# Make identity string and calculate metadata
if [ ${#seq1} -gt ${#seq2} ]; then
  maxlen=${#seq1}
else
  maxlen=${#seq2}
fi
seq=""
ngap1=0
ngap2=0
naln=0
nident=0
for ((i = 0; i < $maxlen; i++)); do
  sym1=${seq1:$i:1}
  sym2=${seq2:$i:1}
  # Make string
  if [ "$sym1" = "$sym2" ] && ! is_gap "$sym1"; then
    seq+='|'
  else
    seq+=" "
  fi

  # Calculate metadata
  if [ "$sym1" != "" -a "$sym2" != "" ] &&
       ! is_gap "$sym1" &&
       ! is_gap "$sym2"; then 
    ((naln++)) # "" checks prevent empty syms when lengths are mismatched
    if [ "$sym1" = "$sym2" ]; then
      ((nident++))
    fi
  fi
  if is_gap "$sym1"; then
    ((ngap1++))
  fi
  if is_gap "$sym2"; then
    ((ngap2++))
  fi
done
header="ident_data len1=${#seq1} len2=${#seq2} ngap1=$ngap1 ngap2=$ngap2 naln=$naln nident=$nident"

# Write outputs
write_fasta_record "$header1" "$seq1" $width
write_fasta_record "$header" "$seq" $width
write_fasta_record "$header2" "$seq2" $width
