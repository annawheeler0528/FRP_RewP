parse_pars <- commandArgs(trailingOnly = TRUE)
which_tsk <- as.numeric(parse_pars[1])
which_dataset <- as.numeric(parse_pars[2])
which_rewp <- as.numeric(parse_pars[3])
which_sd <- as.numeric(parse_pars[4])

cat("which_tsk:", which_tsk, "\n",
    "which_dataset:", which_dataset, "\n",
    "which_rewp:", which_rewp, "\n",
    "which_sd:", which_sd, "\n")


start_time <- Sys.time()

library(tidyverse)
library(brms)
library(loo)

# wrkdir <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/sc_FlavorsRewP"
# save_path <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/data_tib_summaries"

wrkdir <- "/home/fslcollab40/nobackup/autodelete/FlavorsRewP"
save_path <- "/home/fslcollab40/nobackup/autodelete/FlavorsRewP/data_tib_summaries"

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
  mutate(across(event_fit_loo:task_fit_loo,as.list)) 

for (ii in 1:length(tsk_fnames)){
  tsk[ii,2:5] <- readRDS(file.path(tsk_path,tsk_fnames[ii])) %>% 
    select(seed,change,event_fit_loo,task_fit_loo)
}


check_loo_comp <- function(loo1,loo2) {
  
  lc <- suppressWarnings(loo_compare(loo1,loo2))
  # lc <- loo_compare(loo1,loo2)
  
  #if any of the first three criteria are met, then models
  # are functionally equivalent
  
  #if none of the first three criteria is met, then a model
  # outperforms the other. The model in the first row is the
  # better fitting model.
  if (!is.na(lc[2,2])) {
    
    if (abs(lc[2,1]) <= 4) {
      
      #if elpd_diff <= 4, then models are similar
      str_res <- "equiv"
      
    } else if (abs(lc[2,1]) <= lc[2,2]*2) {
      
      #if elpd_diff <= 2*elpd_diff SE, then models are similar
      str_res <- "equiv"
      
    } else if (rownames(lc)[1] %in% c("data_tib$event_fit_loo[[1]]",
                                      "data_tib$event_fit[[1]]",
                                      "event_fit", "event_fit_loo")) {
      str_res <- "event"
    } else if (rownames(lc)[1] %in% c("data_tib$task_fit_loo[[1]]", 
                                      "data_tib$task_fit[[1]]",
                                      "task_fit", "task_fit_loo")) {
      str_res <- "task"
    } else {
      str_res <- "ERROR"
    }
  } else {
    str_res <- "LOOCOMP_FAIL"
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

tsk_summary <- tsk %>%
  mutate(loo_comp = map2(event_fit_loo, task_fit_loo, 
                         check_loo_comp)) %>%
  unnest(loo_comp) %>%
  mutate(change_out = map(change, parse_changes)) %>%
  unnest(change_out) %>%
  select(-event_fit_loo,-task_fit_loo)

saveRDS(tsk_summary,
        file.path(save_path,
                  paste0("data_tib_loo_summ_",
                         which_tsk,"_",
                         which_dataset,
                         fname_suffix,
                         ".rds")))

print(Sys.time() - start_time)
