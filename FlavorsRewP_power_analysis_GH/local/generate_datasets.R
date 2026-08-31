library(tidyverse)
library(brms)
library(cmdstanr)

# set_cmdstan_path('/home/c/clayson/cmdstanr_cmdstan/cmdstan-2.26.1')

brm_rewp_fileloc <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/brm_rewp.rds"
save_path <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/data_tib"

n_cores <- 1
seed_start <- 1000

n_subjs_site1 <- 30
n_subjs_site2 <- 30

#Doors
n_trls_loss_task1 <- 30
n_trls_gain_task1 <- 30

#MID
n_trls_loss_task2 <- 20
n_trls_gain_task2 <- 50

#Time Estimation
n_trls_loss_task3 <- 30
n_trls_gain_task3 <- 30



#dummy each task for site1
#dummy site1: task 1
df_dummy_site1_task1_loss <- data.frame(id = 1,
                                       site = "site1",
                                       task = "task1",
                                       event = "loss",
                                       erp = rep(seq_len(n_trls_loss_task1),
                                                 n_subjs_site1))
df_dummy_site1_task1_loss$id <- rep(seq_len(n_subjs_site1),
                                   each = n_trls_loss_task1)

df_dummy_site1_task1_gain <- data.frame(id = 1,
                                       site = "site1",
                                       task = "task1",
                                       event = "gain",
                                       erp = rep(seq_len(n_trls_gain_task1),
                                                 n_subjs_site1))
df_dummy_site1_task1_gain$id <- rep(seq_len(n_subjs_site1),
                                   each = n_trls_gain_task1)



#dummy site1 task 2
df_dummy_site1_task2_loss <- data.frame(id = 1,
                                       site = "site1",
                                       task = "task2",
                                       event = "loss",
                                       erp = rep(seq_len(n_trls_loss_task2),
                                                 n_subjs_site1))
df_dummy_site1_task2_loss$id <- rep(seq_len(n_subjs_site1),
                                   each = n_trls_loss_task2)

df_dummy_site1_task2_gain <- data.frame(id = 1,
                                       site = "site1",
                                       task = "task2",
                                       event = "gain",
                                       erp = rep(seq_len(n_trls_gain_task2),
                                                 n_subjs_site1))
df_dummy_site1_task2_gain$id <- rep(seq_len(n_subjs_site1),
                                   each = n_trls_gain_task2)




#dummy site1: task 3
df_dummy_site1_task3_loss <- data.frame(id = 1,
                                       site = "site1",
                                       task = "task3",
                                       event = "loss",
                                       erp = rep(seq_len(n_trls_loss_task3),
                                                 n_subjs_site1))
df_dummy_site1_task3_loss$id <- rep(seq_len(n_subjs_site1),
                                   each = n_trls_loss_task3)

df_dummy_site1_task3_gain <- data.frame(id = 1,
                                       site = "site1",
                                       task = "task3",
                                       event = "gain",
                                       erp = rep(seq_len(n_trls_gain_task3),
                                                 n_subjs_site1))
df_dummy_site1_task3_gain$id <- rep(seq_len(n_subjs_site1),
                                   each = n_trls_gain_task3)





#dummy each task for site2
#dummy site2: task 1
df_dummy_site2_task1_loss <- data.frame(id = 1,
                                       site = "site2",
                                       task = "task1",
                                       event = "loss",
                                       erp = rep(seq_len(n_trls_loss_task1),
                                                 n_subjs_site2))
df_dummy_site2_task1_loss$id <- rep(seq_len(n_subjs_site2),
                                   each = n_trls_loss_task1)

df_dummy_site2_task1_gain <- data.frame(id = 1,
                                       site = "site2",
                                       task = "task1",
                                       event = "gain",
                                       erp = rep(seq_len(n_trls_gain_task1),
                                                 n_subjs_site2))
df_dummy_site2_task1_gain$id <- rep(seq_len(n_subjs_site2),
                                   each = n_trls_gain_task1)



#dummy site2 task 2
df_dummy_site2_task2_loss <- data.frame(id = 1,
                                       site = "site2",
                                       task = "task2",
                                       event = "loss",
                                       erp = rep(seq_len(n_trls_loss_task2),
                                                 n_subjs_site2))
df_dummy_site2_task2_loss$id <- rep(seq_len(n_subjs_site2),
                                   each = n_trls_loss_task2)

df_dummy_site2_task2_gain <- data.frame(id = 1,
                                       site = "site2",
                                       task = "task2",
                                       event = "gain",
                                       erp = rep(seq_len(n_trls_gain_task2),
                                                 n_subjs_site2))
df_dummy_site2_task2_gain$id <- rep(seq_len(n_subjs_site2),
                                   each = n_trls_gain_task2)




#dummy site2: task 3
df_dummy_site2_task3_loss <- data.frame(id = 1,
                                       site = "site2",
                                       task = "task3",
                                       event = "loss",
                                       erp = rep(seq_len(n_trls_loss_task3),
                                                 n_subjs_site2))
df_dummy_site2_task3_loss$id <- rep(seq_len(n_subjs_site2),
                                   each = n_trls_loss_task3)

df_dummy_site2_task3_gain <- data.frame(id = 1,
                                       site = "site2",
                                       task = "task3",
                                       event = "gain",
                                       erp = rep(seq_len(n_trls_gain_task3),
                                                 n_subjs_site2))
df_dummy_site2_task3_gain$id <- rep(seq_len(n_subjs_site2),
                                   each = n_trls_gain_task3)


df_dummy <-
  rbind(df_dummy_site1_task1_loss,
        df_dummy_site1_task1_gain,
        df_dummy_site1_task2_loss,
        df_dummy_site1_task2_gain,
        df_dummy_site1_task3_loss,
        df_dummy_site1_task3_gain,
        df_dummy_site2_task1_loss,
        df_dummy_site2_task1_gain,
        df_dummy_site2_task2_loss,
        df_dummy_site2_task2_gain,
        df_dummy_site2_task3_loss,
        df_dummy_site2_task3_gain) %>%
  arrange(.,
          id,site,task,event)



#double check that all dataframes are gain length
nrow(df_dummy) ==
  (n_subjs_site1*n_trls_loss_task1) +
  (n_subjs_site1*n_trls_gain_task1) +
  (n_subjs_site1*n_trls_loss_task2) +
  (n_subjs_site1*n_trls_gain_task2) +
  (n_subjs_site1*n_trls_loss_task3) +
  (n_subjs_site1*n_trls_gain_task3) +
  (n_subjs_site2*n_trls_loss_task1) +
  (n_subjs_site2*n_trls_gain_task1) +
  (n_subjs_site2*n_trls_loss_task2) +
  (n_subjs_site2*n_trls_gain_task2) +
  (n_subjs_site2*n_trls_loss_task3) +
  (n_subjs_site2*n_trls_gain_task3)

colnames(df_dummy)[1] <- "subjid"

brm_rewp <- readRDS(brm_rewp_fileloc)


simDat <- function(seed, df,
                   brm_fit, n_cores){

  set.seed(seed)

  pp_sim <- posterior_predict(
    brm_fit,
    newdata = df,
    allow_new_levels = T,
    ndraws = 1,
    summary = F,
    cores = n_cores)[1,]

  df_out <- df
  df_out$erp <- pp_sim

  return(df_out)
}


for (n_sim in 51:100){
  data_tib <-
    tibble(seed = seed_start + n_sim) %>%
    mutate(raw_sim = map(seed, simDat,
                         df = df_dummy,
                         brm_fit = brm_rewp,
                         n_cores = n_cores))

  saveRDS(data_tib,
          file = file.path(save_path,
                           paste0("data_tib_",n_sim,".rds")))
}
