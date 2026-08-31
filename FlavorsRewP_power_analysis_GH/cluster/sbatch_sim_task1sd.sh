#!/bin/bash
#
#SBATCH --comment=flvrrewp
#SBATCH --job-name=flvrrewp
#SBATCH --output=/home/fslcollab40/FlavorsRewP/Slurm_Output/brm_%j.txt
#SBATCH --time=20:00:00
#SBATCH --cpus-per-task=24 # number of processor cores (i.e. tasks)
#SBATCH --nodes=1 # number of nodes
#SBATCH --mem=32G # total memory
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=peter.clayson@gmail.com


set -eo pipefail          # note: no -u here

module purge              # avoid module toolchain pollution

# ensure conda is on PATH (adjust if needed)
export PATH="$HOME/miniconda3/condabin:$PATH"

# quick sanity check (runs inside env)
conda run -n my_r_env --no-capture-output Rscript --vanilla -e '
cat("R=", R.version.string, "\n", sep="");
for (p in c("rstan","StanHeaders","Rcpp","RcppParallel")) {
  cat(p,"=", as.character(utils::packageVersion(p)),"\n")
}
cat(".libPaths():\n"); print(.libPaths());
so <- system.file("libs", .Platform$r_arch, package="rstan");
cat("rstan .so:", so, "\n");
if (nzchar(so)) cat(system(sprintf("ldd %s/rstan.so | egrep \"stdc\\+\\+|gcc_s|c\\+\\+\"", so), intern=TRUE), sep="\n");
'


# run your script in the env
echo /home/fslcollab40/FlavorsRewP/sim_task1sd.R ${1} ${2} ${3} ${4}
conda run -n my_r_env --no-capture-output \
  Rscript --vanilla /home/fslcollab40/FlavorsRewP/sim_task1sd.R "$1" "$2" "$3" "$4"
