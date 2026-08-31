#!/bin/bash
#
#SBATCH --comment=frewp_comp
#SBATCH --job-name=frewp_comp
#SBATCH --output=/home/fslcollab40/FlavorsRewP/Slurm_Output/brm_sing_comp_%j.txt
#SBATCH --time=1:00:00
#SBATCH --cpus-per-task=2 # number of processor cores (i.e. tasks)
#SBATCH --nodes=1 # number of nodes
#SBATCH --mem=2G # total memory
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
echo /home/fslcollab40/FlavorsRewP/compile_sim_data.R ${1} ${2} ${3} ${4}
conda run -n my_r_env --no-capture-output \
  Rscript --vanilla /home/fslcollab40/FlavorsRewP/compile_sim_data.R "$1" "$2" "$3" "$4"
