#!/urs/bin/python

#importing dependenices 
import sys
from CG_to_Atomistic_functions import *

pdb_1 ='fixed_'+ sys.argv[1] + '.pdb'
pdb_2 = sys.argv[1] + '_protein.pdb'

protein, start, p1residues = CG_to_Atomistic_one(pdb_1,pdb_2)


pdb_3 = 'system_' + sys.argv[1] + '.pdb'

CG_to_Atomistic_two(pdb_3, sys.argv[1], protein, p1residues)





