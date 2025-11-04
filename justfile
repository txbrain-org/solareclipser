## https://just.systems/man/en/recipe-parameters.html
## https://just.systems/man/en/documentation-comments.html?highlight=comments#documentation-comments
## {{re}} 'rmarkdown::render("doc/solareclipser.Rmd", output_format = "all")'; \

set shell := ["bash", "-cu"]
project := 'solareclipser'

user := ''
vmip := ''

re := 'R -e'
builddir := 'release'

# compile and load into memory (current R session only - temp state)
load:
  {{re}} 'devtools::load_all()'

# updates generated docs in man/ from roxygen comments in R/
document:
  {{re}} 'devtools::document()'

# updates the documentation, then builds and checks the package locally.
check:
  {{re}} 'devtools::check(error_on = "error")'

# updates the documentation, then builds and checks the package as CRAN would.
check_cran:
  {{re}} 'devtools::check(error_on = "error", cran = TRUE)'

# installs the package locally
install:
  {{re}} 'devtools::install("release/")'

# builds a package file from package sources
build:
  {{re}} 'devtools::build(path = "{{builddir}}/")'

# locates your README.Rmd and builds it into a README.md
build_readme:
  {{re}} 'devtools::build_readme()'

# https://devtools.r-lib.org/reference/build_vignettes.html?q=build_vignettes#null
build_vignettes:
  {{re}} 'devtools::build_vignettes()'

#release: document build_readme build_vignettes check_release build install

test:
  {{re}} 'devtools::test()'

clean:
  rm src/*.o src/*.so || true

# print dev flow
help-dev:
  cat dev/doc/flow.md

bear:
  bear -- R CMD INSTALL . --preclean
  just load

cpp_src_target := 'solareclipser'
pheno := 'CC'

_test-cpp-setup:
  make clean && make && make install
  mkdir -p tests/testsrc && cp -a inst/bin/solareclipser tests/testsrc

test-cpp: _test-cpp-setup
  make && \
  cd tests/testsrc && \
    ./{{cpp_src_target}} fphi --pedigree ../testdata/HCP_imputed_filtered_ped.csv -t 0 \
                      --phenotypes ../testdata/HCP_WM_ave_norm.csv \
                      --trait {{pheno}} \
                      --out {{pheno}}_evd

push-vm:
  rsync -avz --delete ../{{project}}/ {{user}}@{{vmip}}:~/{{project}}/

pull-vm:
  rsync -avz --delete {{user}}@{{vmip}}:~/{{project}}/ ../{{project}}/
