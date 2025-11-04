library(readr)

## the data is in data-raw/*.csv files
phenotypes <- read_csv("data-raw/HCP_WM_ave_norm.csv", show_col_types = FALSE)
pedigree <- read_csv("data-raw/HCP_imputed_filtered_ped.csv", show_col_types = FALSE)

usethis::use_data(phenotypes, pedigree, overwrite = TRUE)
