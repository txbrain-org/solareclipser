
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
#> Executing solar command... Done.
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
#> Executing solar command... Done.
```

``` r
s <- Solar$new(save_output_dir = "path/to/dir") # to save output files
```

## Tutorial

See [tutorial](inst/doc/tutorial.md) for more infomation.

## SOLAR references

  - [solar-eclipse-genetics.org](https://www.solar-eclipse-genetics.org/)
