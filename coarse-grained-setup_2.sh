#!/bin/bash


#Gromacs centering 
 gmx make_ndx -f $1  -o index.ndx  << EOF #both gromacs statements working
del 0
del 1-100
rDUM
q
EOF

 gmx editconf -f $1  -o centered.pdb -n index.ndx -d 3 -c true << EOF
0
0
EOF


cutx=`grep CRYST centered.pdb | cut -c9-15`
x=`bc -l <<< "scale=3; $cutx / 10"`
cuty=`grep CRYST centered.pdb | cut -c18-24`
y=`bc -l <<< "scale=3; $cuty / 10"`
cutz=`grep CRYST centered.pdb | cut -c27-33`
z=`bc -l <<< "scale=3; $cutz / 10"`
 

gmx confrms -f2 $1 -f1 centered.pdb  -one true -o aligned.gro  << EOF
3
3
EOF

gmx editconf -f aligned.gro -o protein.pdb -label A -resnr 1 -n index.ndx << EOF #potential for -n to be wrong 
0
0
EOF

gmx traj -f aligned.gro -com -s aligned.gro -ox -n <<EOD
1
EOD

b=`tail -n1 coord.xvg |cut -f4`

z2=`bc -l <<< "scale=2; $z / 2 "`

out=`bc -l <<< "scale=2; $z2 - $b "`

python ~/Script/python/residue_replace.py

#Martini 
martinize2 -f protein.pdb -ff martini3001 -x protein-cg.pdb -o protein-cg.top -elastic -ef 500 -eu 1.0 -el 0.5 -ea 0 -ep 0 -merge A -maxwarn 100000 -scfix -dssp mkdssp

sed -e 's/^molecule.*/Protein 1/g' molecule*.itp >  protein-cg.itp

#Insane3.py running ##lipid will need generalising 
~/anaconda3/envs/py2/bin/python2 ~/Script/python/insane3.py  -l $2 -salt 0.15 -sol W -o CG-system.gro -p topol.top -f protein-cg.pdb -center -x $x -y $y -z $z -dm $out

#Fix insane3 naming of ions
#sed -i 's/TNA/NA/g' CG-system.gro
#sed -i 's/TNA/NA/g' topol.top 
#sed -i 's/TCL/CL/g' CG-system.gro
#sed -i 's/TCL/CL/g' topol.top
sed -i 's/#include "martini_v3.itp"/#include "martini_v3.0.0.itp"\n#include "martini_v3.0.0_ions_v1.itp"\n#include "martini_v3.0.0_solvents_v1.itp"\n#include "martini_v3.0.0_phospholipids_v1.itp"\n/g' topol.top

gmx grompp -f em_1000.mdp -o em.tpr -c CG-system.gro -maxwarn -1 -v true

gmx mdrun -deffnm em -c CG-system.pdb 




