#!/bin/bash

SIMS_PER_SUB=50  #How many showers per submission
TOTAL_SUBS=25  #Total number of submissions (25 * 50 = 1250 showers per atmosphere)

#STARTID=10000
#STARTID=30000
#STARTID=80000
STARTID=90000

#SIMS_PER_SUB=1  #For testing only
#TOTAL_SUBS=1  #For testing only

SIM_MODEL=SibyllStar

# ENERGYBLOCK=18.0_18.5
# ENERGYBLOCK=18.5_19.0
# ENERGYBLOCK=19.0_19.5
ENERGYBLOCK=19.5_20.0

#PRIMARYNAME=proton
#PRIMARYNAME=helium
#PRIMARYNAME=oxygen
PRIMARYNAME=iron

if [[ $1 != "" ]]; then
  echo "Overriding with STARTID = $1"
  STARTID=$1
fi

HERE="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"  #Where this script is
SIMSLOC=/pauger/Simulations/libraries/MCTask/corsika-77420_Auger_lib_FLUKAINFN_SibyllStar/$SIM_MODEL/$PRIMARYNAME/$ENERGYBLOCK/run01/  #Where corsika sims are
#ADSTLOC=/sps/pauger/users/bflaggs/Work/ShowerLibraryCreation/ProductionDatabase/adsts/$SIM_MODEL/$ENERGYBLOCK/$PRIMARYNAME/  #Where the ADSTs should go
TEMPLOC=$HERE/TempWorkArea #Directory to do temporary work
OUTLOC=/sps/pauger/users/bflaggs/Work/ShowerLibraryCreation/ParsedData/$SIM_MODEL/$ENERGYBLOCK/$PRIMARYNAME/  #Where to save cosika parsed data
#OUTLOC=$HERE/data
#APESOURCE=/sps/pauger/users/ghia/acoleman/Programs/ape/ape-trunk

SUBJUNK=" --account=pauger -L sps"

for ((iRUN=0; iRUN<$TOTAL_SUBS; iRUN++))
do

cd $HERE

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

echo "#!/usr/bin/env bash
#SBATCH --job-name=${PRIMARYNAME}_${IDFirst}_${IDLast}
#SBATCH --output=$NEWLOC/${PRIMARYNAME}_${IDFirst}_${IDLast}.out
#SBATCH --mem=2G
#SBATCH --time=2-00:00:00
#SBATCH --ntasks=1

SIMSLOC=$SIMSLOC
IDFirst=$IDFirst
IDLast=$IDLast
HERE=$NEWLOC

EXE=\$HERE/../../CorsikaParser/muonReader
EXE2=\$HERE/../../CorsikaParser/GetMuAndEM_ForLongFiles_SIBYLLSTAR_ONLY.py

cd \$HERE
echo Sourcing irods and python
module load irods
module load python

for ((iFILE=\$IDFirst; iFILE<=\$IDLast; iFILE++))
do

  FILENAME=\$(printf "DAT%0*d" 6 \$iFILE)

  echo Copying from irods: $SIMSLOC/\${FILENAME}.tar.gz
  iget $SIMSLOC/\${FILENAME}.tar.gz \$HERE/\${FILENAME}.tar.gz
  tar xvf \$HERE/\${FILENAME}.tar.gz
  rm \$HERE/\${FILENAME}.tar.gz

  # echo \$HERE/\$FILENAME > \$HERE/FileNames

  echo Reading: \$FILENAME
  MUON_DATA=\$(\$EXE \$FILENAME)
  ZENITH=\$(echo \$MUON_DATA | awk '{print \$3}')
  XMAX_DATA=\$(\$EXE2 \${FILENAME}.long --zen \$ZENITH)

  # echo \$MUON_DATA \$XMAX_DATA > \$HERE/\${FILENAME}.txt
  echo \$MUON_DATA \$XMAX_DATA > $OUTLOC/\${FILENAME}.txt

  rm \$HERE/\$FILENAME
  rm \$HERE/\${FILENAME}.long


done
" > $NEWLOC/Sub_${IDFirst}_${IDLast}.sh

sbatch $SUBJUNK  $NEWLOC/Sub_${IDFirst}_${IDLast}.sh

done
