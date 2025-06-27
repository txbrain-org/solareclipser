library(testthat)
library(withr)

#' Return a list of settings for the testbench
#'
#' @description
#' Constructs a `settings` list used for testing, setting the output directory and toggling other options (TCL logging, output redirection).
#'
#' @param dir The output directory to be used in the returned settings list.
#'
#' @return A named list containing testbench settings with structure `list(output = list(dir = ..., ...))`.
tb_settings_set_output_dir <- function(dir) {
  settings <- list(
    output = list(
      dir = dir,
      tcl = FALSE,
      stdout_and_stderr = FALSE
    )
  )
  return(settings)
}

#' Initialize common testbench configuration and input file paths
#'
#' @description
#' Prepares a list of settings and input file paths for use in `test_that()` test cases. Optionally allows skipping settings if `tmp = TRUE`.
#'
#' @param tmp Logical. If `TRUE`, skip populating the settings list (used for temporary file-based tests).
#'
#' @return A named list with elements:
#' - `settings`: a list of testbench settings (or empty if `tmp = TRUE`)
#' - `pedigree_fpath`: file path to the pedigree CSV
#' - `phenotypes_fpath`: file path to the phenotype CSV
testbench_init <- function(tmp = FALSE) {
  proj_root <- dirname(dirname(getwd()))
  solar_input_dir <- file.path(proj_root, "tests/input/solar")
  pedigree_fpath <- file.path(solar_input_dir, "HCP_imputed_filtered_ped.csv")
  phenotypes_fpath <- file.path(solar_input_dir, "HCP_WM_ave_norm.csv")

  tb_settings <- list()
  if (isFALSE(tmp)) {
    solar_output_dir <- file.path(proj_root, "tests/output/solar")
    tb_settings <- tb_settings_set_output_dir(solar_output_dir)
  }

  # Return the settings and file paths
  return(list(
    settings = tb_settings,
    pedigree_fpath = pedigree_fpath,
    phenotypes_fpath = phenotypes_fpath
  ))
}
