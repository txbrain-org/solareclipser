# Bugs from previous repo

The following is what doesn't work following the [tutorial](https://ugcd.github.io/solarius/vignettes/tutorial.html). 🔴 is a breaking bug and 🟡 is a non-breaking bug that may astonish user.


- 🔴 [4.2.1](https://ugcd.github.io/solarius/vignettes/tutorial.html#plot-kinship-matrix)

    ```txt
    > plotKinship2(2*kin)
    Error in h(simpleError(msg, call)) :
      error in evaluating the argument 'x' in selecting a method for function 'image': object 'kin' not found
    Called from: h(simpleError(msg, call))
    ```

- 🟡 [4.2.3](https://ugcd.github.io/solarius/vignettes/tutorial.html#transform-traits)

    - `library("gridExtra")`

      - wasn't installed, so not in solareclipser dependency list, however after
        install it works. Must be included as dependency for examples, or
        suggested.

- 🟡 [4.3.2](https://ugcd.github.io/solarius/vignettes/tutorial.html#custom-kinship-matrix)

    - When following the tutorial `phenodata` is not loaded at this point and
    gives an error. Load the data first.

- 🟡 [4.5.3](https://ugcd.github.io/solarius/vignettes/tutorial.html#snp-data-by-genocov.files-single-value)

    - change package in `dir <- package.file("extdata", "solarAssoc", package = "solarius")` to `solareclipser`.
      This is just for when using the tutorial. Other references have been
      replaced.

- 🟡 [4.5.4](https://ugcd.github.io/solarius/vignettes/tutorial.html#snp-data-by-genocov.files-many-values)

    - same as 4.5.3

- 🔴 [4.5.5](https://ugcd.github.io/solarius/vignettes/tutorial.html#exploration-of-association-results)

    ```txt
    > plot(A5)
    Error in plotManh(x, ...) :
      requireNamespace("qqman", quietly = TRUE) is not TRUE
    Called from: plotManh(x, ...)
    ```

    - `qqman` should be a dependency. NOTE: This was added. Needs a test.

- 🟡 [6](https://ugcd.github.io/solarius/vignettes/tutorial.html#r-session-info) has
    a dependency listing that differs from other documentation.

- 🔴 [minimal.Rmd](docs/bak/minimal.Rmd) exposes a bug that package `rsnps`
  required by [assoc.lib.R](R/assoc.lib.R) is broken when using `check()`:

    ```txt
    E  creating vignettes (9s)
      --- re-building ‘minimal.Rmd’ using rmarkdown
      Failed with error:  'there is no package called 'rsnps''

      Quitting from lines  at lines 200-203 [annot_F11_gait1] (minimal.Rmd)
      Error: processing vignette 'minimal.Rmd' failed with diagnostics:
      requireNamespace("rsnps") is not TRUE
      --- failed re-building ‘minimal.Rmd’

      --- re-building ‘tutorial.Rmd’ using rmarkdown

      Quitting from lines  at lines 633-634 [ver_solarius] (tutorial.Rmd)
      Error: processing vignette 'tutorial.Rmd' failed with diagnostics:
      there is no package called 'solarius'
      --- failed re-building ‘tutorial.Rmd’

      SUMMARY: processing the following files failed:
        ‘minimal.Rmd’ ‘tutorial.Rmd’

      Error: Vignette re-building failed.
      Execution halted
     ```

     - See issue: <https://github.com/ropensci/rsnps/issues/174>.
     - Try previous version:
        - <https://cran-archive.r-project.org/web/checks/2023/2023-07-09_check_results_rsnps.html>
        - <https://cran.r-project.org/src/contrib/Archive/rsnps/>

- 🟡 [tutorial.Rmd](vignettes/tutorial.Rmd) exposes a bug that `solar` no
  longer has info that `solareclipser` needs to create the example using
  `loadExamplesPhen()` in [data.lib.R](R/data.lib.R). See older `solar` versions
  for data.

  ```txt
  E  creating vignettes (8.6s)
   --- re-building ‘tutorial.Rmd’ using rmarkdown
   no files matched glob pattern "/home/wb/solar900/doc/Example/*"

   Quitting from lines  at lines 769-771 [ex] (tutorial.Rmd)
   Error: processing vignette 'tutorial.Rmd' failed with diagnostics:
   cannot open the connection
   --- failed re-building ‘tutorial.Rmd’

   SUMMARY: processing the following file failed:
     ‘tutorial.Rmd’

   Error: Vignette re-building failed.
   Execution halted
   ```

   - The example is commented out for now.

### Other bug notes

Errors caused by checks for matrix. See list:

```txt
R/solar.lib.R:  #stopifnot(class(mat) == "matrix")
R/solar.lib.R:  #stopifnot(class(mat) == "matrix")
R/solar.lib.R:  stopifnot(class(map) == "data.frame")
R/solar.lib.R:  stopifnot(class(kf) == "data.frame")
R/solar.lib.R:  stopifnot(class(kmat) == "matrix")
R/solar.lib.R:  stopifnot(class(kf) == "data.frame")
R/solar.lib.R:  stopifnot(class(pf) == "data.frame")
R/multipoint.lib.R:  stopifnot(class(mf) == "data.frame")
R/classSolarMultipoint.R:  stopifnot(class(lodf) == "data.frame")
R/solarBayesAvg.R:  stopifnot(class(data) == "data.frame")
R/solarPolyAssoc.R:  #  stopifnot(class(snpcovdata) == "matrix")
R/plot.lib.R:  stopifnot(class(data) == "data.frame")
R/solarPolygenic.R:  stopifnot(class(data) == "data.frame")
R/solarAssoc.R:    stopifnot(class(mga.files) == "list")
R/solarAssoc.R:  #  stopifnot(class(snpdata) == "matrix")
R/solarAssoc.R:  #  #stopifnot(class(snpcovdata) == "matrix")
R/transforms.lib.R:  stopifnot(class(transforms) == "character")
R/transforms.lib.R:  stopifnot(class(transform) == "character")
R/transforms.lib.R:  stopifnot(class(x) %in% c("integer", "numeric"))
```


