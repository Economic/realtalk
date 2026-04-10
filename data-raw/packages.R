## library() calls go here
library(targets)
library(tarchetypes)

# conflicts and other options
library(conflicted)
conflicts_prefer(dplyr::filter(), .quiet = TRUE)
options(usethis.quiet = TRUE, tidyverse.quiet = TRUE)

# packages for this analysis
library(tidyverse)
library(readxl)
library(blsR)
library(tsibble)
