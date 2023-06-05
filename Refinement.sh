#!/bin/bash

#Verifies input files and allows lipid choice 

if  ! [[ "$1" == *".pdb" ]];
then
	echo 'Please provide a protein structure'
	exit 
fi

if [ -z "$2" ];
then
		PS3='Please enter your choice: '
		options=("POPC" "POPE:POPG" "POPE:POPG:CARDIOLIPIN" "POPE:POPG:CARDIOLIPIN:UDP1")
		select opt in "${options[@]}"
	do
		case $opt in
			"POPC")
				lipid='  POPC:1'
				break
				;;
			"POPE:POPG")
				lipid=' -l POPE:7 -l POPG:3'
				break
				;;
			"POPE:POPG:CARDIOLIPIN")
				lipid='l POPE:7 -l POPG:2 -l CARD:1'
				break
				;;
			"POPE:POPG:CARDIOLIPIN:UDP1")
				lipid='-l POPE:7 -l POPG:2 -l CARD:1 -l UDP1:1'
				break
				;;
			"Quit")
				break
				;;
			*) echo "invalid option $REPLY";;
		esac
	done
else 
	if [ "$2" == 'POPC' ];
	then 
		lipid=' POPC:1'
	elif [ "$2" == 'POPE:POPG' ]
	then
		lipid='-l POPE:7 -l POPG:3'
	elif [ "$2" == 'POPE:POPG:CARDIOLIPIN' ]
	then
		lipid='-l POPE:7 -l POPG:2 -l CARD:1'
	elif [ "$2" == 'POPE:POPG:CARDIOLIPIN:UDP1' ] 
	then
		lipid='-l POPE:7 -l POPG:2 -l CARD:1 -l UDP1:1'
	else 
		echo "invalid option"
				PS3='Please enter your choice: '
				options=("POPC" "POPE:POPG" "POPE:POPG:CARDIOLIPIN" "POPE:POPG:CARDIOLIPIN:UDP1")
				select opt in "${options[@]}"
		do
			case $opt in
				"POPC")
					lipid=' -l POPC:1'
					break
					;;
				"POPE:POPG")
					lipid='-l POPE:7 -l POPG:3'
					break
					;;
				"POPE:POPG:CARDIOLIPIN")
					lipid='l POPE:7 -l POPG:2 -l CARD:1'
					break
					;;
				"POPE:POPG:CARDIOLIPIN:UDP1")
					lipid='-l POPE:7 -l POPG:2 -l CARD:1 -l UDP1:1'
					break
					;;
				"Quit")
					break
					;;
				*) echo "invalid option $REPLY";;
			esac
		done 
	fi
fi 

#Extracting name from pdb file
pdb_name=$(basename "$1" .pdb)
echo $pdb_name 

#Making file structure providing input structures & files
mkdir -p {molprobity_scoring/{input,initial,final},energy_minimisation/{initial,final},CG-to-Atomistic/Atomistic,membrane-orientation,coarse-grained-system/MD_equilibrate,plddt_dependent_position_restraints,af_refinement}
echo "molprobity_scoring/input/ energy_minimisation/initial/  plddt_dependent_position_restraints/" | xargs -n 1 cp -v . $1 
bash ~/Script/bash/em_mdp_100.sh
bash ~/Script/bash/em_mdp_1000.sh 
echo "energy_minimisation/initial energy_minimisation/final CG-to-Atomistic/Atomistic" | xargs -n 1 cp -v . em_100.mdp
echo "coarse-grained-system/ CG-to-Atomistic/"| xargs -n 1 cp -v . em_1000.mdp
wget https://github.com/pstansfeld/MemProtMD/raw/main/martini_v300.zip
unzip -o martini_v300.zip
echo "coarse-grained-system/ coarse-grained-system/MD_equilibrate" | xargs -n 1 cp -v  martini_v300/{martini_v3.0.0.itp,martini_v3.0.0_ions_v1.itp,martini_v3.0.0_phospholipids_v1.itp,martini_v3.0.0_solvents_v1.itp} coarse-grained-system

#Molprobity Input
cd  molprobity_scoring/input 
bash ~/Script/bash/molprobity.sh $1 

#Energy Minimisation initial
cd ../../energy_minimisation/initial 
bash ~/Script/bash/energy_minimisation_inital.sh $1
cp . topol.top ../../coarse-grained-system

#Molprobity Initial 
echo "../../molprobity_scoring/initial/ ../../CG-to-Atomistic/ ../../CG-to-Atomistic/Atomistic ../../membrane-orientation" | xargs -n 1 cp -v . fixed_$1
cd ../../molprobity_scoring/initial
bash ~/Script/bash/molprobity.sh fixed_$1

#Membrane Orientation
cd ../../membrane-orientation 
~/MemEmbed/bin/memembed -o memembed.pdb fixed_$1
cp . memembed.pdb ../coarse-grained-system

#Setup Coarse-Grained-system
cd ../coarse-grained-system  
bash ~/Script/bash/coarse-grained-setup_2.sh memembed.pdb $lipid #lipid problem
cp . CG-system.pdb topol.top protein-cg.itp MD_equilibrate

#Equilibrating Membrane Protein System 
cd MD_equilibrate
bash ~/Script/bash/cgmd_mdp.sh
bash ~/Script/bash/MD_equilibrate.sh
cp . CG-system.pdb ../../CG-to-Atomistic


#CG-to-Atomistic moving into the directory changes if is included equilibration step also CG-system.pdb
cd ../../CG-to-Atomistic 
bash ~/Script/bash/CG-to-Atomistic.sh $1 $pdb_name
cp Atomistic/{${pdb_name}"_atomistic_system.pdb",index.ndx,topol.top,POPC.itp,TIP3P.itp,PROTEIN_0.itp,NA.itp,CL.itp} ../af_refinement


#Plddt-dependent position restraints refinement
cd ../plddt_dependent_position_restraints/
python ~/Script/python/plddt_dependent_position_restraints.py $1
cp . PROTEIN_refine_posre.itp ../af_refinement
 
#1ns AF refinement 
cd ../af_refinement
wget https://raw.githubusercontent.com/pstansfeld/MemProtMD/main/mdp_files/1ns-refine.mdp
bash ~/Script/bash/af-refinement.sh  $pdb_name
cp . ${pdb_name}"_refined.pdb" ../energy_minimisation/final 

#Energy Minimisation final 
cd ../energy_minimisation/final 
bash ~/Script/bash/energy_minimisation_final.sh $1 $pdb_name
cp . mpm_refine_$1 ../../molprobity_scoring/final

#Molprobity Final
cd  ../../molprobity_scoring/final
bash ~/Script/bash/molprobity.sh mpm_refine_$1
