#!/bin/bash

# Parse sequences from PDB files into FASTA output

# Uses the SEQRES records as the sequence source

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
  printf "usage: %s [-p <chain_id_prefix>] [-w <width>] [file]\n" "${0##*/}" > /dev/stderr
}

print_residues() {
  for residue in "${residues[@]}"; do
    # Map residue to sym
    sym="${RESIDUE_MAP[$residue]}"
    if [ -z "$sym" ]; then
      if [ $error_on_unknown -eq 1 ]; then
        printf "\n%s: Unknown residue \"%s\" in chain %s.\n" "${0##*/}" "$residue" "$chain_id" > /dev/stderr
        exit 1
      fi

      if [ ${#residue} -ge 3 ]; then
        sym="$UNKNOWN_AA"
      else
        sym="$UNKNOWN_NT"
      fi
    fi
    len=$((len + 1))

    # Format
    printf "%s" "$sym"
    if [ $len -ge $width ]; then
      printf "\n"
      len=0
    fi
  done
}

# Default args
id_prefix="chain_"
width=80
error_on_unknown=1

# Parse args
while getopts "p:w:eh" opt; do
  case $opt in
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
residues="${line:19}"

# Create header
printf ">%s\n" "${id_prefix}${chain_id}"
current_chain_id="$chain_id"
len=0

residues=($residues)
print_residues

# Iterate over lines
while read -u 3 line; do
  record_type="${line:0:6}"
  chain_id="${line:11:1}"
  residues="${line:19}"

  if [ "$record_type" != "SEQRES" ]; then
    printf "\n"
    exit
  fi

  if [ "$current_chain_id" != "$chain_id" ]; then
    printf "\n>%s\n" "${id_prefix}${chain_id}"
    current_chain_id="$chain_id"
    len=0
  fi

  residues=($residues)
  print_residues
done
