#!/bin/bash

#runs MolProbity scoring on pdb

bash ~/MolProbity/build/setpaths.sh
bash ~/MolProbity/build/bin/molprobity.molprobity $1

#Add analysis later
