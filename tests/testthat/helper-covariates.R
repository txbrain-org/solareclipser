# Deterministic covariates for the bundled phenotypes, which have none:
# sex 1/2 by ID parity, age 22-36 from the ID, and age missing for every
# 50th ID (24 individuals). dev/solar-reference.sh sources this file to give
# the original SOLAR the same phenotype file.
add_test_covariates <- function(phenotypes) {
  phenotypes <- as.data.frame(phenotypes)
  phenotypes$sex <- ifelse(phenotypes$ID %% 2 == 0, 1, 2)
  phenotypes$age <- 22 + phenotypes$ID %% 15
  phenotypes$age[phenotypes$ID %% 50 == 0] <- NA
  phenotypes
}

# Write `phenotypes` with the test covariates to a CSV for solar_load_phenotype()
write_test_covariates <- function(phenotypes, file) {
  write.csv(add_test_covariates(phenotypes), file, row.names = FALSE, quote = FALSE, na = "")
}
