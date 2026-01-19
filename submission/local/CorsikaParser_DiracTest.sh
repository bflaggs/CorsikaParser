#!/bin/bash

# ==============================
# Configuration parameters
# ==============================
SIMS_PER_SUB=1  #How many showers per submission, for Auger 1250 showers per atmosphere
STARTID=10000
# STARTID=30000
# STARTID=80000
# STARTID=90000

#TOTAL_SUBS=1
#TOTAL_SUBS=25

SIM_MODEL=EPOS_LHC-R
# SIM_MODEL=QGSIII04  --> Needs update
# SIM_MODEL=Sibyll-2.3e

# ENERGYBLOCK=16.0_16.5
# ENERGYBLOCK=16.5_17.0
ENERGYBLOCK=17.0_17.5
# ENERGYBLOCK=17.5_18.0
# ENERGYBLOCK=18.0_18.5
# ENERGYBLOCK=18.5_19.0
# ENERGYBLOCK=19.0_19.5
# ENERGYBLOCK=19.5_20.0
# ENERGYBLOCK=20.0_20.5

PRIMARYNAME=proton
# PRIMARYNAME=helium
# PRIMARYNAME=oxygen
# PRIMARYNAME=iron

# ==============================
# Directory definitions
# ==============================
PARSERLOC="$( cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P )"  # Where this script is
WORKLOC=PATH_TO_WORK_DIRECTORY  # Define a working directory here

SIMSLOC=/auger/prod/d0008/corsika-78010_Auger_lib_FLUKA/$SIM_MODEL/$PRIMARYNAME/$ENERGYBLOCK/run01  # Where corsika sims are
TEMPLOC=$WORKLOC/test/TempWorkArea  # Directory to do temporary work
OUTLOC=$WORKLOC/test/CorsikaData/$SIM_MODEL/$ENERGYBLOCK/$PRIMARYNAME  # Where to save cosika parsed data


# Comment for now..., could be used for parallelization later
#for ((iRUN=0; iRUN<$TOTAL_SUBS; iRUN++))
#do

iRUN=0  # For now, only do one run

cd $PARSERLOC
echo PARSERLOC: $PARSERLOC


let "IDFirst = ($iRUN) * $SIMS_PER_SUB + $STARTID"
let "IDLast = ($iRUN + 1) * $SIMS_PER_SUB + $STARTID - 1"

NEWLOC=$TEMPLOC/RUN${SIM_MODEL}_${PRIMARYNAME}_${IDFirst}_${IDLast}

if [[ -d $NEWLOC ]]; then
  rm -r $NEWLOC
fi

mkdir -p $NEWLOC

if [[ ! -d $OUTLOC ]]; then
  mkdir -p $OUTLOC
fi

cd $NEWLOC
echo Work done in directory: $NEWLOC
echo Output saved in directory: $OUTLOC

# Load any needed environment variables here...

EXE=$PARSERLOC/scripts/corsikaReader
EXE2=$PARSERLOC/scripts/ParseAndFitLongitudinalProfile_Auger.py

echo Corsika Block Parser: $EXE
echo Corsika Longitudinal Parser: $EXE2

for ((iFILE=$IDFirst; iFILE<=$IDLast; iFILE++))
do

  FILENAME=$(printf "DAT%0*d" 6 $iFILE)

  echo Copying from Dirac: $SIMSLOC/${FILENAME}.tar.gz
  dget $SIMSLOC/${FILENAME}.tar.gz $NEWLOC/${FILENAME}.tar.gz >> $NEWLOC/dget_${FILENAME}.log 2>&1
  tar -xzvf $NEWLOC/${FILENAME}.tar.gz
  rm $NEWLOC/${FILENAME}.tar.gz

  # For debugging and tracking downloaded files
  echo $NEWLOC/$FILENAME > $NEWLOC/FileNames

  echo Reading: $FILENAME
  MUON_DATA=$($EXE $FILENAME --thinned)
  ZENITH=$(echo $MUON_DATA | awk '{print $3}')
  XMAX_DATA=$($EXE2 ${FILENAME}.long --zen $ZENITH --removeFinal20gcm2)

  echo $MUON_DATA $XMAX_DATA > $OUTLOC/${FILENAME}.txt

  rm $NEWLOC/$FILENAME
  rm $NEWLOC/${FILENAME}.long
done


# Command for ending loop over runs (iRUN)
#done

echo DONE!