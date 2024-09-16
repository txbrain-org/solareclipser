proj_root <- dirname(dirname(getwd()))
solar_output_dir <- file.path(proj_root, "tests/output/solar")
solar_input_dir <- file.path(proj_root, "tests/input/solar")
pedigree_fpath <- file.path(solar_input_dir, "HCP_imputed_filtered_ped.csv")
phenotypes_fpath <- file.path(solar_input_dir, "HCP_WM_ave_norm.csv")

#  Failure (test-SolarFiles.R:24:3): SolarFiles$set_polygenic_trait_d()
#  sf$private$.polygenic$trait_d not equal to "CC".
#  target is NULL, current is character
#
#  Failure (test-SolarFiles.R:42:3): SolarFiles$get_polygenic_trait_d_files()
#  `trait_d_files` inherits from `'character'` not `'character'`.

test_that("SolarFiles$new()", {
  sf <- SolarFiles$new()
  expect_is(sf, "SolarFiles")
})

test_that("SolarFiles$set_polygenic_trait_d()", {
  sc <- SolarCommand$new(save_output_dir = solar_output_dir)
  sc$load(obj = "pedigree",
          fpath = pedigree_fpath,
          cond = "-t 0")
  sc$load(obj = "phenotypes",
          fpath = phenotypes_fpath)
  sc$trait("CC")$polygenic()
  sc$run()

  sf <- SolarFiles$new(path_to_files = solar_output_dir)
  sf$set_polygenic_trait_d(trait_d = "CC")
  pf <- sf$get_polygenic_files()
  expect_is(pf, "list")
  expect_equal(pf$trait_d, "CC")
})
