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

for X in $(seq "$START" "$END"); do
  echo "Submitting jobs for X = ${X}"

  sbatch /home/fslcollab40/FlavorsRewP/sbatch_sim_task1sd.sh ${X} .00031 .0004 .00001
  sleep 1

  sbatch /home/fslcollab40/FlavorsRewP/sbatch_sim_task1sd_rewp.sh ${X} .00031 .0004 .00001
  sleep 1

  sbatch /home/fslcollab40/FlavorsRewP/sbatch_sim_task2sd.sh ${X} .00031 .0004 .00001
  sleep 1

  sbatch /home/fslcollab40/FlavorsRewP/sbatch_sim_task2sd_rewp.sh ${X} .00031 .0004 .00001
  sleep 1

done