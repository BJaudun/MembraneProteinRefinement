#!/urs/bin/python

#importing dependenices 

import MDAnalysis
import pandas as pd
from biopandas.pdb import PandasPdb

def CG_to_Atomistic_one(pdb1, pdb2):
	
	p1 = MDAnalysis.Universe(pdb1) # Generalise
	p1residues = p1.select_atoms('name CA').resids
	start = p1residues[0]
	
	u = MDAnalysis.Universe(pdb2) #Generalise #input gmx confrms from convery back to atomistic
	protein = u.select_atoms('protein')
	
	return (protein, start, p1residues)  


def CG_to_Atomistic_two(pdb1, name, atom, residues):
	p2 = MDAnalysis.Universe(pdb1)
	p2residues = p2.select_atoms('name CA').resids
	system = p2.select_atoms('not protein')
	combined = MDAnalysis.Merge(atom.atoms, system.atoms)

	All = combined.atoms

	df = pd.DataFrame({'original':p2residues.tolist(),'new':residues.tolist()})

	df = df.set_index('original')

	for i in All:
			if i.residue.resid in df.index:
					i.residue.resid = df.loc[i.residue.resid,'new']

	All.dimensions = p2.dimensions
	All.write(name +"_combined_system.pdb")

	return () # need to return combined pdb 
