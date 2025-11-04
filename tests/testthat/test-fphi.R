test_that("run_fphi executes with example data from package: threshold 0.0", {
  # Load example data from package
  data("pedigree", package = "solareclipser")
  data("phenotypes", package = "solareclipser")

  # Write temporary CSV files
  pedigree_tmp_csv <- tempfile(fileext = ".csv")
  write.csv(pedigree, pedigree_tmp_csv, row.names = FALSE, quote = FALSE)
  phenotypes_tmp_csv <- tempfile(fileext = ".csv")
  write.csv(phenotypes, phenotypes_tmp_csv, row.names = FALSE, quote = FALSE)

  # Create temporary output directory
  output_dir <- tempfile("fphi_")
  dir.create(output_dir)
  trait <- "CC"
  output_basename <- file.path(output_dir, trait)

  rc <- solar_load_pedigree(pedigree_tmp_csv, threshold = 0.0, output_dir = output_dir)
  expect_true(rc == 0)
  
  rc <- solar_load_phenotype(phenotypes_tmp_csv)
  expect_true(rc == 0)
  
  rc <- solar_select_trait(trait)
  expect_true(rc == 0)
  
  rc <- solar_run_fphi(output_basename)
  expect_true(rc == 0)

  expect_true(file.exists(paste0(output_basename, ".ids")))
  expect_true(file.exists(paste0(output_basename, ".eigenvalues")))
  expect_true(file.exists(paste0(output_basename, ".eigenvectors")))
  expect_true(file.exists(paste0(output_basename, ".notes")))
  expect_true(file.exists(paste0(output_basename, "_fphi_results.out")))
  expect_true(file.exists(paste0(output_basename, "_parameters.out")))
  expect_true(file.exists(file.path(output_dir, "pedigree.info")))
  expect_true(file.exists(file.path(output_dir, "pedindex.cde")))
  expect_true(file.exists(file.path(output_dir, "pedindex.out")))
  expect_true(file.exists(file.path(output_dir, "phi2.gz")))

  ## Clean up
  unlink(output_dir, recursive = TRUE)
  unlink(pedigree_tmp_csv)
  unlink(phenotypes_tmp_csv)
})
