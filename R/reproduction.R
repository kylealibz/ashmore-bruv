source_files <- function() {
  revision <- "03bbfc5e30f8fe64295c1d03c5598fefe2bbc82f"
  root <- paste0("https://raw.githubusercontent.com/andieich/Ashmore_behaviour/", revision)
  paths <- c("data/clean/clean_data.csv", "models/fit_bouts_S.rds")
  dir.create("data/cache", recursive = TRUE, showWarnings = FALSE)
  local <- file.path("data/cache", basename(paths))
  for (i in seq_along(local)) {
    if (!file.exists(local[i])) {
      temporary <- tempfile(tmpdir = "data/cache")
      status <- download.file(paste(root, paths[i], sep = "/"), temporary,
                              mode = "wb", quiet = TRUE)
      if (status != 0 || !file.rename(temporary, local[i])) {
        stop("Could not cache ", paths[i])
      }
    }
  }
  local
}

interval <- function(x) {
  unname(quantile(x, c(0.025, 0.5, 0.975)))
}

summarize_draws <- function(x) {
  limits <- interval(x)
  data.frame(median = limits[2], lower = limits[1], upper = limits[3])
}

reproduce_bouts <- function() {
  paths <- source_files()
  all <- read.csv(paths[1])
  cols <- c("bout", "year", "shark_in_video", "video")
  use <- with(all, !is.na(size_class) & size_class == "Small" &
                !is.na(bite) & bite > 0 & !is.na(sec_feeding) & sec_feeding > 0)
  dat <- all[use, cols]
  archived <- readRDS(paths[2])
  model_data <- archived$data[, cols]
  stopifnot(nrow(dat) == 106L, length(unique(dat$video)) == 16L,
            all(vapply(cols, function(key) {
              identical(as.character(dat[[key]]), as.character(model_data[[key]]))
            }, logical(1))))

  # Read the serialized stanfit payload directly. No Stan runtime is needed
  # to summarize draws from the already fitted model.
  sampler <- attr(archived$fit, "sim")
  terms <- c("b_Intercept", "b_year2016", "b_shark_in_videopresent",
             "b_year2016:shark_in_videopresent", "sd_video__Intercept")
  draws <- do.call(rbind, lapply(seq_along(sampler$samples), function(i) {
    which <- seq.int(sampler$warmup2[i] + 1L, sampler$n_save[i])
    do.call(cbind, lapply(sampler$samples[[i]][terms], function(x) x[which]))
  }))
  stopifnot(nrow(draws) == 8000L, all(is.finite(draws)))
  cells <- expand.grid(year = c(2004L, 2016L),
                       shark_in_video = c("absent", "present"),
                       stringsAsFactors = FALSE)
  eta <- with(cells, cbind(1, year == 2016, shark_in_video == "present",
                          year == 2016 & shark_in_video == "present"))
  expected <- exp(draws[, terms[1:4]] %*% t(eta))
  groups <- cbind(cells, do.call(rbind, lapply(seq_len(ncol(expected)), function(i) {
    summarize_draws(expected[, i])
  })))
  contrast_draws <- list(
    "2016 / 2004, shark absent" = expected[, 2] / expected[, 1],
    "2016 / 2004, shark present" = expected[, 4] / expected[, 3],
    "Shark present / absent, 2004" = expected[, 3] / expected[, 1],
    "Shark present / absent, 2016" = expected[, 4] / expected[, 2]
  )
  contrasts <- do.call(rbind, lapply(names(contrast_draws), function(label) {
    value <- contrast_draws[[label]]
    data.frame(contrast = label, summarize_draws(value), probability_above_one = mean(value > 1))
  }))
  sample <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
    selected <- dat[dat$year == cells$year[i] &
                      dat$shark_in_video == cells$shark_in_video[i], ]
    data.frame(cells[i, ], observations = nrow(selected),
               videos = length(unique(selected$video)), raw_mean = mean(selected$bout))
  }))
  list(groups = groups, contrasts = contrasts, sample = sample,
       video_sd = summarize_draws(draws[, terms[5]]))
}
