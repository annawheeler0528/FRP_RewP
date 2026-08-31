library(tidyverse)
library(ggplot2)

wrkdir <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/data_tib_summaries"
save_path <- "/Users/peterclayson/Library/CloudStorage/Box-Box/gdrive_data/FlavorsRewP/pwranalysis/summary"

seed_start <- 1001
seed_stop <- 1050

# wrkdir <- "/fslhome/fslcollab40/compute/ff/data_tib_summaries"
# save_path <- "/fslhome/fslcollab40/compute/ff"


fnames <- list.files(path = wrkdir,
                     pattern = "\\.rds",
                     recursive = F,
                     full.names = T)


# tsk <- tibble("fnames"=fnames) %>%
#   add_column(data_summ = NA) %>% 
#   mutate(across(data_summ,as.list)) 

tsk <- fnames %>%
  map_df(~readRDS(.))

# --- Diagnostic (added 2026-07): surface non-decisive / failed LOO comparisons ---
# The power calc below counts ONLY a decisive "task" win as a detection, so
# "equiv", "event", and any failed comparison ("ERROR" / "LOOCOMP_FAIL") score 0.
# Failed comparisons are legitimate non-detections, but a large count would
# DEFLATE power and usually signals an upstream LOO problem (e.g. high Pareto-k),
# so print the full tally and warn if any failures are present.
print(dplyr::count(tsk, loo_comp))
.n_failed <- sum(tsk$loo_comp %in% c("ERROR", "LOOCOMP_FAIL"), na.rm = TRUE)
if (.n_failed > 0) {
  warning(sprintf("%d of %d summary rows had ERROR/LOOCOMP_FAIL LOO comparisons (counted as non-detections).",
                  .n_failed, nrow(tsk)))
}


tsk %>%
  filter(between(seed,!!seed_start,!!seed_stop)) %>%
  select(task_name,rewp_only,type,diff) %>%
  distinct() %>%
  count()

# should_be_there_130 <- tsk %>%
#   filter(between(seed,101,130)) %>%
#   select(task_name,rewp_only,type,diff) %>%
#   distinct()
# 
# should_be_there_131 <- tsk %>%
#   filter(between(seed,131,150)) %>%
#   select(task_name,rewp_only,type,diff) %>%
#   distinct()

#we have some files that shouldn't be there because they are from
# a previous run. Let's filter only what we want included

tsk_keep <- tsk %>%
  filter(#task_name == "task1",
    type == "mean",
    rewp_only == 0,
    between(diff,.05,.40))

tsk_add <- tsk %>%
  filter(#task_name == "task1",
    type == "mean",
    rewp_only == 1,
    between(diff,.05,.75))

tsk_keep <- bind_rows(tsk_keep,tsk_add)

tsk_add <- tsk %>%
  filter(task_name == "task1",
         type == "sd",
         #rewp_only == 0,
         between(diff,0.001,.01))

tsk_keep <- bind_rows(tsk_keep,tsk_add)

tsk_add <- tsk %>%
  filter(task_name == "task2" | task_name == "task3",
         type == "sd",
         #rewp_only == 0,
         between(diff,.001,.01))

tsk_keep <- bind_rows(tsk_keep,tsk_add)


tsk_distinct <- tsk_keep %>%
  select(task_name,rewp_only,type,diff) %>%
  distinct() 

# tsk_distinct <- tsk %>%
#   select(task_name,rewp_only,type,diff) %>%
#   distinct() 

tsk_keep_seed_counts <- tsk_keep %>%
  filter(between(seed,!!seed_start,!!seed_stop)) %>%
  group_by(seed) %>%
  count()

blnk_set <- bind_cols(tsk_distinct,
                      missing = rep(F,nrow(tsk_distinct)))

for (ii in seed_start:seed_stop) {
  
  jset <- bind_cols(seed = rep(ii,nrow(blnk_set)),
                    blnk_set)
  
  for (jj in 1:nrow(jset)) {
    
    find_jset_row <- tsk_keep %>%
      filter(seed == jset$seed[jj],
             task_name == jset$task_name[jj],
             rewp_only == jset$rewp_only[jj],
             type == jset$type[jj],
             diff == jset$diff[jj]) %>%
      count()
    
    if (find_jset_row$n == 1) {
      jset$missing[jj] <- 0
    } else {
      jset$missing[jj] <- 1
    }
    
  }
  if (ii == seed_start) {
    master <- jset
  }  else {
    master <- bind_rows(master,jset)
  }
}

# 
# write.csv(master[master$missing == 1,])
# 
# 
# huhhhh <- master[master$missing == 1,]
# 
# 
# seed_counts <- tsk %>%
#   filter(between(seed,!!seed_start,!!seed_stop)) %>%
#   group_by(seed) %>%
#   count()
# 
# select(task_name,rewp_only,type,diff) %>%
#   distinct()
# 
# tsk %>%
#   select(task_name,rewp_only,type,diff) 

# saveRDS(tsk_keep,
#         file.path(save_path,"pwr_summ.rds"))


# tsk %>%
#   filter(task_name == "task2",
#         rewp_only == 0,
#          type == "mean",
#          diff == .1) %>%
#   mutate(check = ifelse(loo_comp == "task",1,0),
#          count = n()) %>%
#   summarize(power = mean(check))



pwr_mean_summ <- tsk %>%
  filter(type == "mean") %>%
  group_by(task_name, rewp_only, type, diff) %>%
  mutate(check_loo = ifelse(loo_comp == "task", 1L, 0L),   # detection = a decisive 'task' win ONLY; equiv/event/ERROR/LOOCOMP_FAIL all count as 0
         count = n()) %>%
  summarize(power = mean(check_loo))




ggplot(pwr_mean_summ %>% filter(rewp_only == 1), 
       aes(x = diff, y = power, color = task_name)) +
  geom_line(size=.5) + 
  theme_bw() + 
  theme(axis.text=element_text(size=14), 
        axis.title=element_text(size=14), 
        legend.text=element_text(size=14)) +
  geom_hline(yintercept = 0.90, linetype = 2)



ggplot(pwr_mean_summ %>% filter(rewp_only == 1), 
       aes(x = diff, y = power, color = task_name)) +
  geom_line(size=.5) + 
  theme_bw() + 
  theme(axis.text=element_text(size=14), 
        axis.title=element_text(size=14), 
        legend.text=element_text(size=14)) +
  geom_hline(yintercept = 0.90, linetype = 2)


ggplot(pwr_mean_summ, 
       aes(x = diff, y = power, color = task_name)) +
  geom_line(size=.5) + 
  scale_color_manual(
    name = "Event Changed",
    breaks = c("task1","task2"),
    labels = c("Task 1/3","Task 2"),
    values = c("red","dark green")) +
  geom_hline(yintercept = 0.90, linetype = 2) +
  labs(x = "Change in Amplitude", y = "Sensitivity") +
  theme_bw() + 
  theme(axis.text=element_text(size=14), 
        axis.title=element_text(size=14), 
        legend.text=element_text(size=14),
        legend.title=element_text(size=14)) +
  facet_grid(~rewp_only,
             labeller=labeller(rewp_only = c(
               "0" = "Gain/Loss", 
               "1" = "Only Gain")))




pwr_sd_summ <- tsk %>%
  filter(type == "sd") %>%
  group_by(task_name, rewp_only, type, diff) %>%
  mutate(check_loo = ifelse(loo_comp == "task", 1L, 0L),   # detection = a decisive 'task' win ONLY; equiv/event/ERROR/LOOCOMP_FAIL all count as 0
         count = n()) %>%
  summarize(power = mean(check_loo))



ggplot(pwr_sd_summ, 
       aes(x = diff, y = power, color = task_name)) +
  geom_line(size=.5) + 
  scale_color_manual(
    name = "Event Changed",
    breaks = c("task1","task2"),
    labels = c("Task 1/3","Task 2"),
    values = c("red","dark green")) +
  geom_hline(yintercept = 0.90, linetype = 2) +
  labs(x = "Change in SD", y = "Sensitivity") +
  theme_bw() + 
  theme(axis.text=element_text(size=14), 
        axis.title=element_text(size=14), 
        legend.text=element_text(size=14),
        legend.title=element_text(size=14)) +
  facet_grid(~rewp_only,
             labeller=labeller(rewp_only = c(
               "0" = "Gain/Loss", 
               "1" = "Only Gain")))














power_mean_out <- pwr_mean_summ %>%
  filter(rewp_only %in% c(0, 1)) %>%
  group_by(task_name, rewp_only) %>%
  arrange(diff, .by_group = TRUE) %>%
  mutate(min_future_power = rev(cummin(rev(power)))) %>%
  # rows where power is ≥ .90 and *never* dips below .90 afterward
  filter(power >= 0.80, min_future_power >= 0.80) %>%
  slice_head(n = 1) %>%
  select(task_name, rewp_only, diff, power)

power_mean_out


power_sd_out <- pwr_sd_summ %>%
  filter(rewp_only %in% c(0, 1)) %>%
  group_by(task_name, rewp_only) %>%
  arrange(diff, .by_group = TRUE) %>%
  mutate(min_future_power = rev(cummin(rev(power)))) %>%
  # rows where power is ≥ .90 and *never* dips below .90 afterward
  filter(power >= 0.80, min_future_power >= 0.80) %>%
  slice_head(n = 1) %>%
  select(task_name, rewp_only, diff, power)

power_sd_out