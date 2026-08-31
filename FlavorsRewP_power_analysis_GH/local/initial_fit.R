library(brms)
library(cmdstanr)

df <- read.csv("/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/rewp_meanamp_raw.csv",
                     stringsAsFactors = F,
                     header = T)
save_path <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis"

n_chains <- 4
n_cores <- 4
n_threads <- 3
n_iter <- 10000
n_seed <- 111125



pr_ls <- c(set_prior("student_t(10, 0, 5)", class = "b"),
           set_prior("lkj(3)", class = "L"),
           set_prior("student_t(10, 0, 2)", class = "sd"),
           set_prior("student_t(10, 0, 2)", dpar = "sigma"),
           set_prior("student_t(10, 0, 2)", class = "sd", dpar = "sigma"))


df$event[df$event == "CorrectFdbk"] <- "gain"
df$event[df$event == "IncorrectFdbk"] <- "loss"
df <- df[df$event != "CorrectFdbkFood",]
  
colnames(df)[colnames(df) == "meanamp"] <- "erp"

library(dplyr)

data_filtered <- df %>%
  group_by(subjid) %>%
  filter(all(c("gain", "loss") %in% event)) %>%
  ungroup()

excluded_ids <- setdiff(unique(df$subjid), unique(data_filtered$subjid))


brm_rewp <- brm(bf(erp ~ 0 + Intercept + event +
                      (1+event|p|subjid),
                    sigma ~ 0 + Intercept + event +
                      (1+event|p|subjid)),
                 data = data_filtered,
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
                 file = file.path(save_path,"brm_rewp"))

base_fit_loo <- loo(brm_rewp)

summary(brm_rewp)

print(base_fit_loo)

saveRDS(base_fit_loo,"/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/brm_rewp_loo.rds")

