#BSUB -J WES_single_input -n thread -e %J.err
module purge
module load use.own
module load WES
export R_LIBS=/gpfs/user/abayraktar/tools/Rlibs 
# Now it requires two parameters: thread number and memory size in GB

/gpfs/user/abayraktar/4combined_scripts/wes.bash input thread memory
