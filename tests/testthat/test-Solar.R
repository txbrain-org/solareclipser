library(testthat)

proj_root <- dirname(dirname(getwd()))
solar_output_dir <- file.path(proj_root, "tests/output/solar")
solar_input_dir <- file.path(proj_root, "tests/input/solar")
pedigree_fpath <- file.path(solar_input_dir, "HCP_imputed_filtered_ped.csv")
phenotypes_fpath <- file.path(solar_input_dir, "HCP_WM_ave_norm.csv")
c_evd_out_fbn <- file.path("CC_evd")

test_that("run() - polygenic", {
  solar <- Solar$new(save_output_dir = solar_output_dir)
  solar$load(obj = "pedigree",
             fpath = pedigree_fpath,
             cond = "-t 0")
  solar$load(obj = "phenotypes",
             fpath = phenotypes_fpath)
  solar$trait("CC")
  solar$polygenic()
  solar$run()
  expect_true(solar$get_run_rc() == 0)
})

test_that("run() - fphi)", {
  cc_evd_out_all_fpaths <- c(
    file.path(solar_output_dir, "CC_evd.eigenvalues"),
    file.path(solar_output_dir, "CC_evd.eigenvectors"),
    file.path(solar_output_dir, "CC_evd.ids"),
    file.path(solar_output_dir, "CC_evd.notes")
  )

  solar <- Solar$new(save_output_dir = solar_output_dir)
  solar$load(obj = "pedigree",
             fpath = pedigree_fpath,
             cond = "-t 0")
  solar$load(obj = "phenotypes",
             fpath = phenotypes_fpath)
  solar$trait("CC")
  solar$create_evd_data(output_fbasename = c_evd_out_fbn)
  solar$fphi(evd_data = c_evd_out_fbn)
  solar$run()

  expect_true(solar$get_run_rc() == 0)
  for (fpath in cc_evd_out_all_fpaths) {
    expect_true(file.exists(fpath))
    expect_true(file.size(fpath) > 0)
  }
})
