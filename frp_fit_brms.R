inp_args <- commandArgs(trailingOnly = TRUE)
which_model <- as.numeric(inp_args[1])

library(brms)
library(cmdstanr)

df <- readRDS(".frp_brms/frp_df_sngtrl_081926.rds")
save_path <- "./frp_brms"

n_chains <- 4
n_cores <- 4
n_iter <- 25000
n_warmup <- 5000
n_seed <- 052826
n_threads <- 7


df$event <- relevel(factor(df$event), ref = "loss")

pr_ls <- c(
  set_prior("student_t(10, 0, 5)", class = "b"),
  set_prior("student_t(10, 0, 2)", class = "b", dpar = "sigma"),
  set_prior("lkj(3)", class = "L"),
  set_prior("student_t(10, 0, 2)", class = "sd"),
  set_prior("student_t(10, 0, 2)", class = "sd", dpar = "sigma")
)



model_formulas <- list(
  bf(rewp ~ 0 + event + (0 + event|p|subjid),
     sigma ~ 0 + event + (0 + event|p|subjid)),
  
  bf(rewp ~ 0 + event + event:task + (0 + event + event:task|p|subjid),
     sigma ~ 0 + event + event:task + (0 + event + event:task|p|subjid)),
  
  bf(rewp ~ 0 + event + event:task + event:site + (0 + event + event:task|p|subjid),
     sigma ~ 0 + event + event:task + event:site + (0 + event + event:task|p|subjid)),
  
  bf(rewp ~ 0 + event + event:task + event:site + event:task:site + (0 + event + event:task|p|subjid),
     sigma ~ 0 + event + event:task + event:site + event:task:site +(0 + event + event:task|p|subjid)),
  
  bf(rewp ~ 0 + task + task:event + (0 + task + task:event|p|subjid),
     sigma ~ 0 + task + task:event + (0 + task + task:event|p|subjid)),
  
  bf(rewp ~ 0 + cell + (0 + cell|p|subjid),
     sigma ~ 0 + cell + (0 + cell|p|subjid))
  
)

# Function to fit, summarize, and add criterion to a model
frp_brm_fitmodel <- function(formula, model_name, df_in,
                                   pr_ls, n_chains, n_cores,
                                   n_iter, n_warmup, n_seed,
                                   n_threads, save_path) {
  model <- brm(formula,
               data = df_in,
               family = gaussian(),
               prior = pr_ls,
               chains = n_chains,
               cores = n_cores,
               iter = n_iter + n_warmup,
               warmup = n_warmup,
               seed = n_seed,
               sample_prior = "yes",
               backend = "cmdstanr",
               threads = threading(n_threads),
               file = file.path(save_path, model_name))
  
  print(summary(model))
  
  add_criterion(model,
                c("loo"),
                pointwise = TRUE,
                reloo = TRUE,
                k_threshold = .70,
                file = file.path(save_path, model_name),
                force_save = TRUE)
  
  return(model)
}

# Use the function based on the value of which_model
if (1 <= which_model && which_model <= 6) {
  model_name <- paste0("brm_frp_m", which_model)
  assign(model_name, 
         frp_brm_fitmodel(model_formulas[[which_model]], model_name, df,
                         pr_ls, n_chains, n_cores,
                         n_iter, n_warmup, n_seed,
                         n_threads, save_path))
} else {
  stop("Invalid value for which_model")
}