#!/bin/bash

# Parse sequences from PDB files into FASTA output

# Can use SEQRES or ATOM records as the sequence source
# Insertion codes are ignored in ATOM records

set -e

# Check shell options
if [ -n "$BASH_VERSION" -a "${BASH_VERSINFO[0]}" -lt 4 ]; then
  printf "%s: Requires minimum Bash version 4 for associative arrays.\n" "${0##*/}" > /dev/stderr
  exit 1
elif [ -n "$ZSH_VERSION" ]; then
  setopt shwordsplit # Enables word splitting like bash
fi

# Constants
declare -A RESIDUE_MAP=(
  # (L-) AMINO ACIDS
  [ALA]=A [ARG]=R [ASN]=N [ASP]=D [CYS]=C
  [GLN]=Q [GLU]=E [GLY]=G [HIS]=H [ILE]=I
  [LEU]=L [LYS]=K [MET]=M [PHE]=F [PRO]=P
  [SER]=S [THR]=T [TRP]=W [TYR]=Y [VAL]=V
  [SEC]=U [PYL]=O
  [ASX]=B [GLX]=Z
  [UNK]=X
  # DEOXYRIBONUCLEOTIDES
  [DA]=A [DC]=C [DG]=G [DT]=T [DI]=I
)
UNKNOWN_AA=X
UNKNOWN_NT=N

print_usage() {
  printf "usage: %s [-m seqres|atom] <[-p <chain_id_prefix>] [-w <width>] [<file>]\n" "${0##*/}" > /dev/stderr
}

print_fasta_record() {
  local header="$1"
  local seq="$2"
  local width="$3"

  printf ">%s\n" "$header"
  for ((i = 0; i < ${#seq}; i += $width)); do
    printf "%s\n" "${seq:$i:$width}"
  done
}

map_res_names() {
  local res_names=($1) # Splits on spaces
  local seq=""

  for res_name in "${res_names[@]}"; do
    # Map res_name to sym
    sym="${RESIDUE_MAP[$res_name]}"
    if [ -z "$sym" ]; then
      if [ $error_on_unknown -eq 1 ]; then
        printf "\n%s: Unknown res_name \"%s\" in chain %s.\n" "${0##*/}" "$res_name" "$chain_id" > /dev/stderr
        exit 1
      fi

      if [ ${#res_name} -ge 3 ]; then
        sym="$UNKNOWN_AA"
      else
        sym="$UNKNOWN_NT"
      fi
    fi

    seq+="$sym"
  done

  printf "%s" "$seq"
}

from_seqres() {
  local input_file="$1"
  local id_prefix="$2"
  local width="$3"

  exec 3< "$input_file" # Opens input on file descriptor 3

  # Read to first SEQRES record
  while read -u 3 line; do
    record_type="${line:0:6}"
    if [ "$record_type" = "SEQRES" ]; then
      break
    fi
  done
  if [ "$record_type" != "SEQRES" ]; then
    exit 1
  fi
  chain_id="${line:11:1}"
  res_names="${line:19}"

  # Initialize record
  current_chain_id="$chain_id"
  header="${id_prefix}${chain_id}"
  seq="$(map_res_names "$res_names")"

  # Iterate over lines
  while read -u 3 line; do
    record_type="${line:0:6}"
    if [ "$record_type" != "SEQRES" ]; then
      break
    fi

    chain_id="${line:11:1}"
    res_names="${line:19}"

    if [ "$current_chain_id" != "$chain_id" ]; then
      print_fasta_record "$header" "$seq" "$width"
      current_chain_id="$chain_id"
      header="${id_prefix}${chain_id}"
      seq=""
    fi

    seq+="$(map_res_names "$res_names")"

  done

  print_fasta_record "$header" "$seq" "$width"

  exec 3<&- # Close fd
}

from_atom() {
  local input_file="$1"
  local id_prefix="$2"
  local width="$3"

  exec 3< "$input_file" # Opens input on file descriptor 3

  # Read to first ATOM record
  while read -u 3 line; do
    record_type="${line:0:6}"
    if [ "$record_type" = "ATOM  " ]; then
      break
    fi
  done
  if [ "$record_type" != "ATOM  " ]; then
    exit 1
  fi

  res_name="${line:17:3}"
  chain_id="${line:21:1}"
  res_seq="${line:22:4}"

  # Initialize record
  current_chain_id="$chain_id"
  current_res_seq="$res_seq"
  header="${id_prefix}${chain_id}"
  seq="$(map_res_names "$res_name")"

  # Iterate over lines
  while read -u 3 line; do
    record_type="${line:0:6}"

    if [ "$record_type" != "ATOM  " -a \
      "$record_type" != "HETATM" -a \
      "$record_type" != "TER   " -a \
      "$record_type" != "ANISOU" ]; then
      break
    fi
    if [ "$record_type" != "ATOM  " ]; then
      continue
    fi

    res_name="${line:17:3}"
    chain_id="${line:21:1}"
    res_seq="${line:22:4}"

    if [ "$current_chain_id" != "$chain_id" ]; then
      print_fasta_record "$header" "$seq" "$width"
      current_chain_id="$chain_id"
      current_res_seq=""
      header="${id_prefix}${chain_id}"
      seq=""
    fi

    if [ -z "$current_res_seq" -o "$current_res_seq" != "$res_seq" ]; then
      current_res_seq="$res_seq"
      seq+=$(map_res_names "$res_name")
    fi

  done

  print_fasta_record "$header" "$seq" "$width"

  exec 3<&- # Close fd
}

# Default args
mode="seqres"
id_prefix="chain_"
width=80
error_on_unknown=1

# Parse args
while getopts "m:p:w:eh" opt; do
  case $opt in
    m)
      mode="$OPTARG"
      ;;
    p)
      id_prefix="$OPTARG"
      ;;
    w)
      width="$OPTARG"
      ;;
    e)
      error_on_unknown=0
      ;;
    h | *)
      print_usage
      exit 1
      ;;
  esac
done
shift $(($OPTIND - 1)) # Shift to get the file argument

# Validate args
if [ $# -eq 1 ]; then
  input_file="$1"
else
  input_file="/dev/stdin" # Read from STDIN if no file is provided
fi
if [ "$mode" != "seqres" -a "$mode" != "atom" ]; then
  printf "%s: Mode is not seqres or atom.\n" "${0##*/}"
  exit 1
fi

case "$mode" in
  seqres)
    from_seqres "$input_file" "$id_prefix" "$width"
    ;;
  atom)
    from_atom "$input_file" "$id_prefix" "$width"
    ;;
esac
