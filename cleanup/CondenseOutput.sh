#!/bin/bash

1. Start in the directory `/pbs/home/b/bflaggs/SimulationWork`
2. `touch helium-18.0_18.5-atm03.txt`
3. `cat Parsed_Sims_Header.txt >> helium-18.0_18.5-atm03.txt`
4. `mv helium-18.0_18.5-atm0*.txt ./ParsedData/SIB23c/18.0_18.5/.`
5. `cd ParsedData/SIB23c/18.0_18.5`
6. `mv helium-18.0_18.5-atm0*.txt ./helium/.`
7. `cd helium`
8. Can check the total number of files for a specific atmosphere (here atm03) using command `ls -ltr DAT03*.txt | wc -l`. Output should be about 1250 per atmosphere.
9. `cat DAT03* >> helium-18.0_18.5-atm03.txt`
10. `mv helium-18.0_18.5-atm0*.txt ./../.`
11. Then can run all analysis scripts in directory `/pbs/home/b/bflaggs/SimulationWork/MultivariateAnalysis` while reading in the .txt files desribed here.


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
DATALOC=PATH_TO_DATA_DIRECTORY  # Define the directory holding all the parsed CORSIKA information
OUTLOC=PATH_TO_OUTPUT_DIRECTORY  # Define the directory to save the output, condensed text files

HEADERFILE="$SCRIPTLOC/CorsikaParser_OutputHeader.txt"  # Location of the header file for the condensed output files

cd $DATALOC

for MODEL in "${HADRONIC_MODELS[@]}"
do
  for ENERGY in "${ENERGY_BLOCKS[@]}"
  do
    for PRIMARY in "${PRIMARIES[@]}"
    do
      for ATM in "${ATMOSPHERES[@]}"
      do
        OUTFILELOC="$OUTLOC/$MODEL"

        if [[ ! -d $OUTFILELOC ]]; then
          mkdir -p $OUTFILELOC
        fi

        OUTPUTFILE="$OUTFILELOC/${PRIMARY}-${ENERGY}-atm${ATM}.txt"
        touch $OUTPUTFILE
        cat HEADERFILE >> $OUTPUTFILE
        
