# TODO

feat:
    - [ ] create class for reading in solar output files.
        - read must happen in SolarCommand$run(). 
    - [ ] create class for parsing solar output from stdout.
    - [x] add option to save output dir & relates to an input dir option.
    - [x] create class `fphi`
build:
    - [ ] lib/solar900 needs to not be in the release package.
    - [ ] bundle solar versions.
tests:
    `SolarCommand`:
        - [x] `fphi()`
        - [x] `polygenic()`
        - [x] `new()`
docs:
    - [ ] inline comments class/methods
    - [ ] examples class/methods
    - [ ] tutorial vignette

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

## Notes

### solar

- solar download links from https://www.nitrc.org/frs/?group_id=558:
  - https://www.nitrc.org/frs/download.php/14502/solar-eclipse-9.0.1-static-Linux.zip
  - https://www.nitrc.org/frs/download.php/12460/solar-eclipse-9.0.0-mac-Monterey.zip

### R

1. CLI R script call: `Rscript main.R`
2. CLI inline: `Rscript -e "source('main.R')"`

## References

- https://r6.r-lib.org/articles/Introduction.html
- https://adv-r.hadley.nz/oo-tradeoffs.html
- https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Package-structure
- https://debruine.github.io/tutorials/your-first-r-package-with-unit-tests.html#unit-tests
- https://rstudio.github.io/cheatsheets/html/rmarkdown.html#render
- https://rstudio.github.io/cheatsheets/html/package-development.html#workflow
- https://r-pkgs.org/man.html
