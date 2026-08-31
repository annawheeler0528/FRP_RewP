library(brms)
library(cmdstanr)

wrkdir <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/data_tib"
savdir <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/data_tib_base_brms"

n_chains <- 4
n_cores <- 4
n_threads <- 4
n_iter <- 500
n_seed <- 111125

fnames <- list.files(path = wrkdir,
                     recursive = F)


pr_ls <- c(set_prior("student_t(10, 0, 5)", class = "b"),
           set_prior("lkj(3)", class = "L"),
           set_prior("student_t(10, 0, 2)", class = "sd"),
           set_prior("student_t(10, 0, 2)", dpar = "sigma"),
           set_prior("student_t(10, 0, 2)", class = "sd", dpar = "sigma"))



for (ii in 1:length(fnames)) {
  
  df <- readRDS(file.path(wrkdir,fnames[ii]))$raw_sim[[1]]
  
  base_fit <- brm(bf(erp ~ 0 + Intercept + event +
                       (1+event|p|subjid),
                     sigma ~ 0 + Intercept + event +
                       (1+event|p|subjid)),
                  data = df,
                  prior = pr_ls,
                  family = gaussian(),
                  chains = n_chains,
                  cores = n_cores,
                  iter = n_iter,
                  seed = n_seed,
                  save_pars = save_pars(all = TRUE),
                  sample_prior = "yes",
                  backend = "cmdstanr",
                  threads = threading(n_threads),
                  file = file.path(savdir,fnames[ii]))
  
  base_fit_loo <- loo(base_fit)
  
  summary(base_fit)
  
  print(base_fit_loo)
  
  saveRDS(base_fit_loo,
          file.path(savdir,paste0(tools::file_path_sans_ext(fnames[ii]),"_loo.rds")))
  
}
