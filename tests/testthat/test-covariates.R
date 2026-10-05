test_that("covariate specs expand as in SOLAR", {
  solar_reset()
  on.exit(solar_reset(), add = TRUE)
  expect_identical(solar_select_covariates("age"), "age")
  expect_identical(solar_select_covariates("age^1,2,3"), c("age", "age^2", "age^3"))
  expect_identical(solar_select_covariates("age#sex"), c("age", "sex", "age*sex"))
  expect_identical(solar_select_covariates("age^1,2#sex"),
                   c("age", "sex", "age*sex", "age^2", "age^2*sex"))
  expect_identical(solar_select_covariates("age^1,2*sex"), c("age*sex", "age^2*sex"))
  expect_identical(solar_select_covariates("a*b^2*c"), "a*b^2*c")
  # Several per element, separated by spaces; repeats are dropped
  expect_identical(solar_select_covariates(c("age sex", "age", "age#sex")),
                   c("age", "sex", "age*sex"))
  # No covariates clears them
  expect_identical(solar_select_covariates(), character())
})

test_that("invalid covariate specs are errors and keep the old covariates", {
  solar_reset()
  on.exit(solar_reset(), add = TRUE)
  solar_select_covariates("age")
  expect_error(solar_select_covariates("age*sex#bmi"), "Pound and Star")
  expect_error(solar_select_covariates("age#sex#bmi"), "only allowed with 2 variables")
  expect_error(solar_select_covariates("age^1,2*sex*bmi"), "only allowed with 2 variables")
  expect_error(solar_select_covariates("age*sex^1,2"), "comma shortcut only allowed for first")
  expect_error(solar_select_covariates("age^x"), "Invalid exponent")
  expect_error(solar_select_covariates("age^1,3"), "Invalid exponent")
  expect_error(solar_select_covariates("age*"), "Missing covariate variable name")
  expect_error(solar_select_covariates("age(CC)"), "not supported")
  expect_error(solar_select_covariates(NA_character_), "NA")
  expect_identical(solar_select_covariates("age"), "age")
})

test_that("run_fphi adjusts for covariates", {
  dir <- tempfile("fphi_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  data("pedigree", package = "solareclipser")
  data("phenotypes", package = "solareclipser")
  ped_csv <- file.path(dir, "ped.csv")
  phen_csv <- file.path(dir, "phen.csv")
  write.csv(pedigree, ped_csv, row.names = FALSE, quote = FALSE)
  write_test_covariates(phenotypes, phen_csv)

  solar_reset()
  on.exit(solar_reset(), add = TRUE)
  solar_load_pedigree(ped_csv, threshold = 0, output_dir = dir)
  solar_load_phenotype(phen_csv)
  solar_select_trait("CC")
  # Variables are checked against the phenotype columns, ignoring case
  expect_error(solar_select_covariates("age*bmi"), "'bmi' not found")
  expect_identical(solar_select_covariates("AGE sex"), c("AGE", "sex"))

  expect_output(res <- solar_run_fphi(file.path(dir, "CC"), format = "csv"), "^Trait,h2r")
  # Individuals missing age are left out
  expect_identical(res$results$n_subjects, 976L)
  expect_identical(res$parameters$parameter, c("AGE", "sex", "mean", "e2", "h2r", "sd"))
  expect_true(all(res$parameters$se > 0))
  # The csv parameters table carries the same rows
  csv <- read.csv(file.path(dir, "CC_parameters.out"))
  expect_equal(unname(as.list(csv)), unname(as.list(res$parameters)))

  # Clearing the covariates gives the unadjusted analysis of all 999 again
  solar_select_covariates()
  res <- solar_run_fphi(file.path(dir, "CC"))
  expect_identical(res$results$n_subjects, 999L)
  expect_identical(res$parameters$parameter, c("mean", "e2", "h2r", "sd"))
})
