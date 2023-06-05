#!/urs/bin/python

#importing dependenices 
import pandas as pd
import sys
from biopandas.pdb import PandasPdb


ppdb = PandasPdb()
ppdb.read_pdb(sys.argv[1]) 
restraints=[]
for i in ppdb.df['ATOM']['b_factor']:
  restraints.append(i*2)
posre = open('PROTEIN_refine_posre.itp', 'w')
posre.write("[ position_restraints ]\n")
for i in range(1,len(restraints)):
  val=restraints[i-1]
  posre.write("{}".format(i) + "\t" + "1" + "\t" + "{}".format(val) + "\t" + "\t" + "{}".format(val) + "\t" + "\t" + "{}".format(val) + "\t" + "\n")
posre.close()
