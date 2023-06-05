#!/bin/bash

#generalise naming
gmx make_ndx -f $1_atomistic_system.pdb -o sys.ndx << EOF 
del 0
del 1-40 
rPOP*|rCARD|
name 1 Lipid 
rSOL|aNA|aCL 
name 2 water_and_ions 
q
EOF


gmx grompp -f 1ns-refine.mdp -o refined -c $1_atomistic_system.pdb -r $1_atomistic_system.pdb  -maxwarn 10  -n index.ndxclear


gmx mdrun -deffnm refined -c $1_refined_system.pdb -v True -update gpu -pme gpu -nb gpu -bonded gpu 


gmx editconf -f $1_refined_system.pdb -n index.ndx -o $1_refined.pdb << EOF
1
EOF

#generalise naming 
