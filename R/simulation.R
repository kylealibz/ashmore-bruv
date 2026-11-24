# The expected video mean is two bouts in 2004 and 2 * ratio in 2016.
# Center the lognormal multiplier so the marginal year means stay fixed
# when the between-video standard deviation changes.
simulate_designs <- function(reps = 1000L, ratio = 1.35, seed = 26942L) {
  set.seed(seed)
  designs <- expand.grid(videos = c(12L, 24L, 48L),
                         scored_per_video = c(3L, 6L, 12L),
                         video_sd = c(0.15, 0.45, 0.75))
  summaries <- vector("list", nrow(designs))
  all <- vector("list", nrow(designs))
  for (i in seq_len(nrow(designs))) {
    design <- designs[i, , drop = FALSE]
    rownames(design) <- NULL
    n <- design$videos
    m <- design$scored_per_video
    sigma <- design$video_sd
    run <- function() {
      v <- matrix(rnorm(2L * n, -sigma^2 / 2, sigma), nrow = n)
      lambda <- sweep(exp(v), 2L, c(2, 2 * ratio), "*")
      # The sum of conditionally independent Poisson counts is Poisson.
      totals <- matrix(rpois(2L * n, m * lambda), nrow = n)
      video_mean <- totals / m
      means <- colMeans(video_mean)
      # Delta-method variance of the log of each year mean, treating
      # videos as the independent units. Welch-Satterthwaite t interval.
      if (any(means == 0)) return(c(estimate = NA, lower = NA, upper = NA))
      vars <- apply(video_mean, 2L, var) / (n * means^2)
      estimate <- log(means[2] / means[1])
      denom <- sum(vars^2 / (n - 1L))
      if (denom <= 0) return(c(estimate = NA, lower = NA, upper = NA))
      half_width <- qt(0.975, df = sum(vars)^2 / denom) * sqrt(sum(vars))
      c(estimate = estimate, lower = estimate - half_width, upper = estimate + half_width)
    }
    fit <- as.data.frame(t(replicate(reps, run())))
    keep <- is.finite(fit$estimate)
    coverage <- with(fit[keep, ], mean(lower <= log(ratio) & upper >= log(ratio)))
    detection <- mean(fit$lower[keep] > 0)
    summaries[[i]] <- data.frame(design, scored_per_year = n * m, truth = ratio,
      attempted = reps, usable = sum(keep), bias_log = mean(fit$estimate[keep] - log(ratio)),
      rmse_log = sqrt(mean((fit$estimate[keep] - log(ratio))^2)),
      coverage = coverage, power = detection,
      power_mcse = sqrt(detection * (1 - detection) / sum(keep)),
      median_width_log = median(fit$upper[keep] - fit$lower[keep]))
    all[[i]] <- data.frame(design, replicate = seq_len(reps), truth_log = log(ratio), fit)
  }
  list(replicates = do.call(rbind, all), summary = do.call(rbind, summaries))
}

