

test_that("SolarCommand$new()", {
  sc <- SolarCommand$new()
  expect_is(sc, "SolarCommand")
})

#sc <- SolarCommand$new()
#sc$load(obj = "pedigree",
#        fpath = "tests/debug/solar/input/HCP_imputed_filtered_ped.csv",
#        cond = "-t 0")
#sc$load(obj = "phenotypes",
#        fpath = "tests/debug/solar/input/HCP_WM_ave_norm.csv")
#sc$trait("CC")$polygenic()
#sc$run()