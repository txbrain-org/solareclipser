devtools::document()
devtools::load_all()
library(solareclipser)
library(stringr)

solar_output_dir <- "tests/output/solar"

## traits:
## ID,CC,GCC,BCC,SCC,FX,CST,IC,ALIC,PLIC,RLIC,CR,ACR,SCR,PCR,PTR,SS,EC,CGC,CGH,FXST,SLF,SFO,UNC,TAP

#solar <- Solar$new(save_output_dir = solar_output_dir)
#solar$load(obj = "pedigree",
#           fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
#           cond = "-t 0")
#solar$load(obj = "phenotypes",
#           fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
#solar$trait("CC")
#solar$create_evd_data(output_fbasename = "evd_data")
#solar$fphi(evd_data = "evd_data")
#solar$run()

#solar <- Solar$new(save_output_dir = solar_output_dir)
#solar$load(obj = "pedigree",
#           fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
#           cond = "-t 0")
#solar$load(obj = "phenotypes",
#           fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
#solar$trait("CC")$polygenic()
#solar$run()

#sf <- SolarFiles$new(path_to_files = solar_output_dir)
#sf$set_polygenic_trait_d(trait_d = "CC")
#sfc <- SolarFilesController$new(sf = sf)
#sfc$set_polygenic_trait_d_files()
#trait_d_files <- sfc$get_polygenic_trait_d_files()
#print(trait_d_files)

# populates settings with new values
settings <- list(
  output = list(
    dir = "tests/output/solar",
    tcl = FALSE,
    stdout_and_stderr = TRUE
  )
)

solar <- Solar$new(settings = settings)
#solar$set_settings(settings = settings)$print_settings()

solar$load(obj = "pedigree",
           fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
           cond = "-t 0")
solar$load(obj = "phenotypes",
           fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
solar$trait("CC")$polygenic()
solar$run()


#solar <- Solar$new(settings = settings)
#solar$load(obj = "pedigree",
#           fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
#           cond = "-t 0")
#solar$load(obj = "phenotypes",
#           fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
#solar$trait("CC")
#solar$create_evd_data(output_fbasename = "evd_data")
#solar$fphi(evd_data = "evd_data")
#solar$run()


