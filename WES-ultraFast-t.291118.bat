#BSUB -J WES_trial-004-fast -n 40 -e %J.err
module purge
module load use.own
module load WES
export R_LIBS=/gpfs/user/abayraktar/tools/Rlibs 
# Now it requires two parameters: thread number and memory size in GB
/gpfs/user/abayraktar/1perfect_files/WES_lsf_271118-160G-40coreBWA.bash $1 40 160
