#!/urs/bin/python
import pandas as pd
import sys
from biopandas.pdb import PandasPdb
import os
import csv
import MDAnalysis as mda
from MDAnalysis.analysis import distances
import numpy as np
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')

# Should use most recent pdb file from lipid system
u = mda.Universe(sys.argv[1])

CA = u.select_atoms("name CA")

dist_arr = distances.distance_array(CA.positions, CA.positions, box=u.dimensions)

# Looping through half of matrix to check which are contacts
contact = []

for i in range(len(dist_arr)):
    for j in range(len(dist_arr)):
        if i >= j or i >= j - 1:
            continue
        else:
            if dist_arr[i, j] <= 8:
                contact.append([i, j])
            else:
                continue

#print(contact)
residue_size = len(CA) - 2
startpoint = 0
prev_i = 0
line_list = []

for i in contact:
    if i[0] == prev_i:
        #print(startpoint)
        pass
    else:
        startpoint += (residue_size - i[0] + 1)
        prev_i = i[0]
        #print(startpoint)
    line_list.append(startpoint + (i[1] - i[0] - 2))

#print(line_list)


with open(sys.argv[2]+'.deepmetapsicov.con', 'r') as f:
    lines = f.readlines()

# CDA Score
sum_array = []  # List for the sum of DMP scores
number_array = []  # List for counting the number of contacts

for i in range(len(CA)):
    sum_array.append(0)
    number_array.append(0)



for k in line_list:
    data = lines[k].split()
    sum_array[int(data[0])-1] = sum_array[int(data[0])-1] + float(data[4])
    sum_array[int(data[1])-1] = sum_array[int(data[1])-1] + float(data[4])
    number_array[int(data[0])-1] = number_array[int(data[0])-1] + 1
    number_array[int(data[1])-1] = number_array[int(data[1])-1] + 1

#print(number_array)
#print(sum_array)

CDA_score = []
positional_restriants=[]



for i in range(len(CA)):
    CDA_score.append(sum_array[i] / number_array[i])
    positional_restriants.append(CDA_score[i]*397.48 + 20.92) 
	
#print(CDA_score)
#print(positional_restriants)

# Create a PandasPdb object
ppdb = PandasPdb()

# Read the PDB file specified in the command-line argument
ppdb.read_pdb(sys.argv[1])

# Extract B-factor values and double them
residues = ppdb.df['ATOM']['residue_number']

# Open the output file for writing
with open('PROTEIN_refine_posre.itp', 'w') as posre:
    posre.write("[ position_restraints ]\n")

    # Iterate over the B-factor values
    for i, val in enumerate(residues, start=1):
        posre.write("{}\t1\t{}\t{}\t{}\n".format(i, positional_restriants[val], positional_restriants[val], positional_restriants[val]))
