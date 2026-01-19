#!/bin/env python3
import glob
import os

ABS_PATH_HERE = str(os.path.dirname(os.path.realpath(__file__)))

import subprocess
import getpass

simDir = "/data/sim/IceCubeUpgrade/CosmicRay/Radio/coreas/data/continuous/star-pattern"
outDir = "/data/sim/IceCubeUpgrade/CosmicRay/Gen2Surface/sim/mass"

whoami = getpass.getuser()


def MakeAndSubmit(prim, eng, zen):

    fullPath = simDir + "/" + prim + "/" + eng + "/" + zen
    outPath = outDir + "/{}-{}-{}.txt".format(prim, eng, zen)

    file = open("tempSub.sub", "w")
    file.write("Executable = {}/CorsikaParser_RunControl.sh\n".format(ABS_PATH_HERE))
    file.write("Error = {}/logfiles/mass_{}_{}_{}.err\n".format(ABS_PATH_HERE, prim, eng, zen))
    file.write("Output = {}/logfiles/mass_{}_{}_{}.out\n".format(ABS_PATH_HERE, prim, eng, zen))
    file.write("Log = /scratch/{}/gen2/mass_{}_{}_{}.log\n".format(whoami, prim, eng, zen))
    file.write("request_memory = 2GB\n")
    file.write("Arguments = {} {}\n".format(fullPath, outPath))
    file.write("Queue 1\n")
    file.close()

    subprocess.call(["condor_submit tempSub.sub -batch-name {0}_{1}_{2}".format(eng, zen, prim[0:4])], shell=True)
    subprocess.call(["rm tempSub.sub"], shell=True)


prims = glob.glob(simDir + "/*")
prims = [val.split("/")[-1] for val in prims]
prims.sort()

prims = ["proton", "helium", "oxygen", "iron"]

for prim in prims:
    engs = glob.glob(simDir + "/" + prim + "/lgE_1*")
    engs = [val.split("/")[-1] for val in engs]
    engs.sort()

    for eng in engs:
        zens = glob.glob(simDir + "/" + prim + "/" + eng + "/*")
        zens = [val.split("/")[-1] for val in zens]
        zens.sort()
        for zen in zens:
            MakeAndSubmit(prim, eng, zen)
