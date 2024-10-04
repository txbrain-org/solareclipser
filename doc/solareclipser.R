## ----include = FALSE----------------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)
knitr::opts_knit$set(root.dir = rprojroot::find_rstudio_root_file())

## ----installation, eval = FALSE-----------------------------------------------
#  install.packages("devtools")
#  devtools::install_github("txbrain-org/solareclipser")

## ----settings-----------------------------------------------------------------
library(solareclipser)

settings <- list(
  output = list(
    dir = "tests/output/solar",
    tcl = FALSE,
    stdout_and_stderr = FALSE
  )
)

## ----polygenic----------------------------------------------------------------
solar <- Solar$new(settings = settings)
solar$cmd$load(obj = "pedigree",
               fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
               cond = "-t 0")
solar$cmd$load(obj = "phenotypes",
               fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
solar$cmd$trait("CC")$polygenic()
solar$run()

## ----fphi---------------------------------------------------------------------
library(solareclipser)

solar <- Solar$new(settings = settings)
solar$cmd$load(obj = "pedigree",
               fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
               cond = "-t 0")
solar$cmd$load(obj = "phenotypes",
               fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
solar$cmd$trait("CC")
solar$cmd$create_evd_data(output_fbasename = "evd_data")
solar$cmd$fphi(evd_data = "evd_data")
solar$run()

## ----solarfiles_polygenic-----------------------------------------------------
# trait_d => trait directory
sf <- SolarFiles$new(settings = settings)
sf$set_polygenic_trait_d(trait_d = "CC")
sfc <- SolarFilesController$new(sf = sf)
sfc$set_polygenic_trait_d_files()
trait_d_files <- sfc$get_polygenic_trait_d_files()

mod_files <- sfc$get_mod_files()
out_files <- sfc$get_out_files()
stat_files <- sfc$get_stats_files()

summary <- readLines(out_files[str_detect(out_files, "polygenic.out")])
cat(str_trim(summary), sep = "\n")

## ----settings_tcl_true_stdout_and_stderr_true---------------------------------
library(solareclipser)

settings <- list(
  output = list(
    dir = "tests/output/solar",
    tcl = TRUE,
    stdout_and_stderr = TRUE
  )
)

solar <- Solar$new(settings = settings)
solar$cmd$load(obj = "pedigree",
               fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
               cond = "-t 0")
solar$cmd$load(obj = "phenotypes",
               fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
solar$cmd$trait("CC")$polygenic()
solar$run()

