#!/usr/bin/env python3

# Must supply a directory(s) with the ASCII files

import numpy as np
from scipy.optimize import curve_fit
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("input", type=str, help="Input data files.")
parser.add_argument("--zen", required=True, type=float, help="Zenith angle of the shower (rad)")
args = parser.parse_args()


def LongFileParser(filename):
    depths = []
    positrons = []
    electrons = []
    muPlus = []
    muMinus = []
    chargedParticles = []

    file = open(filename, "r")
    nLines = 0
    xmax = -1
    Rcorsika = -1
    Lcorsika = -1
    energyDeposit = 0
    for iline, line in enumerate(file):
        if iline == 0:
            nLines = line.split()[3]
            continue

        if iline <= 2:
            continue  # Skip header

        cols = line.split()

        if "ENERGY" in cols and "DEPOSIT" in cols:
            energyDeposit += 1

        if "PARAMETERS" in cols:
            xmax = float(cols[4])
            x0 = float(cols[3])
            lambdaApprox = float(cols[5]) # Drop 1st + 2nd order corrections

            x0Prime = x0 - xmax
            Rcorsika = float(np.sqrt(lambdaApprox / abs(x0Prime))) # Shape parameter
            Lcorsika = float(np.sqrt(abs(x0Prime * lambdaApprox))) # Characteristic width

        if len(cols) != 10 or "FIT" in cols:
            continue

        if energyDeposit > 0:
            continue  # Skip all energy deposit lines in .long file

        depths.append(float(cols[0]))
        positrons.append(float(cols[2]))
        electrons.append(float(cols[3]))
        muPlus.append(float(cols[4]))
        muMinus.append(float(cols[5]))
        chargedParticles.append(float(cols[7]))

    file.close()

    return depths, positrons, electrons, muPlus, muMinus, chargedParticles, xmax, Rcorsika, Lcorsika, x0, lambdaApprox


def FindGroundIndex(ground, depths):
    absDepthToGround = []

    for i in range(len(depths)):
        absDepthToGround.append(abs(depths[i] - ground))

    minDepthToGround = min(absDepthToGround)
    indGround = absDepthToGround.index(minDepthToGround)

    return indGround

# Comment out old functions, want to fit for Xmax as well...
#def GHFunction(XPrime, R, L):
#    return (1 + (R * XPrime / L)) ** (1 / (R**2)) * np.exp(-1. * XPrime / (L * R))

#def FitLongitudinalProfile(depths, xmax, chargedParticles, Nmax, RGuess, LGuess):
#    XPrimeVals = np.asarray(depths) - xmax
#    particleArray = np.asarray(chargedParticles) / Nmax
#    popt, pcov = curve_fit(GHFunction, XPrimeVals, particleArray, p0=[RGuess, LGuess])
#    perr = np.sqrt(np.diag(pcov))
#    RFit = popt[0]
#    LFit = popt[1]
#    RFitSigma = perr[0]
#    LFitSigma = perr[1]
#    return RFit, RFitSigma, LFit, LFitSigma


def GHFunction(X, Nmax, Xmax, X0, lamb):
    return Nmax * ((X - X0) / (Xmax - X0)) ** ((Xmax - X0) / lamb) * np.exp((Xmax - X) / lamb)

def GHFunctionWithABS(X, Nmax, Xmax, X0, lamb):
    return Nmax * (abs(X - X0) / (Xmax - X0)) ** ((Xmax - X0) / lamb) * np.exp((Xmax - X) / lamb)


def AndringaFunction(X, Xmax, R, L):
    return (1 + (R * (X - Xmax) / L)) ** (1 / (R**2)) * np.exp(-1. * (X - Xmax) / (L * R))

def AndringaFunctionWithABS(X, Xmax, R, L):
    return abs(1 + (R * (X - Xmax) / L)) ** (1 / (R**2)) * np.exp(-1. * (X - Xmax) / (L * R))


def FitLongitudinalProfile(depths, chargedParticles, NmaxGuess, XmaxGuess, X0Guess, lambGuess, shift=False, absoluteValue=False):

    if (shift == True) and (absoluteValue == False):
        depthArray = np.asarray(depths) + 100.0 # Shift all depths by 100 g/cm^2 to see if we get physical results...
    else:
        depthArray = np.asarray(depths)

    particleArray = np.asarray(chargedParticles)

    # Use Poissonian counting statistics to estimate an uncertainty in the charged particle number
    # Take uncertainty as ratio of uncertainty in bin to particle number in bin so bins with more particles have less uncertainty than those with less particles
    uncerts = 1.0 / np.sqrt(particleArray)

    if (shift == True) and (absoluteValue == False):
        popt, pcov = curve_fit(GHFunction, depthArray, particleArray, p0=[NmaxGuess, XmaxGuess+100.0, X0Guess, lambGuess], sigma=uncerts)
    elif (absoluteValue == True) and (shift == False):
        popt, pcov = curve_fit(GHFunctionWithABS, depthArray, particleArray, p0=[NmaxGuess, XmaxGuess, X0Guess, lambGuess], sigma=uncerts)
    else:
        popt, pcov = curve_fit(GHFunction, depthArray, particleArray, p0=[NmaxGuess, XmaxGuess, X0Guess, lambGuess], sigma=uncerts)

    perr = np.sqrt(np.diag(pcov))

    NmaxFit = popt[0]
    XmaxFit = popt[1]
    X0Fit = popt[2]
    lambFit = popt[3]

    NmaxSigma = perr[0]
    XmaxSigma = perr[1]
    X0Sigma = perr[2]
    lambSigma = perr[3]

    X0Prime = abs(X0Fit - XmaxFit)

    RFit = np.sqrt(lambFit / X0Prime)
    LFit = np.sqrt(X0Prime * lambFit)

    # Squared terms found from error prop.
    sigmaRterm1 = (lambSigma ** 2) / (4 * lambFit * X0Prime)
    sigmaRterm2 = (lambFit * (X0Sigma ** 2 + XmaxSigma ** 2)) / (4 * X0Prime ** 3)

    RFitSigma = np.sqrt(sigmaRterm1 + sigmaRterm2)

    # Squared terms found from error prop.
    sigmaLterm1 = (X0Prime * lambSigma ** 2) / (4 * lambFit)
    sigmaLterm2 = (lambFit * (X0Sigma ** 2 + XmaxSigma ** 2)) / (4 * X0Prime)

    LFitSigma = np.sqrt(sigmaLterm1 + sigmaLterm2)

    if (shift == True) and (absoluteValue == False):
        XmaxFit = popt[1] - 100.0 # Shift Xmax from fit back to real xmax
        X0Fit = popt[2] - 100.0 # Shift X0 value from fit back to true X0 for observed profile    

    return RFit, RFitSigma, LFit, LFitSigma, XmaxFit, XmaxSigma


def FitLongitudinalProfileAndringa(depths, NprimeArray, XmaxGuess, RGuess, LGuess, shift=False, absoluteValue=False):

    if (shift == True) and (absoluteValue == False):
        depthArray = np.asarray(depths) + 100.0 # Shift all depths by 100 g/cm^2 to see if we get physical results...
    else:
        depthArray = np.asarray(depths)

    # Use Poissonian counting statistics to estimate an uncertainty in the charged particle number
    # Take uncertainty as ratio of uncertainty in bin to particle number in bin so bins with more particles have less uncertainty than those with less particles
    uncerts = 1.0 / np.sqrt(NprimeArray)

    if (shift == True) and (absoluteValue == False):
        popt, pcov = curve_fit(AndringaFunction, depthArray, NprimeArray, p0=[XmaxGuess+100.0, RGuess, LGuess], sigma=uncerts)
    elif (absoluteValue == True) and (shift == False):
        popt, pcov = curve_fit(AndringaFunctionWithABS, depthArray, NprimeArray, p0=[XmaxGuess, RGuess, LGuess], sigma=uncerts)
    else:
        popt, pcov = curve_fit(AndringaFunction, depthArray, NprimeArray, p0=[XmaxGuess, RGuess, LGuess], sigma=uncerts)

    perr = np.sqrt(np.diag(pcov))

    XmaxAndringaFit = popt[0]
    RAndringaFit = popt[1]
    LAndringaFit = popt[2]

    XmaxAndringaSigma = perr[0]
    RAndringaSigma = perr[1]
    LAndringaSigma = perr[2]

    if (shift == True) and (absoluteValue == False):
        XmaxAndringaFit = popt[0] - 100.0 # Shift Xmax from fit back to real xmax

    return XmaxAndringaFit, XmaxAndringaSigma, RAndringaFit, RAndringaSigma, LAndringaFit, LAndringaSigma



depths, positrons, electrons, muPlus, muMinus, chargedParticles, xmax, Rcorsika, Lcorsika, x0, lambdaApprox = LongFileParser(args.input)

totalEM = np.array(positrons) + np.array(electrons)
ixmax = np.argmax(totalEM)

if xmax > 1700:  # Sometimes corsika fits of the profile fail
    xmax = depths[ixmax]
    Rcorsika = -1
    Lcorsika = -1

ground = 696 / np.cos(args.zen)

indGround = FindGroundIndex(ground, depths)

muPlusGround = muPlus[indGround]
muMinusGround = muMinus[indGround]

positronsGround = positrons[indGround]
electronsGround = electrons[indGround]


# Remove the last point in the longitudinal distributions b/c it is not physical (sometimes below ground)
# Agnieszka suggested removing the final two points but start with only the final point at first
depths.pop()
chargedParticles.pop()

Nmax = np.max(chargedParticles)
NmaxGuess = np.random.normal(loc=Nmax, scale=0.1*abs(Nmax))
XmaxGuess = depths[ixmax]
X0Guess = np.random.normal(loc=x0, scale=0.1*abs(x0))
lambGuess = np.random.normal(loc=lambdaApprox, scale=0.1*abs(lambdaApprox))

NPrimeValsCORSIKA = np.asarray(chargedParticles) / Nmax
RGuess = np.random.normal(loc=Rcorsika, scale=0.1*abs(Rcorsika))
LGuess = np.random.normal(loc=Lcorsika, scale=0.1*abs(Lcorsika))

RFit, RFitSigma, LFit, LFitSigma, XmaxFit, XmaxSigma = FitLongitudinalProfile(depths, chargedParticles, NmaxGuess, XmaxGuess, X0Guess, lambGuess, shift=False, absoluteValue=False)
RFitShift, RFitSigmaShift, LFitShift, LFitSigmaShift, XmaxFitShift, XmaxSigmaShift = FitLongitudinalProfile(depths, chargedParticles, NmaxGuess, XmaxGuess, X0Guess, lambGuess, shift=True, absoluteValue=False)
RFitABS, RFitSigmaABS, LFitABS, LFitSigmaABS, XmaxFitABS, XmaxSigmaABS = FitLongitudinalProfile(depths, chargedParticles, NmaxGuess, XmaxGuess, X0Guess, lambGuess, shift=False, absoluteValue=True)

XmaxAndringaFit, XmaxAndringaSigma, RAndringaFit, RAndringaSigma, LAndringaFit, LAndringaSigma = FitLongitudinalProfileAndringa(depths, NPrimeValsCORSIKA, XmaxGuess, RGuess, LGuess, shift=False, absoluteValue=False)
XmaxAndringaFitShift, XmaxAndringaSigmaShift, RAndringaFitShift, RAndringaSigmaShift, LAndringaFitShift, LAndringaSigmaShift = FitLongitudinalProfileAndringa(depths, NPrimeValsCORSIKA, XmaxGuess, RGuess, LGuess, shift=True, absoluteValue=False)
XmaxAndringaFitABS, XmaxAndringaSigmaABS, RAndringaFitABS, RAndringaSigmaABS, LAndringaFitABS, LAndringaSigmaABS = FitLongitudinalProfileAndringa(depths, NPrimeValsCORSIKA, XmaxGuess, RGuess, LGuess, shift=False, absoluteValue=True)


print(xmax, round(muPlusGround + muMinusGround), totalEM[ixmax], round(positronsGround + electronsGround), Rcorsika, Lcorsika, RFit, RFitSigma, LFit, LFitSigma, XmaxFit, XmaxSigma, RFitShift, RFitSigmaShift, LFitShift, LFitSigmaShift, XmaxFitShift, XmaxSigmaShift, RFitABS, RFitSigmaABS, LFitABS, LFitSigmaABS, XmaxFitABS, XmaxSigmaABS, XmaxAndringaFit, XmaxAndringaSigma, RAndringaFit, RAndringaSigma, LAndringaFit, LAndringaSigma, XmaxAndringaFitShift, XmaxAndringaSigmaShift, RAndringaFitShift, RAndringaSigmaShift, LAndringaFitShift, LAndringaSigmaShift, XmaxAndringaFitABS, XmaxAndringaSigmaABS, RAndringaFitABS, RAndringaSigmaABS, LAndringaFitABS, LAndringaSigmaABS, end="")
