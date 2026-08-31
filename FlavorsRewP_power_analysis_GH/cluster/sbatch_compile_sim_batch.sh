#!/bin/bash
#
#SBATCH --comment=flvrrewp
#SBATCH --job-name=flvrrewp
#SBATCH --output=/home/fslcollab40/FlavorsRewP/Slurm_Output/brm_batch_%j.txt
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=2 # number of processor cores (i.e. tasks)
#SBATCH --nodes=1 # number of nodes
#SBATCH --mem=1G # total memory
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=peter.clayson@gmail.com

START=$1
END=$2

if [ -z "$START" ] || [ -z "$END" ]; then
  echo "Usage: sbatch $0 <start> <end>"
  exit 1
fi

for which_dataset in $(seq "$START" "$END"); do
  echo "Submitting jobs for dataset = ${which_dataset}"

  for which_tsk in {1..2}; do
    for which_rewp in 0 1; do
      for which_sd in 0 1; do
        
        sbatch /home/fslcollab40/FlavorsRewP/sbatch_compile_sim_sing.sh \
          "$which_tsk" "$which_dataset" "$which_rewp" "$which_sd"

        sleep 1

      done
    done
  done
done