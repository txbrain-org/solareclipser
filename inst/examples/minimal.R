library(solareclipser)

## Load the example data
data("pedigree", package = "solareclipser")
data("phenotypes", package = "solareclipser")

## Write temporary CSV files
pedigree_tmp_csv <- tempfile(fileext = ".csv")
write.csv(pedigree, pedigree_tmp_csv, row.names = FALSE, quote = FALSE)
phenotypes_tmp_csv <- tempfile(fileext = ".csv")
write.csv(phenotypes, phenotypes_tmp_csv, row.names = FALSE, quote = FALSE)

## Create temporary output directory
output_dir <- tempfile("fphi_")
dir.create(output_dir)
trait <- "CC"
output_basename <- file.path(output_dir, trait)

rc <- solar_load_pedigree(pedigree_tmp_csv, threshold = 0.0, output_dir = output_dir)
if (rc != 0) {
  stop("Failed to load pedigree")
}

rc <- solar_load_phenotype(phenotypes_tmp_csv)
if (rc != 0) {
  stop("Failed to load phenotypes")
}

rc <- solar_select_trait(trait)
if (rc != 0) {
  stop("Failed to select trait")
}

## Results are printed to stdout in each format and written to
## <output_basename>_fphi_results.out / _parameters.out (csv) and
## <output_basename>_fphi.json. Other formats: "tsv", "yaml", and "solar"
## (the original SOLAR-Eclipse summary block, for diffing against its output).
rc <- solar_run_fphi(output_basename, format = c("csv", "json"))
if (rc != 0) {
  stop("FPHI analysis failed")
}

## Read and display FPHI results
fphi_results <- read.csv(paste0(output_basename, "_fphi_results.out"))
