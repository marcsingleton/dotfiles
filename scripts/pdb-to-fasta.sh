#!/bin/bash

# Parse sequences from PDB files into FASTA output

# Uses the SEQRES records as the sequence source

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
printf "usage: ${0##*/} [-p <chain_id_prefix>] [-w <width>] [file]\n"
}

print_residues() {
for residue in ${residues[@]}; do
    # Map residue to sym
    sym="${RESIDUE_MAP[$residue]}"
    if [ -z "$sym" ]; then
        if [ $ERROR_ON_UNKNOWN -eq 1 ]; then
            printf "\n${0##*/}: unknown residue $residue in chain $chain_id\n" > /dev/stderr
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
    printf "$sym"
    if [ $len -ge $WIDTH ]; then
        printf "\n"
        len=0
    fi
done
}

# Default options
ID_PREFIX="chain_"
WIDTH=80
ERROR_ON_UNKNOWN=1

# Parse arguments
while getopts "p:w:eh" opt; do
  case $opt in
    p)
      ID_PREFIX="$OPTARG"
      ;;
    w)
      WIDTH="$OPTARG"
      ;;
    e)
      ERROR_ON_UNKNOWN=0
      ;;
    h|*)
      print_usage
      exit 1
      ;;
  esac
done

shift $(($OPTIND - 1))

# Check if a file argument is provided
if [ $# -eq 1 ]; then
  input_file="$1"
else
  input_file="/dev/stdin"  # Read from STDIN if no file is provided
fi

exec 3< "$input_file"  # Opens input on file descriptor 3

# Read to first SEQRES record
while read -u 3 line; do
    record_type="${line:0:6}"
    if [ "$record_type" = "SEQRES" ]; then
        break
   fi
done
chain_id="${line:11:1}"
residues="${line:19}"

# Create header
printf ">${ID_PREFIX}${chain_id}\n"
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
        printf "\n>${ID_PREFIX}${chain_id}\n"
        current_chain_id="$chain_id"
        len=0
    fi
    
    residues=($residues)
    print_residues
done
