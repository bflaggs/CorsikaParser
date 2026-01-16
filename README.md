# CorsikaParser

This repository hosts the code for parsing CORSIKA output files to later be used in my multivariate analysis.

The parsing is based on the original parsing used in the raw CORSIKA output files generated for the surface array of IceCube-Gen2, the next generation upgrade to the IceCube Neutrino Observatory.

### Goal
Update parser to be of general use, i.e. if a CORSIKA simulation library exists then these parsing scripts can be run "out of the box" with minimal updates/selection of options.

### To-do:
1. Run basic scripts on Auger CORSIKA simulations stored on grid
2. Convert basic scripts to run multiple times via jobs submitted to CPU nodes
3. Make submission scripts for this...

