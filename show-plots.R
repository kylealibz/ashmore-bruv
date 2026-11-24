# Open the RStudio project and source this file to draw all three charts.
source("R/plots.R")
plot_bouts(read.csv("results/bout-means.csv"))
design_results <- read.csv("results/simulation-summary.csv")
plot_effort(design_results)
plot_grid(design_results)
