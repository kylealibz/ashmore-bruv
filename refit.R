# Optional fresh fit. Requires brms, cmdstanr, and a working CmdStan toolchain.
# Model and archived priors match the source QMD and saved posterior object.
source("R/reproduction.R")
paths <- source_files()
dat <- read.csv(paths[1])
dat <- subset(dat, size_class == "Small" & bite > 0 & sec_feeding > 0)
dat$year <- factor(dat$year, levels = c(2004, 2016))
dir.create("results", showWarnings = FALSE)
brms::brm(bout ~ year * shark_in_video + (1 | video),
          data = dat, family = poisson(link = "log"),
          prior = c(brms::set_prior("student_t(3, 0.7, 2.5)", class = "Intercept"),
                    brms::set_prior("student_t(3, 0, 2.5)", class = "sd")),
          iter = 4000, warmup = 2000, chains = 4, cores = 4, seed = 123,
          control = list(adapt_delta = 0.99, max_treedepth = 16),
          backend = "cmdstanr", threads = brms::threading(2, static = TRUE),
          file = "results/fresh-bouts-fit", file_refit = "on_change")
