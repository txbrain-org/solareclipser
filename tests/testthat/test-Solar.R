library(testthat)

proj_root <- dirname(dirname(getwd()))
solar_output_dir <- file.path(proj_root, "tests/output/solar")
solar_input_dir <- file.path(proj_root, "tests/input/solar")
pedigree_fpath <- file.path(solar_input_dir, "HCP_imputed_filtered_ped.csv")
phenotypes_fpath <- file.path(solar_input_dir, "HCP_WM_ave_norm.csv")
c_evd_out_fbn <- file.path("CC_evd")

settings <- list(
  output = list(
    dir = solar_output_dir,
    tcl = FALSE,
    stdout_and_stderr = FALSE
  )
)

test_that("run() - polygenic", {
  solar <- Solar$new(settings = settings)
  solar$cmd$load(obj = "pedigree",
             fpath = pedigree_fpath,
             cond = "-t 0")
  solar$cmd$load(obj = "phenotypes",
             fpath = phenotypes_fpath)
  solar$cmd$trait("CC")
  solar$cmd$polygenic()
  solar$run()

  expect_false(is.null(solar$get_run_rc()))
})

test_that("run() - fphi)", {
  cc_evd_out_all_fpaths <- c(
    file.path(settings$output$dir, "CC_evd.eigenvalues"),
    file.path(settings$output$dir, "CC_evd.eigenvectors"),
    file.path(settings$output$dir, "CC_evd.ids"),
    file.path(settings$output$dir, "CC_evd.notes")
  )

  solar <- Solar$new(settings = settings)
  solar$cmd$load(obj = "pedigree",
             fpath = pedigree_fpath,
             cond = "-t 0")
  solar$cmd$load(obj = "phenotypes",
             fpath = phenotypes_fpath)
  solar$cmd$trait("CC")
  solar$cmd$create_evd_data(output_fbasename = c_evd_out_fbn)
  solar$cmd$fphi(evd_data = c_evd_out_fbn)
  solar$run()

  expect_false(is.null(solar$get_run_rc()))
  for (fpath in cc_evd_out_all_fpaths) {
    expect_true(file.exists(fpath))
    expect_true(file.size(fpath) > 0)
  }
})
