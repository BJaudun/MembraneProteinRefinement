#!/bin/bash

cg2at -group all -o align -w tip3p -c CG-system.pdb -a fixed_$1 -loc CG2AT -ff charmm36-jul2020-updated -fg martini_3-0_charmm36 


cd CG2AT/FINAL/

gmx grompp -f ../../em_1000.mdp -o final.tpr  -c final_cg2at_aligned.pdb -p topol_final.top -maxwarn -1

cp -R ./* ../../Atomistic
cd ../../Atomistic

gmx editconf -f final.tpr -o system_$1

gmx confrms -f1 system_$1 -f2  ../CG2AT/PROTEIN/PROTEIN_aligned_merged.pdb -one True -o $2_protein.pdb << EOF
1
1
EOF

#MDAnalysis

python ~/Script/python/CG_to_Atomistic.py "$2"

gmx editconf -f system_$1 -o system_$1 -resnr $? 

python ~/Script/python/CG_to_Atomistic_two.py $2 #see if I can improve by not repeating steps potentially problems in the future

gmx make_ndx -f $2_combined_system.pdb -o index.ndx << EOF
del 2-40 
rSOL|rNA*|rCL*
1|2
0&!3
del 3 
name 2 water_and_ions
name 3 Lipid
q
EOF

mv topol_final.top topol.top

chmod 777 PROTEIN_0.itp

python ~/Script/python/CG_to_Atomistic_three.py

echo -e "\n#ifdef REFINE\n#include \"PROTEIN_refine_posre.itp\"\n#endif\n" >> PROTEIN_0.itp

gmx grompp -f em_100.mdp -o em -c $2_combined_system.pdb -maxwarn -1 # generalise naming 

gmx mdrun -deffnm em  -c $2_atomistic_system.pdb -v True #generalise naming 
