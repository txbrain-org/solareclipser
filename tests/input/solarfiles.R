devtools::document()
devtools::load_all()
library(solareclipser)
library(stringr)

solar_output_dir <- "tests/output/solar"

solar <- Solar$new(save_output_dir = solar_output_dir)
solar$load(obj = "pedigree",
           fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
           cond = "-t 0")
solar$load(obj = "phenotypes",
           fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
solar$trait("CC")$polygenic()
#solar$run()

sf <- SolarFiles$new(path_to_files = solar_output_dir)
sf$set_polygenic_trait_d(trait_d = "CC")
sfc <- SolarFilesController$new(sf = sf)
sfc$set_polygenic_trait_d_files()
trait_d_files <- sfc$get_polygenic_trait_d_files()

mod_files <- sfc$get_mod_files()
out_files <- sfc$get_out_files()
stat_files <- sfc$get_stats_files()

summary <- readLines(out_files[str_detect(out_files, "polygenic.out")])

# cat without leading and trailing whitespace
cat(str_trim(summary), sep = "\n")

# Pedigree:    HCP_imputed_filtered_ped.csv empirical
# Phenotypes:  HCP_WM_ave_norm.csv
# Trait:       CC GCC                Individuals:  999
# 
#      H2r(CC) is 0.9313878  
#      H2r(CC) Std. Error:  0.0111919
# 
#      H2r(GCC) is 0.9085732  
#      H2r(GCC) Std. Error:  0.0130573
# 
# Warning.  Unexpectedly high heritabilities might result from
# numerical problems, especially if mztwins are present.
# 
#      RhoE is 0.5418278  
#      RhoE Std. Error:  0.0652996
# 
#      RhoG is 0.9303343
#      RhoG Std. Error:  0.0084219
# 
#      Derived Estimate of RhoP is 0.8987376
# 
# Loglikelihoods and chi's are in CC.GCC/polygenic.logs.out
# Best model is named poly and null0
# Final models are named poly, spor

## # get polygenic.out files
## text <- readLines(out_files[str_detect(out_files, "polygenic.out")])
## 
## # Extract relevant data using regular expressions
## pedigree <- str_match(text, "Pedigree:\\s+([\\S]+)")[1,2]
## phenotypes <- str_match(text, "Phenotypes:\\s+([\\S]+)")[2,2]
## # (Trait:)(.*)(Individuals:)(\s+[0-9]+)
## #trait_info <-
## #  str_match(text, "(Trait:)(.*)(Individuals:)")
## trait_info <-
##   str_match(text, "(Trait:)(.*)(Individuals:)")
## print(trait_info)
## 
## #trait_info <- str_match(text, "Trait:\\s+(\\S+)\\s+(\\S+)\\s+Individuals:\\s+(\\d+)")
## #h2r_CC <- str_match(text, "H2r\\(CC\\) is\\s+([\\S]+)")[,2]
## #h2r_CC_se <- str_match(text, "H2r\\(CC\\) Std. Error:\\s+([\\S]+)")[,2]
## #h2r_GCC <- str_match(text, "H2r\\(GCC\\) is\\s+([\\S]+)")[,2]
## #h2r_GCC_se <- str_match(text, "H2r\\(GCC\\) Std. Error:\\s+([\\S]+)")[,2]
## #rhoE <- str_match(text, "RhoE is\\s+([\\S]+)")[,2]
## #rhoE_se <- str_match(text, "RhoE Std. Error:\\s+([\\S]+)")[,2]
## #rhoG <- str_match(text, "RhoG is\\s+([\\S]+)")[,2]
## #rhoG_se <- str_match(text, "RhoG Std. Error:\\s+([\\S]+)")[,2]
## #rhoP <- str_match(text, "RhoP is\\s+([\\S]+)")[,2]
## 
## # Create a dataframe using base R
## df <- data.frame(
##   Pedigree = pedigree,
##   Phenotypes = phenotypes
## #  Trait_1 = trait_info[2],
## #  Trait_2 = trait_info[3],
## #  Individuals = as.numeric(trait_info[4]),
## #  H2r_CC = as.numeric(h2r_CC),
## #  H2r_CC_Std_Error = as.numeric(h2r_CC_se),
## #  H2r_GCC = as.numeric(h2r_GCC),
## #  H2r_GCC_Std_Error = as.numeric(h2r_GCC_se),
## #  RhoE = as.numeric(rhoE),
## #  RhoE_Std_Error = as.numeric(rhoE_se),
## #  RhoG = as.numeric(rhoG),
## #  RhoG_Std_Error = as.numeric(rhoG_se),
## #  RhoP = as.numeric(rhoP),
## #  stringsAsFactors = FALSE
## )
## 
## # View the dataframe
## print(df)
## 
