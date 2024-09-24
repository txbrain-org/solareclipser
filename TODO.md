# TODO

- feat:
    - Pedifromsnp
        - [ ] complete options, need files for testing.
    - SolarFiles
        - [ ] create a parser to load into dataframe for the specific files (e.g. polygenic.out)

- build:
    - [ ] lib/solar900 needs to not be in the release package.
    - [ ] bundle solar versions.

- tests:
    - `Solar$run()`
        - [x] `polygenic()`
        - [x] `fphi()`

- docs:
    - [ ] inline comments class/methods
    - [ ] examples class/methods
    - [ ] tutorial vignette
        - [ ] installation
        - [ ] usage
            - [ ] `Solar$run()`
            - [ ] `SolarFiles()`

## Tests

```r
usethis::use_test("testname") # create test file
devtools::test() # run tests
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

Parallel:

- https://testthat.r-lib.org/articles/parallel.html

Adding a dev dependency:

```R
usethis::use_package("testthat", type = "Suggests")
```

## Notes

### solar

- solar download links from https://www.nitrc.org/frs/?group_id=558:
  - https://www.nitrc.org/frs/download.php/14502/solar-eclipse-9.0.1-static-Linux.zip
  - https://www.nitrc.org/frs/download.php/12460/solar-eclipse-9.0.0-mac-Monterey.zip

### R

1. CLI R script call: `Rscript main.R`
2. CLI inline: `Rscript -e "source('main.R')"`


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

### roxygen2

```r
vignette("rd-formatting") # roxygen2 markdown formatting
```

## References

- https://r6.r-lib.org/articles/Introduction.html
- https://adv-r.hadley.nz/oo-tradeoffs.html
- https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Package-structure
- https://debruine.github.io/tutorials/your-first-r-package-with-unit-tests.html#unit-tests
- https://rstudio.github.io/cheatsheets/html/rmarkdown.html#render
- https://rstudio.github.io/cheatsheets/html/package-development.html#workflow
- https://r-pkgs.org/man.html
