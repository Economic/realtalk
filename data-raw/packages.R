## library() calls go here
library(targets)
library(tarchetypes)

# conflicts
library(conflicted)
conflict_prefer("filter", "dplyr", quiet = TRUE)

# packages for this analysis
suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
})
