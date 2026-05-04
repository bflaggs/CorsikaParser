#!/bin/bash
date

# ==============================
# Configuration parameters
# ==============================
SIMS_PER_ATM=1250  #How many showers per atmosphere for Auger

# Array of ATM_IDS values to loop over, 4 atmospheres for each model/primary/energyblock
ATM_IDS=(10000 30000 80000 90000)

# Array of PRIMARYNAME values to loop over
PRIMARYNAMES=(proton helium oxygen iron)

# ==================================
# Current generation hadronic models
# ==================================
# SIM_MODEL=EPOS_LHC-R
# SIM_MODEL=QGSJET-III.01
# SIM_MODEL=Sibyll-2.3e

# ==================================
# Previous generation hadronic models
# ==================================
SIM_MODEL=EPOS_LHC
# SIM_MODEL=QGSJET-II-04
# SIM_MODEL=Sibyll2.3d

# Statement to define ENERGYBLOCK values to loop over and header path to model data
# Previous generation models have different final energy bin and different header path than current generation models
if [[ $SIM_MODEL == "EPOS_LHC" || $SIM_MODEL == "QGSJET-II-04" || $SIM_MODEL == "Sibyll2.3d"]]; then
    ENERGYBLOCKS=(16.0_16.5 16.5_17.0 17.0_17.5 17.5_18.0 18.0_18.5 18.5_19.0 19.0_19.5 19.5_20.0 20.0_20.2)
    SIMSLOCHEADER="/auger/prod/d0005/corsika-77420_NPlib_FLUKAINFN"
else
    ENERGYBLOCKS=(16.0_16.5 16.5_17.0 17.0_17.5 17.5_18.0 18.0_18.5 18.5_19.0 19.0_19.5 19.5_20.0 20.0_20.5)
    SIMSLOCHEADER="/auger/prod/d0008/corsika-78010_Auger_lib_FLUKA"
fi

# ==============================
# Directory definitions
# ==============================
PARSERLOC="/cr/users/schroeder/testDirac/CorsikaParser"  #Where this script is
WORKDIR="/cr/data/schroeder/diracCorsikaProcessing"

# ==============================
# Function: Process Data in Background
# ==============================
process_shower() {
    local FILENAME=$1
    local NEWLOC=$2
    local OUTLOC=$3
    local EXE=$4
    local EXE2=$5

    echo "Untarring file: tar -xzvf $NEWLOC/${FILENAME}.tar.gz"
    if tar -xzvf $NEWLOC/${FILENAME}.tar.gz -C $NEWLOC; then
        echo "Removing unneeded tarball: rm $NEWLOC/${FILENAME}.tar.gz"
        rm $NEWLOC/${FILENAME}.tar.gz

        # Append filenames for debugging
        echo $NEWLOC/$FILENAME >> $NEWLOC/FileNames.log

        echo "Reading: $FILENAME"
        MUON_DATA=$($EXE $FILENAME --thinned)
        echo "Executing Corsika Block Parser: $MUON_DATA"
        
        ZENITH=$(echo $MUON_DATA | awk '{print $3}')
        XMAX_DATA=$($EXE2 ${FILENAME}.long --zen $ZENITH --removeFinal20gcm2)
        echo "Executing Corsika Longitudinal Parser: $XMAX_DATA"

        # Write output
        echo $MUON_DATA $XMAX_DATA > $OUTLOC/${FILENAME}.txt

        echo "Removing untarred files..."
        rm $NEWLOC/$FILENAME
        rm $NEWLOC/${FILENAME}.long
    else
        echo "ERROR: Failed to untar $FILENAME"
    fi
}

# Loop through atmospheric models, primaries, and energy blocks
for ATM_IDS in "${ATM_IDS[@]}"
do
  for PRIMARYNAME in "${PRIMARYNAMES[@]}"
  do
    for ENERGYBLOCK in "${ENERGYBLOCKS[@]}"
    do
      SIMSLOC=$SIMSLOCHEADER/$SIM_MODEL/$PRIMARYNAME/$ENERGYBLOCK/run01/  #Where corsika sims are
      TEMPLOC=$WORKDIR/TempWorkArea #Directory to do temporary work
      OUTLOC=$WORKDIR/CorsikaData/$SIM_MODEL/$ENERGYBLOCK/$PRIMARYNAME/  #Where to save corsika parsed data

      let "IDFirst = (0) * $SIMS_PER_ATM + $ATM_IDS"
      let "IDLast = (1) * $SIMS_PER_ATM + $ATM_IDS - 1"

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

      EXE=$PARSERLOC/corsikaReader
      EXE2=$PARSERLOC/ParseAndFitLongitudinalProfile_Auger.py

      echo Corsika Block Parser: $EXE
      echo Corsika Longitudinal Parser: $EXE2

      for ((iFILE=$IDFirst; iFILE<=$IDLast; iFILE++))
      do
        FILENAME=$(printf "DAT%0*d" 6 $iFILE)

        echo Copying from Dirac: $SIMSLOC${FILENAME}.tar.gz
        echo command: dget $SIMSLOC${FILENAME}.tar.gz $NEWLOC/
        dget $SIMSLOC${FILENAME}.tar.gz $NEWLOC/ >> $NEWLOC/dget_${FILENAME}.log 2>&1
        
        # Check if download was successful before processing
        if [ -f "$NEWLOC/${FILENAME}.tar.gz" ]; then
            # Run untarring and processing of file in the background (with &)
            process_shower "$FILENAME" "$NEWLOC" "$OUTLOC" "$EXE" "$EXE2" & 
        else
            echo "Download failed for $FILENAME"
        fi
      done

      # Wait for background processes to finish before moving to next energyblock/primary/atmosphere
      wait

    done  # End loop over energy blocks
  done    # End loop over primaries
done      # End loop over atmospheric models

date
echo DONE!