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

test_that("run_fphi executes with example data from package: threshold 0.05", {
  # At this threshold the kinship matrix splits into 609 families, and the
  # eigenvectors include subnormal values (e.g. -6.0276e-322) that fphi must
  # read back.
  data("pedigree", package = "solareclipser")
  data("phenotypes", package = "solareclipser")

  pedigree_tmp_csv <- tempfile(fileext = ".csv")
  write.csv(pedigree, pedigree_tmp_csv, row.names = FALSE, quote = FALSE)
  phenotypes_tmp_csv <- tempfile(fileext = ".csv")
  write.csv(phenotypes, phenotypes_tmp_csv, row.names = FALSE, quote = FALSE)

  output_dir <- tempfile("fphi_")
  dir.create(output_dir)
  trait <- "CC"
  output_basename <- file.path(output_dir, trait)

  expect_equal(solar_load_pedigree(pedigree_tmp_csv, threshold = 0.05, output_dir = output_dir), 0)
  expect_equal(solar_load_phenotype(phenotypes_tmp_csv), 0)
  expect_equal(solar_select_trait(trait), 0)
  expect_equal(solar_run_fphi(output_basename), 0)

  expect_true(file.exists(paste0(output_basename, "_fphi_results.out")))
  expect_true(file.exists(paste0(output_basename, "_parameters.out")))

  solar_reset()
  unlink(output_dir, recursive = TRUE)
  unlink(pedigree_tmp_csv)
  unlink(phenotypes_tmp_csv)
})

# Runs the threshold 0 pipeline for trait CC in `dir`; returns rc and stdout
run_cc <- function(dir, ...) {
  data("pedigree", package = "solareclipser")
  data("phenotypes", package = "solareclipser")
  ped_csv <- file.path(dir, "ped.csv")
  phen_csv <- file.path(dir, "phen.csv")
  write.csv(pedigree, ped_csv, row.names = FALSE, quote = FALSE)
  write.csv(phenotypes, phen_csv, row.names = FALSE, quote = FALSE)

  solar_reset()
  stopifnot(solar_load_pedigree(ped_csv, threshold = 0.0, output_dir = dir) == 0,
            solar_load_phenotype(phen_csv) == 0,
            solar_select_trait("CC") == 0)
  rc <- NULL
  out <- capture.output(rc <- solar_run_fphi(file.path(dir, "CC"), ...))
  list(rc = rc, out = out)
}

test_that("run_fphi writes every output format with the same values", {
  dir <- tempfile("fphi_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  res <- run_cc(dir, format = c("csv", "tsv", "json", "yaml", "solar"))
  expect_equal(res$rc, 0)
  base <- file.path(dir, "CC")

  csv <- read.csv(paste0(base, "_fphi_results.out"))
  tsv <- read.delim(paste0(base, "_fphi_results.tsv"))
  expect_equal(tsv, csv)
  expect_equal(read.delim(paste0(base, "_parameters.tsv")),
               read.csv(paste0(base, "_parameters.out")))
  h2r <- csv$h2r
  expect_gt(h2r, 0.9)
  # Null model is trait minus its mean, as in SOLAR (dev/doc/solar-threshold-0.out)
  expect_equal(csv$sporadic_loglik, -487.520945344, tolerance = 1e-11)

  skip_if_not_installed("jsonlite")
  json <- jsonlite::fromJSON(paste0(base, "_fphi.json"))
  expect_identical(json$h2r, h2r)
  expect_identical(json$n_subjects, csv$n_subjects)
  expect_equal(json$parameters$name, c("mean", "e2", "h2r", "sd"))

  skip_if_not_installed("yaml")
  yml <- yaml::read_yaml(paste0(base, "_fphi.yaml"))
  expect_identical(yml$h2r, h2r)
  expect_true(yml$significant)

  solar <- readLines(paste0(base, "_fphi.solar.out"))
  expect_match(solar[2], "Fast Permutation Heritability Inference \\(FPHI\\) Summary of Results")
  expect_match(solar, "^  Trait:   CC H2r = 0\\.934443\\d* SE = .*  Individuals:  999$", all = FALSE)
  expect_match(solar, "^       h2r {6}0\\.934443\\d{6} {5}0\\.0104086\\d+$", all = FALSE)

  # stdout carries each format in turn, starting with the csv tables
  expect_equal(res$out[1], "Trait,h2r,SE,loglik,sporadic_loglik,p_value,n_subjects")
  expect_true(any(solar[1] == res$out))
  solar_reset()
})

test_that("run_fphi with write_files = FALSE only prints results", {
  dir <- tempfile("fphi_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  res <- run_cc(dir, format = "json", write_files = FALSE)
  expect_equal(res$rc, 0)
  expect_false(file.exists(file.path(dir, "CC_fphi.json")))
  expect_false(file.exists(file.path(dir, "CC_fphi_results.out")))

  skip_if_not_installed("jsonlite")
  expect_gt(jsonlite::fromJSON(paste(res$out, collapse = "\n"))$h2r, 0.9)
  solar_reset()
})

test_that("run_fphi rejects an unknown format", {
  expect_equal(solar_run_fphi(tempfile(), format = "xml"), 1)
})
