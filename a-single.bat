#BSUB -J WES -n 40 -e %J.err
module purge
module load use.own
module load WES
export R_LIBS=/gpfs/user/abayraktar/tools/Rlibs 
# Now it requires two parameters: thread number and memory size in GB
# NO SLASH!!! at the end of input variable

input="/gpfs/user/abayraktar/FASTQ-INPUTS/RabiaKaya"
job=$(basename $input)
thread=40
memory=160

#=====#======#=====#

sed "s@input@$input@g;s/thread/$thread/g;s/memory/$memory/g" \
/gpfs/user/abayraktar/4combined_scripts/single.bat > /gpfs/user/abayraktar/4combined_scripts/single."$job".bat
bsub -q dataqHigh < /gpfs/user/abayraktar/4combined_scripts/single."$job".bat
