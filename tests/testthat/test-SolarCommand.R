proj_root <- dirname(dirname(getwd()))
solar_output_dir <- file.path(proj_root, "tests/output/solar")
solar_input_dir <- file.path(proj_root, "tests/input/solar")
pedigree_fpath <- file.path(solar_input_dir, "HCP_imputed_filtered_ped.csv")
phenotypes_fpath <- file.path(solar_input_dir, "HCP_WM_ave_norm.csv")
c_evd_out_fbn <- file.path("CC_evd")

test_that("SolarCommand$new()", {
  sc <- SolarCommand$new()
  expect_is(sc, "SolarCommand")
})

# TODO:  load()
# TODO:  trait()
# TODO:  create_evd_data() - can't be checked for files befor run()
#     - [ ] check files created against known correct file

# TODO:  run() - polygenic
test_that("run() - polygenic)", {
  proj_root <- dirname(dirname(getwd()))
  print(proj_root)

  cc_evd_out_all_fpaths <- c(
    file.path(solar_output_dir, "CC_evd.eigenvalues"),
    file.path(solar_output_dir, "CC_evd.eigenvectors"),
    file.path(solar_output_dir, "CC_evd.ids"),
    file.path(solar_output_dir, "CC_evd.notes")
  )

  sc <- SolarCommand$new(save_output_dir = solar_output_dir)
  sc$load(obj = "pedigree",
          fpath = pedigree_fpath,
          cond = "-t 0")
  sc$load(obj = "phenotypes",
          fpath = phenotypes_fpath)
  sc$trait("CC")
  sc$polygenic()
  sc$run()

  for (fpath in cc_evd_out_all_fpaths) {
    expect_true(file.exists(fpath))
    expect_true(file.size(fpath) > 0)
  }
})

# TODO:  run() - fphi
test_that("run() - fphi)", {
  proj_root <- dirname(dirname(getwd()))
  print(proj_root)

  cc_evd_out_all_fpaths <- c(
    file.path(solar_output_dir, "CC_evd.eigenvalues"),
    file.path(solar_output_dir, "CC_evd.eigenvectors"),
    file.path(solar_output_dir, "CC_evd.ids"),
    file.path(solar_output_dir, "CC_evd.notes")
  )

  sc <- SolarCommand$new(save_output_dir = solar_output_dir)
  sc$load(obj = "pedigree",
          fpath = pedigree_fpath,
          cond = "-t 0")
  sc$load(obj = "phenotypes",
          fpath = phenotypes_fpath)
  sc$trait("CC")
  sc$create_evd_data(output_fbasename = c_evd_out_fbn)
  sc$fphi(evd_data = c_evd_out_fbn)
  sc$run()

  for (fpath in cc_evd_out_all_fpaths) {
    expect_true(file.exists(fpath))
    expect_true(file.size(fpath) > 0)
  }
})
