# Notes

## Tests

```r
usethis::use_test("testname") # create test file
devtools::test() # run tests
```

### Reporters

```r
> devtools::test(reporter = 'tap')
ℹ Testing solareclipser
1..2
ok 1 fphi
ok 2 polygenic
> devtools::test(reporter = 'location')
ℹ Testing solareclipser
Start test: fphi
  'test-solar_cmd_fphi.R:33:3' [success]
End test: fphi

Start test: polygenic
  'test-solar_cmd_polygenic.R:26:3' [success]
End test: polygenic
```

## Build

Using `devtools`:

```R
devtools::check()
devtools::build(path = "release/")
devtools::install("release/")
```

Without:

```R
install_local("release/")
install.packages("release/solareclipser_0.3.3.tar.gz", dependancies = TRUE)
```

```R
install.packages("~/Downloads/myPackage_1.0.tar.gz", repos = NULL, type = "source")
```

Parallel:

- https://testthat.r-lib.org/articles/parallel.html

### Dependencies

Adding a dev dependency:

```R
usethis::use_package("testthat", type = "Suggests")
```

## Installation

Installing from a different branch:

```R
devtools::install_github("username/mypackage", ref = "dev")
```

Installing from a url:

```R
devtools::install_url("example.com/mypackage.tar.gz")
```

Install from local package: 

```R
install.packages("path/to/pkg.tar.gz", repos = NULL, type = "source")
```

## Documentation

- [rmarkdown](https://bookdown.org/yihui/rmarkdown-cookbook/rmarkdown-render.html)
- [workflowr](https://bookdown.org/yihui/rmarkdown-cookbook/workflowr.html)

## Notes

### solar

- solar download links from https://www.nitrc.org/frs/?group_id=558:
  - https://www.nitrc.org/frs/download.php/14502/solar-eclipse-9.0.1-static-Linux.zip
  - https://www.nitrc.org/frs/download.php/12460/solar-eclipse-9.0.0-mac-Monterey.zip

### R

1. CLI R script call: `Rscript main.R`
2. CLI inline: `Rscript -e "source('main.R')"`

### roxygen2

```r
vignette("rd-formatting") # roxygen2 markdown formatting
```

## VM setup

```
dnf install install epel-release
sudo dnf install epel-release
sudo dnf --set-enabled powertools
sudo dnf config-manager --set-enabled powertools
sudo dnf install R
sudo dnf install libxml2-devel
sudo dnf install libcurl-devel
sudo dnf install openssl-devel
sudo dnf install harfbuzz-devel
```

## References

- https://r6.r-lib.org/articles/Introduction.html
- https://adv-r.hadley.nz/oo-tradeoffs.html
- https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Package-structure
- https://debruine.github.io/tutorials/your-first-r-package-with-unit-tests.html#unit-tests
- https://rstudio.github.io/cheatsheets/html/rmarkdown.html#render
- https://rstudio.github.io/cheatsheets/html/package-development.html#workflow
- https://r-pkgs.org/man.html
