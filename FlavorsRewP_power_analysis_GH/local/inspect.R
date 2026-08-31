library(brms)

datatib <- readRDS("/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/data_tib_task1/data_tib_1_task1sd_rewp_0.01.rds")
base_loo <- readRDS("/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/brm_rewp_loo.rds")


loo_compare(datatib$event_fit_loo[[1]],base_loo)
lc<- loo_compare(datatib$event_fit_loo[[1]],base_loo)

check_loo_comp(datatib$event_fit_loo[[1]],base_loo)


fit <- readRDS("/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/inspect/data_tib_20_task1sd_0.99.rds")
loo_compare(fit$event_fit_loo[[1]],fit$task_fit_loo[[1]])

