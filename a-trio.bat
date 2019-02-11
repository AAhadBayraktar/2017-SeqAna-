#BSUB -J WES_trio -n 40 -e %J.err
module purge
module load use.own
module load WES
export R_LIBS=/gpfs/user/abayraktar/tools/Rlibs 
# Now it requires two parameters: thread number and memory size in GB

in_dir=/gpfs/user/abayraktar/FASTQ-INPUTS/
family=altas
input1=1014349_S2
input2=1014363_S5
input3=1014364_S6
thread=40
memory=160
ped=/gpfs/user/abayraktar/3partitioned_scripts/ped.ped

#=====#======#=====#

sed "s@input@$in_dir$family/$input1@g;s/thread/$thread/g;s/memory/$memory/g;\
s@WES_single_input@WES_trio_$family/$input1@g" \
/gpfs/user/abayraktar/4combined_scripts/single.bat > /gpfs/user/abayraktar/4combined_scripts/single.bat.1
bsub -q dataqHigh < /gpfs/user/abayraktar/4combined_scripts/single.bat.1

sed "s@input@$in_dir$family\/$input2@g;s/thread/$thread/g;s/memory/$memory/g;\
s@WES_single_input@WES_trio_$family/$input2@g" \
/gpfs/user/abayraktar/4combined_scripts/single.bat > /gpfs/user/abayraktar/4combined_scripts/single.bat.2
bsub -q dataqHigh < /gpfs/user/abayraktar/4combined_scripts/single.bat.2

sed "s@input@$in_dir$family\/$input3@g;s/thread/$thread/g;s/memory/$memory/g;\
s@WES_single_input@WES_trio_$family/$input3@g" \
/gpfs/user/abayraktar/4combined_scripts/single.bat > /gpfs/user/abayraktar/4combined_scripts/single.bat.3
bsub -q dataqHigh < /gpfs/user/abayraktar/4combined_scripts/single.bat.3


bsub -q dataqHigh \
-w "done(WES_trio_$family/$input1) && done(WES_trio_$family/$input2) && done(WES_trio_$family/$input3)" \
/gpfs/user/abayraktar/4combined_scripts/trio.bash thread memory $input1 $input2 $input3 $ped $family
