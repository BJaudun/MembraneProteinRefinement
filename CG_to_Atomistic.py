#!/urs/bin/python

#importing dependenices 
import sys
from CG_to_Atomistic_functions import *

pdb_1 ='fixed_'+ sys.argv[1] + '.pdb'
pdb_2 = sys.argv[1] + '_protein.pdb'


a, b, c = CG_to_Atomistic_one(pdb_1,pdb_2)

sys.exit(b)
