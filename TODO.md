# TODO

## dev

- feat:
    - Pedifromsnp
        - [ ] complete options, need files for testing.
    - SolarFiles
        - [ ] create a parser to load into dataframe for the specific files (e.g. polygenic.out)

- build:
    - [ ] lib/solar900 needs to not be in the release package.
    - [ ] bundle solar versions.

- tests:
    - [ ] check install on vm, see [vm](dev/build/vm).
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

## chore

### CRAN

- [x] Possibly misspelled words in DESCRIPTION:
    solareclipser (18:27)
    Please single quote all  software names such as 'SOLAR' in both Title and Description fields of the DESCRIPTION file.
- [ ] FOSS licence with BuildVignettes: false
- [ ] Package has a VignetteBuilder field but no prebuilt vignette index.
- [x] Found the following (possibly) invalid file URI:
    URI: doc/solareclipser.pdf
      From: README.md
- [x] The Date field is over a month old.
