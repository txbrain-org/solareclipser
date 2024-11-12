library(testthat)
library(withr)

#' Return a list of settings for the testbench
#' @param dir The output directory to be used by the returned settings
#' @return A list of settings
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

#' Set common variables used test_that() tests
#' Returns: list(settings, pedigree_fpath, phenotypes_fpath)
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
