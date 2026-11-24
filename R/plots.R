save_chart <- function(path, draw) {
  png(path, width = 1450, height = 820, res = 145)
  on.exit(dev.off())
  draw()
}

plot_bouts <- function(groups) {
  old <- par(mar = c(5, 5, 4, 2))
  on.exit(par(old))
  positions <- c(0.9, 1.9, 1.1, 2.1)
  colors <- rep(c("#007D88", "#BA562C"), each = 2)
  plot(positions, groups$median, pch = 19, col = colors, cex = 1.3,
       xaxt = "n", xlim = c(0.65, 2.35), ylim = c(0, max(groups$upper) * 1.1),
       xlab = "Survey year", ylab = "Expected feeding bouts per feeding observation",
       main = "Small fish at Ashmore Reef", bty = "l")
  axis(1, at = 1:2, labels = c("2004", "2016"))
  segments(positions, groups$lower, positions, groups$upper, col = colors, lwd = 2)
  points(positions, groups$median, pch = 19, col = colors, cex = 1.3)
  legend("topright", c("Shark absent", "Shark present"), col = unique(colors),
         pch = 19, bty = "n")
  mtext("Posterior medians and 95% credible intervals for a video with random effect zero",
        side = 3, line = 0.4, cex = 0.8)
}

plot_effort <- function(summary) {
  old <- par(mar = c(5, 5, 4, 2))
  on.exit(par(old))
  equal <- summary[summary$scored_per_year == 144, ]
  colors <- c("#477AAA", "#007D88", "#BA562C")
  plot(NA, xlim = c(0.8, 3.2), ylim = c(0, 1), xaxt = "n", yaxt = "n",
       xlab = "Videos per year x observations per video",
       ylab = "Positive year effect detected",
       main = "Where should 144 observations per year go?", bty = "l")
  axis(1, at = 1:3, labels = c("12 x 12", "24 x 6", "48 x 3"))
  axis(2, at = seq(0, 1, 0.2), labels = paste0(seq(0, 100, 20), "%"), las = 1)
  for (i in seq_along(colors)) {
    rows <- equal[equal$video_sd == sort(unique(equal$video_sd))[i], ]
    rows <- rows[order(rows$videos), ]
    lines(1:3, rows$power, type = "b", pch = 19, lwd = 2, col = colors[i])
  }
  legend("topleft", paste("Video log-SD", c(0.15, 0.45, 0.75)), col = colors,
         lty = 1, pch = 19, bty = "n")
}

plot_grid <- function(summary) {
  old <- par(mfrow = c(1, 3), mar = c(5, 4, 3, 1), oma = c(0, 0, 2, 0))
  on.exit(par(old))
  colors <- c("#477AAA", "#007D88", "#BA562C")
  for (sigma in sort(unique(summary$video_sd))) {
    plot(NA, xlim = c(1, 3), ylim = range(summary$median_width_log), xaxt = "n",
         xlab = "Videos per year", ylab = "Median 95% interval width (log ratio)",
         main = paste("Video log-SD", sigma), bty = "l")
    axis(1, at = 1:3, labels = c(12, 24, 48))
    for (i in seq_along(colors)) {
      rows <- summary[summary$video_sd == sigma &
                      summary$scored_per_video == c(3, 6, 12)[i], ]
      lines(1:3, rows$median_width_log[order(rows$videos)],
            type = "b", pch = 19, lwd = 2, col = colors[i])
    }
    if (sigma == min(summary$video_sd)) {
      legend("topright", paste(c(3, 6, 12), "obs/video"), col = colors,
             pch = 19, lty = 1, bty = "n", cex = 0.8)
    }
  }
  mtext("Precision across survey designs", outer = TRUE, line = 0.2, font = 2)
}
