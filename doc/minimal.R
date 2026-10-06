## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)


## ----setup--------------------------------------------------------------------
library(solareclipser)

## Load the example data
data("pedigree", package = "solareclipser")
data("phenotypes", package = "solareclipser")

## Write temporary CSV files
pedigree_tmp_csv <- tempfile(fileext = ".csv")
write.csv(pedigree, pedigree_tmp_csv, row.names = FALSE, quote = FALSE)
phenotypes_tmp_csv <- tempfile(fileext = ".csv")
write.csv(phenotypes, phenotypes_tmp_csv, row.names = FALSE, quote = FALSE)

## Create temporary output directory
output_dir <- tempfile("fphi_")
dir.create(output_dir)
trait <- "CC"
output_basename <- file.path(output_dir, trait)

## Each step signals an R error if it fails
solar_load_pedigree(pedigree_tmp_csv, threshold = 0.0, output_dir = output_dir)
solar_load_phenotype(phenotypes_tmp_csv)
solar_select_trait(trait)

## Optionally adjust for covariates in the phenotype file, in SOLAR's syntax
## (the example data has none), e.g. age, age^2, sex and their interactions:
## solar_select_covariates("age^1,2#sex")

## The results come back as a list of two data frames
res <- solar_run_fphi(output_basename)
res$results
res$parameters

## To also print the results as text and write them to files, list formats:
## "csv", "tsv", "json", "yaml", or "solar" (the original SOLAR-Eclipse
## summary block, for diffing against its output). For example
## solar_run_fphi(output_basename, format = "csv") also writes
## <output_basename>_fphi_results.out and _parameters.out.

