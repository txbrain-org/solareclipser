
<!-- README.md is generated from README.Rmd. Please edit that file -->

# solareclipser

<!-- badges: start -->

<!-- badges: end -->

## Description

`solareclipser` is an R package to interface SOLAR and to run its main
models: polygenic, fphi.

## Installation

You can install the development version of solareclipser like so:

``` r
library(devtools)
install_github("enigma-1590c46634/solareclipser")
```

## Minimal example

``` r
library(solareclipser)

sc <- SolarCommand$new()
sc$load(obj = "pedigree",
        fpath = "tests/debug/solar/input/HCP_imputed_filtered_ped.csv",
        cond = "-t 0")
sc$load(obj = "phenotypes",
        fpath = "tests/debug/solar/input/HCP_WM_ave_norm.csv")
sc$trait("CC")$polygenic()
sc$run()
#> ------------------------------------------------------------
#> 
#> proc file50227c6a5776 {} {
#>   load pedigree HCP_imputed_filtered_ped.csv -t 0
#>   load phenotypes HCP_WM_ave_norm.csv
#>   trait CC
#>   polygenic
#> }
#> 
#> ------------------------------------------------------------
```

``` r
library(solareclipser)
sc <- SolarCommand$new()
sc$load(obj = "pedigree",
        fpath = "tests/debug/solar/input/HCP_imputed_filtered_ped.csv",
        cond = "-t 0")
sc$load(obj = "phenotypes",
        fpath = "tests/debug/solar/input/HCP_WM_ave_norm.csv")
sc$trait("CC")
sc$create_evd_data(output_fbasename = "CC_evd")
sc$fphi(evd_data = "CC_evd")
sc$run()
#> ------------------------------------------------------------
#> 
#> proc file5022750317bb {} {
#>   load pedigree HCP_imputed_filtered_ped.csv -t 0
#>   load phenotypes HCP_WM_ave_norm.csv
#>   trait CC
#>   create_evd_data --o CC_evd
#>   fphi --evd_data CC_evd
#> }
#> 
#> ------------------------------------------------------------
```

``` r
SolarCommand$new(save_output_dir = "path/to/dir") # to save output files
```

## Tutorial

See [tutorial](inst/doc/tutorial.md) for more infomation.

## SOLAR references

  - The new [SOLAR web page](https://solar-eclipse-genetics.org/)
    (SOLAR-Eclipse)
  - [Appendix 1. SOLAR Command
    Descriptions](http://helix.nih.gov/Documentation/solar-6.6.2-doc/91.appendix_1_text.html)
