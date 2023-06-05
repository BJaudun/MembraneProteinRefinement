#!/bin/bash

gmx make_ndx -f CG-system.pdb -o index.ndx << EOF 
del 0
del 1-40
0|rPOP*
1&!0
!1 
del 1
name 1 Lipid
name 2 SOL_ION
q
EOF

gmx grompp -f cgmd.mdp -o md -c CG-system.pdb -maxwarn -1 -n index.ndx 

gmx mdrun -deffnm md -v True -nsteps 10000 
