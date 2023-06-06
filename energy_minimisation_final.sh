#!/bin/bash
#requires access to em.mdp file


gmx pdb2gmx -f $2_refined.pdb -ff charmm27 -ignh true -water tip3p -o conf.pdb

gmx editconf -f conf.pdb -d 8 -c true -o conf.pdb

gmx grompp -f em_100.mdp -maxwarn 5  -o em -c conf.pdb #requires em.mdp 

gmx mdrun -deffnm em -c clean.pdb

echo 'system' | gmx trjconv -f clean.pdb  -o mpm_refine_$1  -s em.tpr
