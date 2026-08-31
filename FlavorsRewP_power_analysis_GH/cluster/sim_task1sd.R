parse_pars <- commandArgs(trailingOnly = TRUE)
which_dataset <- as.numeric(parse_pars[1])
task1_change_min <- as.numeric(parse_pars[2])
task1_change_max <- as.numeric(parse_pars[3])
task1_change_step <- as.numeric(parse_pars[4])

cat("which_dataset:", which_dataset, "\n",
    "task1_change_min:", task1_change_min, "\n",
    "task1_change_max:", task1_change_max, "\n",
    "task1_change_step:", task1_change_step, "\n")


# ---- Programmatic install: rstan + brms + cmdstanr (for non-interactive jobs) ----
options(repos = c(CRAN = "https://cloud.r-project.org"))
options(Ncpus = max(1L, parallel::detectCores() - 1L))
Sys.setenv(MAKEFLAGS = paste0("-j", getOption("Ncpus")))
suppressPackageStartupMessages({
  library(utils)
})

# Prefer compiling with conda's toolchain if available
conda_prefix <- Sys.getenv("CONDA_PREFIX", unset = "")
if (nzchar(conda_prefix)) {
  cc  <- file.path(conda_prefix, "bin", "x86_64-conda-linux-gnu-cc")
  cxx <- file.path(conda_prefix, "bin", "x86_64-conda-linux-gnu-c++")
  if (file.exists(cc))  Sys.setenv(CC = cc)
  if (file.exists(cxx)) {
    Sys.setenv(CXX = cxx, CXX17 = paste(cxx, "-std=gnu++17"))
  }
  Sys.setenv(R_LIBS_USER = file.path(conda_prefix, "lib", "R", "library"))
}

lib <- .libPaths()[1]
cat("Using lib path:", lib, "\n")

install_if_needed <- function(pkg, version = NULL, type = "source", ...) {
  need <- !requireNamespace(pkg, quietly = TRUE)
  if (!need && !is.null(version)) {
    cur <- tryCatch(as.character(packageVersion(pkg)), error = function(e) NA_character_)
    need <- is.na(cur) || utils::compareVersion(cur, version) < 0
  }
  if (need) {
    # Remove first to avoid stale .so
    if (pkg %in% rownames(installed.packages(lib.loc = lib))) {
      try(remove.packages(pkg, lib = lib), silent = TRUE)
    }
    install.packages(pkg, type = type, dependencies = TRUE, ...)
  }
}

# Ensure a coherent toolchain alignment:
# 1) Install (or refresh) Rcpp FIRST (so rstan links against the currently loaded Rcpp)
install_if_needed("Rcpp")             # keep whatever CRAN version is current in this session
install_if_needed("RcppParallel")

# 2) Install StanHeaders and rstan (from CRAN, source builds) so they match each other & Rcpp
install_if_needed("StanHeaders", type = "source")
install_if_needed("rstan",       type = "source")

# 3) Install brms and cmdstanr
install_if_needed("brms",     type = "source")
install_if_needed("cmdstanr", type = "source")

# Load and print versions
suppressPackageStartupMessages({
  library(Rcpp)
  library(StanHeaders)
  library(rstan)
  library(brms)
  library(cmdstanr)
})
cat("Versions:\n")
for (p in c("Rcpp","RcppParallel","StanHeaders","rstan","brms","cmdstanr")) {
  cat(sprintf("  %s = %s\n", p, as.character(utils::packageVersion(p))))
}

# CmdStan: use existing install if present; otherwise install locally
# Prefer an explicit location under $HOME to avoid permission issues in conda dirs
default_cmdstan_dir <- file.path(Sys.getenv("HOME"), ".cmdstanr")
if (cmdstanr::cmdstan_version(error_on_NA = FALSE) %in% c(NA, "not found")) {
  dir.create(default_cmdstan_dir, showWarnings = FALSE, recursive = TRUE)
  cat("Installing CmdStan (this compiles C++ and can take a while)...\n")
  # You can pin a version by setting version = "2.37.0" (or whichever you prefer)
  cmdstanr::install_cmdstan(dir = default_cmdstan_dir,
                            cores = max(1L, parallel::detectCores() - 1L),
                            overwrite = TRUE,
                            quiet = TRUE)
} else {
  cat("Found existing CmdStan at:", cmdstanr::cmdstan_path(), "\n")
}

# If conda provided a CmdStan symlink (e.g., $CONDA_PREFIX/bin/cmdstan), prefer it
conda_cmdstan <- file.path(conda_prefix, "bin", "cmdstan")
if (nzchar(conda_prefix) && file.exists(conda_cmdstan)) {
  cmdstanr::set_cmdstan_path(conda_cmdstan)
  cat("CmdStan path set to conda-provided:", cmdstanr::cmdstan_path(), "\n")
}

# Final sanity checks
cat("CXX17:", system("R CMD config CXX17", intern = TRUE), "\n")
cat("g++  :", system("which g++", intern = TRUE), "\n")
cat("CmdStan version:", tryCatch(as.character(cmdstanr::cmdstan_version()), error = function(e) "not found"), "\n")

# Compile a tiny Stan model to verify rstan toolchain
cat("Compiling test model with rstan…\n")
test_code <- "parameters { real y; } model { y ~ normal(0, 1); }"
sm <- rstan::stan_model(model_code = test_code)
fit <- rstan::sampling(sm, iter = 200, chains = 2, refresh = 0)
print(summary(fit)$summary[1, , drop = FALSE])

cat("✓ rstan + brms + cmdstanr are installed and working.\n")


library(tidyverse)
library(brms)
library(cmdstanr)
library(loo)
options(mc.cores = 24)

# set_cmdstan_path('/fslhome/fslcollab40/cmdstanr_cmdstan/cmdstan-2.26.1')

load_path <- "/home/fslcollab40/nobackup/autodelete/FlavorsRewP/data_tib"
save_path <- "/home/fslcollab40/nobackup/autodelete/FlavorsRewP/data_tib_task1"


#set up brms models
n_chains <- 4
n_cores <- 4
n_iter <- 2000
n_warmup <- 3000
n_threads <- 6


pr_ls <- c(set_prior("student_t(10, 0, 5)", class = "b"),
          set_prior("lkj(3)", class = "L"),
          set_prior("student_t(10, 0, 2)", class = "sd"),
          set_prior("student_t(10, 0, 2)", dpar = "sigma"),
          set_prior("student_t(10, 0, 2)", class = "sd", dpar = "sigma"))


for (task1_change in seq(task1_change_min, task1_change_max, by = task1_change_step)) {
  data_tib <- readRDS(file.path(load_path,paste0("data_tib_",which_dataset,".rds")))
  
  data_tib <-
    data_tib %>%
    unnest(raw_sim) %>%
    mutate(erp_raw = erp,
           erp = erp + ifelse(task == "task1", 
                        rnorm(n(),0,task1_change), 
                        0)) %>%
    nest(data = c(subjid,site,task,event,erp,erp_raw)) %>%
    mutate(change = paste0("task1 add stddev ", task1_change)) %>%
    mutate(event_fit = map2(data, seed,
                            ~brm(bf(erp ~ 0 + event +
                                      (0+event|p|subjid),
                                    sigma ~ 0 + event +
                                      (0+event|p|subjid)),
                                 data = .x,
                                 prior = pr_ls,
                                 chains = n_chains,
                                 cores = n_cores,
                                 iter = n_iter + n_warmup,
                                 warmup = n_warmup,
                                 seed = .y,
                                 save_pars = save_pars(all = TRUE),
                                 backend = "cmdstanr",
                                 threads = threading(n_threads))
    ))  %>%
    mutate(task_fit = map2(data, seed,
                           ~brm(bf(erp ~ 0 + event + event:task +
                                     (0+event|p|subjid),
                                   sigma ~ 0 + event + event:task +
                                     (0+event|p|subjid)),
                                data = .x,
                                prior = pr_ls,
                                chains = n_chains,
                                cores = n_cores,
                                iter = n_iter + n_warmup,
                                warmup = n_warmup,
                                seed = .y,
                                save_pars = save_pars(all = TRUE),
                                backend = "cmdstanr",
                                threads = threading(n_threads))
    ))
  
  
  event_fit_loo <- loo(data_tib$event_fit[[1]])
  print(event_fit_loo)
  
  task_fit_loo <- loo(data_tib$task_fit[[1]])
  
  print(task_fit_loo)
  
  data_tib <-
    data_tib %>%
    mutate(event_fit_loo = list(event_fit_loo),
           task_fit_loo = list(task_fit_loo))
  
  saveRDS(data_tib,file.path(save_path,
                             paste0("data_tib_",which_dataset,
                                    "_task1sd_",task1_change,
                                    ".rds")))
  
  
  
}
