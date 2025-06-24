devtools::document()
devtools::load_all()
library(solareclipser)
library(stringr)

#solar_output_dir <- "tests/output/solar"

# populates settings with new values
settings <- list(
  output = list(
    #dir = "tests/output/solar",
    tcl = FALSE,
    stdout_and_stderr = TRUE
  )
)

solar <- Solar$new(settings = settings)
#solar$set_settings(settings = settings)$print_settings()

solar$cmd$load(obj = "pedigree",
               fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
               cond = "-t 0")
solar$cmd$load(obj = "phenotypes",
               fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
trait <- solar$cmd$trait("CC")$polygenic()
solar$run()


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


