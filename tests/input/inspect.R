library(solareclipser)

# 1st run
#sc <- SolarCommand$new(save_output_dir = "tests/output/solar")
#sc$load(obj = "pedigree",
#        fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
#        cond = "-t 0")
#sc$load(obj = "phenotypes",
#        fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
#sc$trait("CC")
#sc$create_evd_data(output_fbasename = "CC_evd")
#sc$fphi(evd_data = "CC_evd")
#sc$run()

# 2nd run
sc <- SolarCommand$new(save_output_dir = "tests/output/solar")
sc$load(obj = "pedigree",
        fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
        cond = "-t 0")
sc$load(obj = "phenotypes",
        fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
sc$trait("CC")
sc$create_evd_data(output_fbasename = "CC_evd")
sc$fphi(evd_data = "CC_evd")
sc$run()
