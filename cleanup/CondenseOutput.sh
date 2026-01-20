#!/bin/bash

# ===============================
# Loop parameters
# ===============================
HADRONIC_MODELS=(EPOS_LHC-R QGSJET-III.01 Sibyll-2.3e)
ENERGY_BLOCKS=(16.0_16.5 16.5_17.0 17.0_17.5 17.5_18.0 18.0_18.5 18.5_19.0 19.0_19.5 19.5_20.0 20.0_20.5)
PRIMARIES=(proton helium oxygen iron)
ATMOSPHERES=(01 03 08 09)


# ===============================
# Directory definitions
# ===============================
SCRIPTLOC="$( cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P )"  # Where this script is
PARENT_DATALOC=/home/bflaggs/Documents/Research/git_repos/CorsikaParser/TestDiracFiles/data  # Define the parent directory holding all the parsed CORSIKA information
PARENT_OUTLOC=/home/bflaggs/Documents/Research/git_repos/CorsikaParser/TestDiracFiles/outputs  # Define the parent directory to save the output, i.e. the condensed text files

HEADERFILE="$SCRIPTLOC/CorsikaParser_OutputHeader.txt"  # Location of the header file for the condensed output files

echo "========================================================================="
echo "Starting to condense CORSIKA parsed output files into single text files for each model/energyblock/primary/atmosphere"
echo "Data locations: $PARENT_DATALOC/<model>/<energyblock>/<primary>/"
echo "Output locations: $PARENT_OUTLOC/<model>/<energyblock>/" 
echo "Including header from $HEADERFILE"
echo "========================================================================="

cd $PARENT_DATALOC

for MODEL in "${HADRONIC_MODELS[@]}"
do
  for ENERGY in "${ENERGY_BLOCKS[@]}"
  do
    for PRIMARY in "${PRIMARIES[@]}"
    do
      for ATM in "${ATMOSPHERES[@]}"
      do
        # Define locations of data and output
        DATALOC="$PARENT_DATALOC/$MODEL/$ENERGY/$PRIMARY"
        OUTLOC="$PARENT_OUTLOC/$MODEL/$ENERGY"

        if [[ ! -d $DATALOC ]]; then
          echo "Data directory $DATALOC does not exist, skipping..."
          continue
        fi

        if [[ ! -d $OUTLOC ]]; then
          echo "Making output directory: $OUTLOC"
          mkdir -p $OUTLOC
        fi

        cd $DATALOC

        OUTPUTFILE="$OUTLOC/${PRIMARY}-${ENERGY}-atm${ATM}.txt"

        if [[ -f $OUTPUTFILE ]]; then
          echo "Output file $OUTPUTFILE already exists, skipping to avoid overwriting..."
          continue
        fi

        echo "Creating condensed output file: $OUTPUTFILE"
        touch $OUTPUTFILE

        cat $HEADERFILE >> $OUTPUTFILE

        NUMFILES=$(ls -l DAT${ATM}* 2>/dev/null | wc -l)

        echo "Appending data for atmosphere $ATM, total files to process: $NUMFILES"
        cat DAT${ATM}* >> $OUTPUTFILE
      done
    done
  done
done

echo "========================================================================="
echo "Condensing complete. Now can run your analysis scripts on the condensed files in $PARENT_OUTLOC"
echo "Have fun :)"
echo "========================================================================="

