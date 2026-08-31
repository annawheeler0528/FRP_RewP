# FlavorsRewP — Simulation-Based Power (Sensitivity) Analysis

This directory contains everything needed to reproduce the Bayesian, simulation-based
**power / sensitivity analysis** for the *Flavors of Reward Positivity (FlavorsRewP)*
project. The analysis asks a design question:

> For a planned multi-site, multi-task study of the Reward Positivity (RewP), how large a
> between-task difference in the ERP — either a shift in **mean amplitude** or an increase in
> **trial-to-trial variability** — must exist before our planned analysis can reliably detect
> it?

"Reliably detect it" is operationalized with **Bayesian leave-one-out cross-validation (LOO)
model comparison** rather than a p-value. For each simulated dataset we fit two competing
multilevel models and ask which one LOO prefers:

- `event_fit` — the ERP depends only on feedback **event** (gain vs. loss); it does **not**
  allow the effect to differ by task.
- `task_fit` — the ERP depends on event **and on an event×task interaction**; it **does**
  allow the effect to differ by task.

We inject a known task difference of a given size into the simulated data, fit both models,
and record which model LOO prefers. Repeated over many simulated datasets, the proportion of
datasets in which `task_fit` is decisively preferred **is the statistical power (sensitivity)**
at that effect size. Sweeping the injected effect size traces out a power curve, and the
smallest effect that reaches ~80–90% sensitivity is the **minimum detectable effect** for the
planned design.

---

## 1. The pipeline at a glance

```
RAW DATA  ─────────────────── LOCAL (workstation / RStudio) ────────────────────────────
  data/rewp_meanamp_raw.csv
       │
       ▼  initial_fit.R          fit the generative model          →  brm_rewp.rds (+ _loo)
       ▼  generate_datasets.R    draw many full-study datasets     →  data_tib/*.rds
       ▼  (base_brms.R)          (optional) per-dataset base + LOO →  data_tib_base_brms/*

          ─────────────────── CLUSTER (Slurm / HPC) ────────────────────────────────────
       │  copy data_tib/*.rds to the cluster
       ▼  sim_task*.R   (×8 variants, driven by sbatch_sim_batch*.sh)
            perturb task1/task2 by a grid of magnitudes; fit event_fit + task_fit; loo()
                                                   →  data_tib_task1/* , data_tib_task2/*
       ▼  compile_sim_data.R   (driven by sbatch_compile_sim_batch.sh)
            loo_compare(event_fit, task_fit) → classify {equiv | event | task}
                                                   →  data_tib_summaries/*

          ─────────────────── LOCAL (workstation / RStudio) ────────────────────────────
       │  copy data_tib_summaries/*.rds back
       ▼  examine_summaries.R
            power = P(preferred model == task_fit) per (task, scope, type, magnitude)
                                                   →  sensitivity curves + MDE table
```

The heavy model fitting (Stages 3–4) ran on a Slurm HPC cluster; the generative modelling
(Stages 0–1) and the final summary (Stage 5) ran locally in R. The two environments are kept
in separate folders here (`local/` and `cluster/`) because that is how they were actually run.

You chose to treat the **simulated datasets as the starting point**, so the runnable core is
Stages 3 → 4 → 5. Stages 0 → 1 (and 2) are included as **provenance** — the exact scripts that
produced `data_tib/*.rds` — so the pipeline is reproducible all the way back to the raw data if
you ever need it.

---

## 2. What's in this folder

```
FlavorsRewP_power_analysis/
├── README.md                        ← this file
├── data/
│   └── rewp_meanamp_raw.csv         raw single-trial RewP mean amplitudes (real data; input to Stage 0)
├── local/                           run interactively in R / RStudio on a workstation
│   ├── initial_fit.R                Stage 0  fit the generative model from the raw data
│   ├── generate_datasets.R          Stage 1  simulate full-study datasets from that model
│   ├── base_brms.R                  Stage 2  (optional) per-dataset base model + LOO
│   ├── examine_summaries.R          Stage 5  power/sensitivity curves + minimum detectable effect
│   ├── inspect.R                    scratch/QA helper (spot-check one LOO comparison)
│   ├── compile_sim_data.R           ALTERNATE local compile (base-referenced; see §7) — not the main path
│   └── compile_sim_data_localtest.R ALTERNATE local compile, wrapped in a small test loop
└── cluster/                         run on the HPC via Slurm (keep these files together, flat)
    ├── sim_task1.R                   Stage 3  perturb task1 mean, all events
    ├── sim_task1_rewp.R              Stage 3  perturb task1 mean, gain event only (i.e., the RewP)
    ├── sim_task1sd.R                 Stage 3  perturb task1 variability (SD), all events
    ├── sim_task1sd_rewp.R            Stage 3  perturb task1 variability (SD), gain event only
    ├── sim_task2.R                   Stage 3  perturb task2 mean, all events
    ├── sim_task2_rewp.R              Stage 3  perturb task2 mean, gain event only
    ├── sim_task2sd.R                 Stage 3  perturb task2 variability (SD), all events
    ├── sim_task2sd_rewp.R            Stage 3  perturb task2 variability (SD), gain event only
    ├── compile_sim_data.R           Stage 4  CANONICAL compile that feeds examine_summaries.R
    ├── sbatch_sim_task1.sh …         Slurm wrappers, one per sim_task*.R variant (8 of them)
    ├── sbatch_sim_batch*.sh          batch drivers that submit the 8 variants across a magnitude grid
    ├── sbatch_compile_sim_sing.sh    Slurm wrapper for one compile_sim_data.R job
    └── sbatch_compile_sim_batch.sh   batch driver that submits all compile jobs
```

> **Note on the two `compile_sim_data.R` files.** `cluster/compile_sim_data.R` is the canonical
> one — it produces the `loo_comp` classification that `examine_summaries.R` reads. The
> `local/compile_sim_data.R` and `local/compile_sim_data_localtest.R` are an **alternate**
> version that additionally compares each model to a per-dataset *base* model; they were used for
> local checking and produce a different output schema. Use the cluster one for the headline
> result. See §7.

---

## 3. Software environment

All modelling is done in **R** with **`brms`** on top of a **CmdStan** backend (`cmdstanr`).

Required R packages: `tidyverse`, `brms`, `cmdstanr`, `loo`, `rstan`, `StanHeaders`, `Rcpp`,
`RcppParallel`, `ggplot2` (`ggplot2`/`dplyr`/`purrr` come with `tidyverse`).

Plus a working **C++ toolchain** and a **CmdStan** installation (CmdStan compiles Stan models to
C++). On the cluster this was handled two ways, both already baked into the scripts:

- A **conda** environment named `my_r_env` (see the `conda run -n my_r_env …` lines in every
  `sbatch_*.sh`), providing R and a matching compiler toolchain.
- A **self-contained bootstrap block** at the top of every `sim_task*.R` that will, if needed,
  install/refresh `Rcpp → RcppParallel → StanHeaders → rstan → brms → cmdstanr` (source builds,
  kept version-consistent), install CmdStan under `$HOME/.cmdstanr`, and compile a tiny test model
  to confirm the toolchain works before doing any real fitting. This makes each cluster job
  reproducible on a bare node; it also means the **first** job on a fresh environment spends time
  compiling.

Locally (Stages 0, 1, 5) you just need R with the packages above and a CmdStan install
(`cmdstanr::install_cmdstan()` once).

Reproducibility of the fits themselves is pinned by explicit `seed=` arguments throughout (see §6).

---

## 4. Stage-by-stage: what each script does and why

### Stage 0 — `local/initial_fit.R` — build the generative model  *(provenance)*
**Why:** to simulate *realistic* data we first need a model that captures the real subject-level
and trial-level structure of the RewP.
**In:** `data/rewp_meanamp_raw.csv` (columns `subjid, event, meanamp` — single-trial amplitudes).
**Does:** recodes feedback events (`CorrectFdbk → gain`, `IncorrectFdbk → loss`, drops
`CorrectFdbkFood`), renames `meanamp → erp`, keeps only subjects who have **both** gain and loss
trials, then fits a Bayesian multilevel **location-scale** Gaussian model:

```r
erp   ~ 0 + Intercept + event + (1 + event | p | subjid)
sigma ~ 0 + Intercept + event + (1 + event | p | subjid)
```

i.e. both the **mean** and the (log) **residual SD** of the ERP vary by event and by subject,
with correlated random effects (`| p |` ties the mean- and sigma-side random effects into one
covariance). 4 chains × 10,000 iterations, `sample_prior = "yes"`, priors as in §6.
**Out:** `brm_rewp.rds` (the fitted model) and `brm_rewp_loo.rds` (its LOO).

### Stage 1 — `local/generate_datasets.R` — simulate full-study datasets  *(provenance)*
**Why:** turn the generative model into many synthetic *replications* of the planned study.
**Does:** builds the planned design grid — **2 sites × 30 subjects** each, and **3 tasks** with
their real trial counts:

| task  | label (paradigm)   | gain trials | loss trials |
|-------|--------------------|-------------|-------------|
| task1 | Doors              | 30          | 30          |
| task2 | MID                | 50          | 20          |
| task3 | Time Estimation    | 30          | 30          |

Then, for each random seed, draws **one** posterior-predictive dataset from `brm_rewp`
(`posterior_predict(..., ndraws = 1, allow_new_levels = TRUE)`) — a complete, realistic
gain/loss ERP dataset for all subjects, sites, and tasks.
**Out:** `data_tib/data_tib_<n>.rds`, one per simulated study. Each is a tibble with a `seed`
column and a nested `raw_sim` list-column holding the simulated trials
(`subjid, site, task, event, erp`). The full set is datasets **1–100** (seeds **1001–1100**);
the completeness check in `examine_summaries.R` targets datasets **1–50** (seeds **1001–1050**) —
i.e. **50 simulated experiments** per condition — and power is then averaged over whatever
summarized datasets are actually present. *(The copy here loops `51:100`; an identical earlier run
produced `1:50`.)*

> **task3 shares task1's structure** (30/30 trials), which is why the final plots label the red
> series "Task 1/3". The perturbation scripts (Stage 3) only inject effects into `task1` and
> `task2`.

### Stage 2 — `local/base_brms.R` — per-dataset base model  *(optional / provenance)*
Fits a light (500-iteration) "base" model to each `data_tib/*.rds` and saves its LOO to
`data_tib_base_brms/`. This base LOO is used **only** by the alternate local compile (§7); the
canonical power path does not need it. Included for completeness.

### Stage 3 — `cluster/sim_task*.R` — inject an effect, fit the two rival models  *(core)*
**Why:** this is where "power" is generated. For a given dataset and a given injected effect
size, we perturb the data, fit both `event_fit` and `task_fit`, and store their LOOs so Stage 4
can decide which model wins.

Each script takes four command-line arguments:

```
Rscript sim_task<v>.R  <which_dataset>  <change_min>  <change_max>  <change_step>
```

and loops `change` from `change_min` to `change_max` in steps of `change_step`. For each
`change` it (a) reloads `data_tib_<which_dataset>.rds`, (b) applies the perturbation below,
(c) fits both models, (d) computes `loo()` for each, and (e) saves a results tibble.

The **8 variants** are the crossing of *task* × *event scope* × *effect type*:

| script                | task  | applied to      | effect type                    | change label written      | output file suffix        |
|-----------------------|-------|-----------------|--------------------------------|---------------------------|---------------------------|
| `sim_task1.R`         | task1 | gain **and** loss | **mean** shift `erp += c`      | `task1 plus c`            | `_task1_<c>.rds`          |
| `sim_task1_rewp.R`    | task1 | gain **only**   | **mean** shift `erp += c`      | `task1:gain plus c`       | `_task1_rewp_<c>.rds`     |
| `sim_task1sd.R`       | task1 | gain and loss   | **SD** add `erp += rnorm(0,c)` | `task1 add stddev c`      | `_task1sd_<c>.rds`        |
| `sim_task1sd_rewp.R`  | task1 | gain only       | **SD** add `erp += rnorm(0,c)` | `task1:rewp add stddev c` | `_task1sd_rewp_<c>.rds`   |
| `sim_task2.R`         | task2 | gain and loss   | mean shift                     | `task2 plus c`            | `_task2_<c>.rds`          |
| `sim_task2_rewp.R`    | task2 | gain only       | mean shift                     | `task2:gain plus c`       | `_task2_rewp_<c>.rds`     |
| `sim_task2sd.R`       | task2 | gain and loss   | SD add                         | `task2 add stddev c`      | `_task2sd_<c>.rds`        |
| `sim_task2sd_rewp.R`  | task2 | gain only       | SD add                         | `task2:rewp add stddev c` | `_task2sd_rewp_<c>.rds`   |

"gain only" = a change to the **RewP itself** (RewP ≈ gain − loss), so those variants are the
directly interpretable ones. "gain and loss" shifts the whole task and is more of a nuisance /
sanity condition.

The two models fit for every dataset (both are location-scale, both have subject random effects):

```r
# event_fit — no task difference allowed
erp   ~ 0 + event + (0 + event | p | subjid)
sigma ~ 0 + event + (0 + event | p | subjid)

# task_fit — allows the effect to differ by task
erp   ~ 0 + event + event:task + (0 + event | p | subjid)
sigma ~ 0 + event + event:task + (0 + event | p | subjid)
```

Sampler settings (identical across variants): 4 chains, `warmup = 3000`, `iter = 3000 + 2000`
(⇒ 2000 post-warmup draws/chain, 8000 total), `threads = threading(6)`, `backend = "cmdstanr"`,
`save_pars(all = TRUE)`, `seed =` the dataset's own seed. With 4 chains × 6 threads the job uses
24 cores — which is exactly `--cpus-per-task=24` in the sbatch wrapper.
**Out:** `data_tib_task1/…` or `data_tib_task2/…`, one `.rds` per (dataset × variant × magnitude),
each carrying `seed`, `change`, `event_fit`, `task_fit`, `event_fit_loo`, `task_fit_loo`.

### Stage 4 — `cluster/compile_sim_data.R` — decide who won, per dataset  *(core)*
**Why:** collapse each fitted pair into a single verdict.
**Runs as:** `Rscript compile_sim_data.R <which_tsk> <which_dataset> <which_rewp> <which_sd>`
(the four selectors pick task 1/2, dataset, gain-only vs. all-events, and SD vs. mean, so the
job gathers exactly the matching `data_tib_task*/data_tib_<d>_*.rds` files).
**Does:** for each file runs `loo_compare(event_fit_loo, task_fit_loo)` and classifies via
`check_loo_comp()`:

- **`equiv`** — models are indistinguishable: `|elpd_diff| ≤ 4`, **or** `|elpd_diff| ≤ 2 × se_diff`.
- **`event`** — the simpler event-only model is decisively better.
- **`task`** — the task-difference model is decisively better ⇒ **the injected effect was detected**.

It also parses the `change` label into tidy columns `task_name`, `rewp_only` (0 = gain&loss,
1 = gain only), `type` (`mean` / `sd`), and `diff` (the magnitude `c`).
**Out:** `data_tib_summaries/data_tib_loo_summ_<tsk>_<dataset><suffix>.rds`, where `<suffix>` ∈
`{"", "_rewp", "_sd", "_rewp_sd"}`, containing the `loo_comp` verdict per row.

### Stage 5 — `local/examine_summaries.R` — power curves & minimum detectable effect  *(core)*
**Why:** aggregate verdicts across the simulated experiments (completeness target: 50 datasets,
seeds 1001–1050) into the actual result.
**Does:** reads **all** of `data_tib_summaries/*.rds`, then for each
`(task_name, rewp_only, type, diff)` computes

```r
power = mean( loo_comp == "task" )   # detection = a decisive 'task' win only; equiv/event/ERROR/LOOCOMP_FAIL all count as 0
```

— the fraction of simulated experiments in which the injected effect was detected. **Only a
decisive `task` win counts as a detection**; `equiv`, `event`, and any failed comparison
(`ERROR` / `LOOCOMP_FAIL`) all score 0. The script also prints a tally of every `loo_comp` value and
warns if any failed comparisons are present, so a numerical failure can't silently shift the power
estimate. This average is taken over **all** summary files present in `data_tib_summaries/`; the
seed-1001–1050 block near the top of the script is a separate completeness check (see the note
below), not a filter on the power calculation. It plots
**sensitivity vs. effect size**, faceted by scope (Gain/Loss vs. Only-Gain) and coloured by task
(Task 1/3 vs. Task 2), with reference lines drawn at 0.90. It then tabulates the **minimum
detectable effect** as the smallest `diff` whose power is ≥ 0.80 **and stays** ≥ 0.80 for every
larger `diff` (`power_mean_out`, `power_sd_out`).

> The plots draw a **0.90** guide line while the tabulated MDE uses a **0.80** threshold — set
> your target explicitly to whichever you intend to report. The `tsk_keep` / `missing` block near
> the top is bookkeeping that checks which (task × scope × type × magnitude × seed) cells were
> actually completed across seeds 1001–1050; it does not affect the power numbers.

---

## 5. The perturbation grid that was actually swept

The batch drivers submitted the magnitude sweep in several waves (each `sbatch_sim_batch*.sh`
loops datasets `START…END` and submits the per-variant jobs with a particular range). The union:

**Mean-shift magnitudes (µV):**

| driver                | range (min → max, step)   |
|-----------------------|---------------------------|
| `sbatch_sim_batch.sh` / `_jmean.sh` | 0.01 → 1, step 0.01 |
| `sbatch_sim_batch2.sh`| 0.51 → 1, step 0.01 (top-up) |
| `sbatch_sim_batch3.sh`| 2.05 → 3, step 0.05       |
| `sbatch_sim_batch4.sh`| 3.05 → 5, step 0.05       |
| `sbatch_sim_batch6.sh`| 5.05 → 7, step 0.05       |

**Added-SD magnitudes (µV):**

| driver                | range (min → max, step)     |
|-----------------------|-----------------------------|
| `sbatch_sim_batch.sh` | 0.00001 → 0.0001, step 0.00001 |
| `sbatch_sim_batch_jsd3.sh` | 0.00021 → 0.0003, step 0.00001 |
| `sbatch_sim_batch_jsd4.sh` | 0.00031 → 0.0004, step 0.00001 |
| `sbatch_sim_batch3.sh`| 0.0102 → 0.015, step 0.0002 |
| `sbatch_sim_batch4.sh`| 0.0152 → 0.025, step 0.0002 |
| `sbatch_sim_batch6.sh`| 0.0252 → 0.04, step 0.0002  |
| `sbatch_sim_batch_jsd.sh` / `_jsd2.sh` | 1 → 3, step 0.01 (large-value exploration) |

You do **not** need to replay every wave. `sbatch_sim_batch.sh` submits all 8 variants and is the
canonical entry point; the other drivers just extend or refine the range where the power curve was
still climbing. Add ranges until each curve of interest saturates near 1.

---

## 6. Priors, seeds, and Slurm resources (quick reference)

**Priors** (identical everywhere models are fit — object `pr_ls`):

```r
set_prior("student_t(10, 0, 5)", class = "b")                         # fixed effects
set_prior("lkj(3)",              class = "L")                         # RE correlation
set_prior("student_t(10, 0, 2)", class = "sd")                        # RE SDs (mean side)
set_prior("student_t(10, 0, 2)", dpar  = "sigma")                     # sigma fixed effects
set_prior("student_t(10, 0, 2)", class = "sd", dpar = "sigma")        # RE SDs (sigma side)
```

**Seeds:** generative model & per-dataset base fits use `seed = 111125`; each simulated dataset
uses `seed = 1000 + n` (datasets 1–100 ⇒ seeds 1001–1100); every Stage-3 fit passes that same
per-dataset seed into `brm(seed = …)`. This makes the whole chain deterministic given the same
software versions.

**Slurm resources (from the `sbatch_*.sh` headers):**

| job type                          | time     | cpus-per-task | mem  |
|-----------------------------------|----------|---------------|------|
| simulation fits (`sbatch_sim_task*.sh`) | 20:00:00 | 24            | 32G  |
| compile (`sbatch_compile_sim_sing.sh`)  | 1:00:00  | 2             | 2G   |
| batch drivers (`sbatch_sim_batch*.sh`, `sbatch_compile_sim_batch.sh`) | 1:00:00 | 2 | 1G |

The per-variant simulation and compile jobs (`sbatch_sim_task*.sh`, `sbatch_compile_sim_sing.sh`)
`module purge`, put `~/miniconda3/condabin` on `PATH`, and run inside the conda env `my_r_env`;
the batch drivers (`sbatch_sim_batch*.sh`, `sbatch_compile_sim_batch.sh`) just loop and `sbatch`.
Failure emails go to `peter.clayson@gmail.com`.

---

## 7. Reproducing it

### 7a. From the simulated datasets (your chosen entry point)

Assumes you already have `data_tib/*.rds`. Everything below is cluster-side except the last step.
Put **all files from `cluster/` into one flat directory** on the cluster (the sbatch scripts call
each other by absolute path — see §8) and place the datasets on fast scratch.

```bash
# 1. Fit event_fit + task_fit for every dataset × variant × magnitude.
#    sbatch_sim_batch.sh submits all 8 variants for datasets START..END.
sbatch sbatch_sim_batch.sh 1 50
#    (extend the magnitude range only where curves haven't saturated:)
sbatch sbatch_sim_batch3.sh 1 50      # mean 2.05–3;  SD 0.0102–0.015
sbatch sbatch_sim_batch4.sh 1 50      # mean 3.05–5;  SD 0.0152–0.025
sbatch sbatch_sim_batch6.sh 1 50      # mean 5.05–7;  SD 0.0252–0.04
#    → fills data_tib_task1/ and data_tib_task2/

# 2. Classify each fitted pair with LOO (task1/task2 × gain-only/all × sd/mean).
sbatch sbatch_compile_sim_batch.sh 1 50
#    → fills data_tib_summaries/
```

```r
# 3. Back on your workstation: copy data_tib_summaries/ down, then
#    edit the two paths at the top of local/examine_summaries.R and run it.
source("local/examine_summaries.R")   # → sensitivity plots + power_mean_out / power_sd_out
```

### 7b. All the way from raw data (optional, full provenance)

```r
source("local/initial_fit.R")        # data/rewp_meanamp_raw.csv        → brm_rewp.rds (+ _loo)
source("local/generate_datasets.R")  # brm_rewp.rds                     → data_tib/*.rds
# (optional) source("local/base_brms.R")     # data_tib/*.rds           → data_tib_base_brms/*
# …then continue with 7a from step 1.
```

### 7c. Alternate / QA compile (not the headline path)
`local/compile_sim_data.R` (and its `…_localtest.R` sibling that loops datasets 1–5) is a second
version of Stage 4 that compares **each** model against a per-dataset *base* model
(`data_tib_base_brms/…_loo.rds`) instead of comparing the two models to each other. It adds a
third "equivalence" criterion and writes a different schema (`event_fit_loo` / `task_fit_loo`
verdict columns rather than a single `loo_comp`). It reads from a local mirror of the cluster
outputs (`sc_FlavorsRewP/…`). It was used for cross-checking; `examine_summaries.R` consumes the
**cluster** compile's `loo_comp`, so use `cluster/compile_sim_data.R` for the reported result.

---

## 8. Paths and settings you must edit

Every script hard-codes absolute paths. Before running, update:

**Cluster scripts**
- In each `cluster/sim_task*.R`: `load_path` (where `data_tib/*.rds` live) and `save_path`
  (`data_tib_task1` / `data_tib_task2`). As shipped these point at
  `/home/fslcollab40/nobackup/autodelete/FlavorsRewP/…` — **`autodelete` scratch is purged
  automatically**, so copy anything you want to keep off it promptly.
- In `cluster/compile_sim_data.R`: `wrkdir` (parent of `data_tib_task1/2`) and `save_path`
  (`data_tib_summaries`).
- In every `cluster/sbatch_*.sh`: the absolute script directory (`/home/fslcollab40/FlavorsRewP/…`),
  the `--output` Slurm log path (create that folder first), the conda env name `my_r_env`, the
  `miniconda3` location, and `--mail-user`. The batch drivers call the per-variant wrappers by
  absolute path, so **keep all cluster scripts in the one directory those paths point to.**

**Local scripts**
- `local/initial_fit.R`: the `read.csv(...)` path to `rewp_meanamp_raw.csv` and `save_path`.
- `local/generate_datasets.R`: `brm_rewp_fileloc` and `save_path` (`data_tib`); the `51:100`
  loop range if you want a different set of datasets.
- `local/base_brms.R`, `local/examine_summaries.R`, `local/compile_sim_data*.R`: `wrkdir` /
  `save_path` / `base_loo_path` at the top.

---

## 9. How to read the result

`examine_summaries.R` produces, for each **task** (Task 1/3, Task 2), **scope** (Only-Gain =
change in the RewP, vs. Gain/Loss = whole-task shift), and **effect type** (mean shift in µV, or
added trial-to-trial SD in µV):

- a **sensitivity curve** — probability of detecting the effect vs. its size; and
- a **minimum detectable effect** — the smallest effect reaching your sensitivity target
  (0.80 in the tabulated output, 0.90 on the plotted guide line).

Because the "detector" is a LOO comparison between a model that allows a task difference and one
that doesn't, the reported number answers the planning question directly: *the smallest RewP
difference (in amplitude, or in variability) the planned multi-site design can reliably tell
apart from no difference.*

---

## 10. Data object schemas (so you know what each `.rds` holds)

- `data/rewp_meanamp_raw.csv` — long, one row per trial: `subjid`, `event`
  (`CorrectFdbk`/`IncorrectFdbk`/`CorrectFdbkFood`), `meanamp` (µV).
- `data_tib/data_tib_<n>.rds` — tibble: `seed`; `raw_sim` (list-col → `subjid, site, task,
  event, erp`).
- `data_tib_task{1,2}/data_tib_<d>_<variant>_<c>.rds` — tibble: `seed`, `change`, `data`,
  `event_fit`, `task_fit`, `event_fit_loo`, `task_fit_loo`.
- `data_tib_summaries/data_tib_loo_summ_<tsk>_<d><suffix>.rds` — tidy tibble: `fnames`, `seed`,
  `change`, `loo_comp` (`equiv`/`event`/`task`), `task_name`, `rewp_only`, `type`, `diff`.
- `brm_rewp.rds` / `brm_rewp_loo.rds` — the fitted generative model and its LOO.

---

*Reproduction package assembled from the final cluster scripts in
`pwranalysis/cluster_scripts` plus the local driver scripts in `pwranalysis/`. The out-of-scope
`run_all_dimdiff_chisquare.sh` (a separate dimensional-difference / chi-square analysis) was
intentionally excluded.*

*One deliberate change from the as-run scripts: `local/examine_summaries.R` now scores **only** a
decisive `task` win as a detection — previously `ERROR` / `LOOCOMP_FAIL` verdicts were counted as
detections, which could inflate power — and it prints a tally of `loo_comp` values (with a warning
if any comparisons failed) so failures stay visible instead of silently moving the estimate.*
