#!/bin/bash

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
echo HERE: $HERE

eval `/cvmfs/icecube.opensciencegrid.org/py3-v4.1.0/setup.sh`

EXE=$HERE/../corsika-parser/muonReaderTHINNED
EXE2=$HERE/../corsika-parser/GetMuAndEM_ForLongFiles.py
INPUTDIR=$1
OUTPUT=$2

echo EXE: $EXE
echo INPUTDIR: $INPUTDIR
echo OUTPUT: $OUTPUT

INPUTFILE=$(ls $INPUTDIR/*/DAT??????)

echo "#ParticleID, E(GeV), zenith, azimuth, nMu, nMu>300GeV, nMu>500GeV, nMu>1TeV, nMuThin300, thinW300, nMuThin500, thinW500, nMu<50m, nMu<100m, nMu<150m, nMu<200m, nMu<250m, nMu<300m, nMu<350m, nMu<400m, nMu<450m, nMu<500m, nMu<550m, nMu<600m, nMu<650m, nMu<700m, nMu<750m, nMu<800m, nMu<850m, nMu<900m, nMu<950m, nMu<1000m, nEM, nEM<50m, nEM<100m, nEM<150m, nEM<200m, nEM<250m, nEM<300m, nEM<350m, nEM<400m, nEM<450m, nEM<500m, nEM<550m, nEM<600m, nEM<650m, nEM<700m, nEM<750m, nEM<800m, nEM<850m, nEM<900m, nEM<950m, nEM<1000m, xmax, nMuLong, nEMxmax, nEMLong, Rcorsika, Lcorsika, RFit, sigmaRFit, LFit, sigmaLFit, XmaxFit, sigmaXmaxFit, RFitShift, sigmaRFitShift, LFitShift, sigmaLFitShift, XmaxFitShift, sigmaXmaxShift, RFitABS, sigmaRFitABS, LFitABS, sigmaLFitABS, XmaxFitABS, sigmaXmaxABS, XmaxAndringaFit, sigmaXmaxAndringa, RAndringaFit, sigmaRAndringa, LAndringaFit, sigmaLAndringa, XmaxAndringaFitShift, sigmaXmaxAndringaShift, RAndringaFitShift, sigmaRAndringaShift, LAndringaFitShift, sigmaLAndringaShift, XmaxAndringaFitABS, sigmaXmaxAndringaABS, RAndringaFitABS, sigmaRAndringaABS, LAndringaFitABS, sigmaLAndringaABS" > $OUTPUT

for file in $INPUTFILE; do
    echo Reading: $file
    MUON_DAT=$($EXE $file)
    ZENITH=$(echo $MUON_DAT | awk '{print $3}')
    XMAX_DAT=$($EXE2 ${file}.long --zen $ZENITH)

    echo $MUON_DAT $XMAX_DAT >> $OUTPUT
done

echo DONE!