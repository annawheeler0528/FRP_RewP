parse_pars <- commandArgs(trailingOnly = TRUE)
which_tsk <- as.numeric(parse_pars[1])
which_dataset <- as.numeric(parse_pars[2])
which_rewp <- as.numeric(parse_pars[3])
which_sd <- as.numeric(parse_pars[4])

start_time <- Sys.time()

library(tidyverse)
library(brms)
library(loo)

wrkdir <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/sc_FlavorsRewP"
save_path <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/data_tib_summaries"
base_loo_path <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/data_tib_base_brms"

# wrkdir <- "/nobackup/archive/usr/fslcollab40/FlavorsRewP"
# save_path <- "/nobackup/archive/usr/fslcollab40/FlavorsRewP/data_tib_summaries"
# base_loo <- readRDS("/nobackup/archive/usr/fslcollab40/FlavorsRewP/brm_rewp_loo.rds")

if (which_tsk == 1) {
  tsk_path <- file.path(wrkdir,"data_tib_task1")
} else if (which_tsk == 2) {
  tsk_path <- file.path(wrkdir,"data_tib_task2")
} 

tsk_fnames <- list.files(path = tsk_path,
                         pattern = paste0("data_tib_", 
                                          which_dataset, 
                                          "_.*\\.rds"),
                         recursive = F)

fname_suffix <- ""

base_loo <- readRDS(file.path(base_loo_path,paste0("data_tib_", 
                                                   which_dataset,
                                                   "_loo.rds")))

if (which_rewp == 0){
  tsk_fnames <- tsk_fnames[!grepl("rewp",tsk_fnames)]
} else if (which_rewp == 1){
  tsk_fnames <- tsk_fnames[grepl("rewp",tsk_fnames)]
  fname_suffix <- paste0(fname_suffix,"_rewp")
}

if (which_sd == 0){
  tsk_fnames <- tsk_fnames[!grepl("sd",tsk_fnames)]
} else if (which_sd == 1){
  tsk_fnames <- tsk_fnames[grepl("sd",tsk_fnames)]
  fname_suffix <- paste0(fname_suffix,"_sd")
}

tsk <- tibble("fnames"=tsk_fnames) %>%
  add_column(seed = NA,
             change = NA,
             event_fit_loo = NA,
             task_fit_loo = NA) %>% 
  mutate(across(seed,as.integer)) %>% 
  mutate(across(change,as.character)) %>% 
  mutate(across(event_fit_loo:task_fit_loo,as.list)) %>%
  mutate(base_fit_loo = rep(list(base_loo), length(tsk_fnames)))

for (ii in 1:length(tsk_fnames)){
  tsk[ii,2:5] <- readRDS(file.path(tsk_path,tsk_fnames[ii])) %>% 
    select(seed,change,event_fit_loo,task_fit_loo)
}


check_loo_comp <- function(loo1,loo2){
  
  lc <- suppressWarnings(loo_compare(loo1,loo2))
  
  #if any of the first three criteria are met, then models
  # are functionally equivalent
  
  #if none of the first three criteria is met, then a model
  # outperforms the other. The model in the first row is the
  # better fitting model.
  if (!is.na(lc[2,2])) {
  
  if (lc[2,1] <= 4) {
    
    #if elpd_diff <= 4, then models are similar
    str_res <- "equiv"
    
  } else if (lc[2,1] <= lc[2,2]*2) {
    
    #if elpd_diff <= 2*elpd_diff SE, then models are similar
    str_res <- "equiv"
    
  } else if (lc[2,2] <= lc[2,3]*2) {
    
    #if elpd_diff SE <= 2*elpd_diff of the subsample, then models are similar
    str_res <- "equiv"
    
  } else if (rownames(lc)[1] == "data_tib$event_fit[[1]]") {
    str_res <- "event"
  } else if (rownames(lc)[1] == "data_tib$task_fit[[1]]") {
    str_res <- "task"
  } } else if (rownames(lc)[1] == "data_tib$base_fit[[1]]") {
    str_res <- "task"
  } else {
    str_res <- "ERROR"
  }
  return(str_res) 
}


parse_changes <- function(change){
  
  name_split <- strsplit(change," ")
  
  change_out <- tibble(
    "task_name" = substr(name_split[[1]][1],1,5),
    "rewp_only" = ifelse(nchar(name_split[[1]][1]) == 5,0,1),
    "type" = ifelse(length(name_split[[1]]) == 3,"mean","sd"),
    "diff" = as.numeric(name_split[[1]][length(name_split[[1]])])
  )
  
  return(change_out)
}


################ Double Check done separately for event_fit_loo

# event_summary <- tsk %>%
#   mutate(loo_comp_event = map2(event_fit_loo, base_fit_loo, 
#                          check_loo_comp)) %>%
#   unnest(loo_comp_event) %>%
#   mutate(change_out = map(change, parse_changes)) %>%
#   unnest(change_out) %>%
#   select(-event_fit_loo,-task_fit_loo, -base_fit_loo)
# 
# task_summary <- tsk %>%
#   mutate(loo_comp_task = map2(task_fit_loo, base_fit_loo, 
#                          check_loo_comp)) %>%
#   unnest(loo_comp_task) %>%
#   mutate(change_out = map(change, parse_changes)) %>%
#   unnest(change_out) %>%
#   select(-event_fit_loo,-task_fit_loo, -base_fit_loo)

summary_long <- tsk %>% 
  pivot_longer(c(event_fit_loo, task_fit_loo), 
                names_to = "target", 
                values_to = "fit_loo", 
                values_drop_na = TRUE ) %>% 
  mutate(loo_comp = 
           purrr::map2(fit_loo, 
                       base_fit_loo, 
                       check_loo_comp)) %>% 
  unnest(loo_comp) %>% 
  mutate(change_out = 
           purrr::map(change, 
                      parse_changes)) %>% 
  unnest(change_out) %>% 
  select(-fit_loo, -base_fit_loo) %>%
  pivot_wider(
    names_from = target,
    values_from = loo_comp,
    names_glue = "{target}"
  )


saveRDS(summary_long,
        file.path(save_path,
                  paste0("data_tib_loo_summ_",
                         which_tsk,"_",
                         which_dataset,
                         fname_suffix,
                         ".rds")))

Sys.time() - start_time
