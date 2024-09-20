
<!-- README.md is generated from README.Rmd. Please edit that file -->

# solareclipser

<!-- badges: start -->

<!-- badges: end -->

## Description

`solareclipser` is an R package to interface SOLAR and to run its main
models: polygenic, fphi.

## Installation

You can install solareclipser like so:

``` r
library(devtools)
install_github("txbrain-org/solareclipser")
```

## Examples

``` r
library(solareclipser)

s <- Solar$new()
s$load(obj = "pedigree",
       fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
       cond = "-t 0")
s$load(obj = "phenotypes",
       fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
s$trait("CC")
s$polygenic()
s$run()
#> ------------------------------------------------------------
#> 
#> proc filec42c1f5d9591 {} {
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

s <- Solar$new()
s$load(obj = "pedigree",
       fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
       cond = "-t 0")
s$load(obj = "phenotypes",
       fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
s$trait("CC")
s$create_evd_data(output_fbasename = "CC_evd")
s$fphi(evd_data = "CC_evd")
s$run()
#> ------------------------------------------------------------
#> 
#> proc filec42c64b3f9f7 {} {
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
s <- Solar$new(save_output_dir = "path/to/dir") # to save output files
```

## Tutorial

See [tutorial](inst/doc/tutorial.md) for more infomation.

## SOLAR references

  - The new [SOLAR web page](https://solar-eclipse-genetics.org/)
    (SOLAR-Eclipse)
  - [Appendix 1. SOLAR Command
    Descriptions](http://helix.nih.gov/Documentation/solar-6.6.2-doc/91.appendix_1_text.html)
