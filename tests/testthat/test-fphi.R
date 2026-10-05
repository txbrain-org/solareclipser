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

  expect_true(solar_load_pedigree(pedigree_tmp_csv, threshold = 0.0, output_dir = output_dir))
  expect_true(solar_load_phenotype(phenotypes_tmp_csv))
  expect_true(solar_select_trait(trait))

  # By default the results are only returned: nothing printed, no result files
  expect_output(res <- solar_run_fphi(output_basename), NA)

  expect_named(res, c("results", "parameters"))
  expect_s3_class(res$results, "data.frame")
  expect_named(res$results, c("trait", "h2r", "se", "loglik", "sporadic_loglik",
                              "p_value", "n_subjects"))
  expect_equal(nrow(res$results), 1)
  expect_identical(res$results$trait, "CC")
  expect_identical(res$results$n_subjects, 999L)
  expect_gt(res$results$h2r, 0.9)
  expect_s3_class(res$parameters, "data.frame")
  expect_named(res$parameters, c("parameter", "value", "se"))
  expect_identical(res$parameters$parameter, c("mean", "e2", "h2r", "sd"))
  expect_identical(res$parameters$value[3], res$results$h2r)
  expect_identical(attr(res, "pedigree"), pedigree_tmp_csv)
  expect_identical(attr(res, "phenotypes"), phenotypes_tmp_csv)

  expect_true(file.exists(paste0(output_basename, ".ids")))
  expect_true(file.exists(paste0(output_basename, ".eigenvalues")))
  expect_true(file.exists(paste0(output_basename, ".eigenvectors")))
  expect_true(file.exists(paste0(output_basename, ".notes")))
  expect_false(file.exists(paste0(output_basename, "_fphi_results.out")))
  expect_false(file.exists(paste0(output_basename, "_parameters.out")))
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

  solar_load_pedigree(pedigree_tmp_csv, threshold = 0.05, output_dir = output_dir)
  solar_load_phenotype(phenotypes_tmp_csv)
  solar_select_trait(trait)
  res <- solar_run_fphi(output_basename)

  expect_equal(res$results$h2r, 0.93350, tolerance = 1e-4)
  expect_true(file.exists(paste0(output_basename, ".eigenvectors")))

  solar_reset()
  unlink(output_dir, recursive = TRUE)
  unlink(pedigree_tmp_csv)
  unlink(phenotypes_tmp_csv)
})

# Runs the threshold 0 pipeline for trait CC in `dir`; returns the result
# (res) and stdout (out)
run_cc <- function(dir, ...) {
  data("pedigree", package = "solareclipser")
  data("phenotypes", package = "solareclipser")
  ped_csv <- file.path(dir, "ped.csv")
  phen_csv <- file.path(dir, "phen.csv")
  write.csv(pedigree, ped_csv, row.names = FALSE, quote = FALSE)
  write.csv(phenotypes, phen_csv, row.names = FALSE, quote = FALSE)

  solar_reset()
  solar_load_pedigree(ped_csv, threshold = 0.0, output_dir = dir)
  solar_load_phenotype(phen_csv)
  solar_select_trait("CC")
  res <- NULL
  out <- capture.output(res <- solar_run_fphi(file.path(dir, "CC"), ...))
  list(res = res, out = out)
}

test_that("run_fphi writes every output format with the same values", {
  dir <- tempfile("fphi_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  res <- run_cc(dir, format = c("csv", "tsv", "json", "yaml", "solar"))
  base <- file.path(dir, "CC")

  csv <- read.csv(paste0(base, "_fphi_results.out"))
  tsv <- read.delim(paste0(base, "_fphi_results.tsv"))
  expect_equal(tsv, csv)
  params <- read.csv(paste0(base, "_parameters.out"))
  expect_equal(read.delim(paste0(base, "_parameters.tsv")), params)
  # The text formats carry the same values as the returned data frames
  expect_equal(unname(as.list(csv)), unname(as.list(res$res$results)))
  expect_equal(unname(as.list(params)), unname(as.list(res$res$parameters)))
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
  expect_false(file.exists(file.path(dir, "CC_fphi.json")))
  expect_false(file.exists(file.path(dir, "CC_fphi_results.out")))

  skip_if_not_installed("jsonlite")
  expect_gt(jsonlite::fromJSON(paste(res$out, collapse = "\n"))$h2r, 0.9)
  solar_reset()
})

test_that("run_fphi rejects an unknown format", {
  expect_error(solar_run_fphi(tempfile(), format = "xml"), "Unknown output format 'xml'")
})

test_that("failures are signalled as R errors", {
  solar_reset()
  expect_error(solar_run_fphi(tempfile()), "pedigree not loaded")
  expect_error(solar_load_phenotype(tempfile()), "pedigree not loaded")
  expect_error(solar_load_pedigree(tempfile(), output_dir = tempdir()),
               "Cannot open pedigree file")

  data("phenotypes", package = "solareclipser")
  ped_csv <- tempfile(fileext = ".csv")
  phen_csv <- tempfile(fileext = ".csv")
  on.exit(unlink(c(ped_csv, phen_csv)), add = TRUE)
  ids <- as.character(phenotypes$ID[1:3])
  write.csv(data.frame(IDA = ids, IDB = ids, KIN = 1), ped_csv, row.names = FALSE, quote = FALSE)
  write.csv(phenotypes, phen_csv, row.names = FALSE, quote = FALSE)
  out_dir <- tempfile("ped_")
  dir.create(out_dir)
  on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)
  solar_load_pedigree(ped_csv, output_dir = out_dir)
  solar_load_phenotype(phen_csv)
  expect_error(solar_select_trait("nope"), "Trait 'nope' not found")
  solar_reset()
})
