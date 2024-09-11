proj := 'solareclipser'
version := `grep -r Version DESCRIPTION | awk '{print $2}'`
pkg := proj + '_' + version + '.tar.gz'

release := 'release'
tests_release := 'tests/release'

release_pkg := release + '/' + pkg
tests_release_pkg := tests_release + '/' + pkg

user_libs := `find ~/Work/nGit/R -type d -iname "r_libs_user_linux"`

solar_output_files := 'tests/output/solar'

re := 'Rscript -e'
inspect_r := "\"source('tests/input/inspect.R')\""

# run inspect.R (default)
run:
  {{re}} {{inspect_r}}

# run devtools::test()
run-tests:
  {{re}} 'devtools::test()'

# devtools::build(path = "release/")'
# cp {{release_pkg}} {{tests_release}}
build:
  {{re}} 'devtools::build(path = "release/")'
  @if [ ! -d {{tests_release}} ]; then mkdir {{tests_release}}; fi
  cp {{release_pkg}} {{tests_release}}

# devtools::build_readme()
build-readme:
  {{re}} 'devtools::build_readme()'

# build-release: build build-readme
build-release: build build-readme

# devtools::check()
check:
  {{re}} 'devtools::check()'

# rm {{user_libs}}/{{pkg}}
clean-install:
  @if [ -f {{user_libs}}/{{pkg}} ]; then rm -Irf {{user_libs}}/{{pkg}}; fi

# devtools::install("release/")
install: clean-install
  {{re}} 'devtools::install("release/")'

# rm {{solar_output_files}}
clean-solar-outputs:
  @if [ -d {{solar_output_files}} ]; then rm -Irf {{solar_output_files}}/*; fi

# rm release/{{pkg}} && tests/release/{{pkg}}
clean:
  @if [ -f {{release_pkg}} ]; then rm -fI {{release_pkg}}; fi
  @if [ -f {{tests_release_pkg}} ]; then rm -fI {{tests_release_pkg}}; fi

# install.packages("{{tests_release_pkg}}", dependencies=TRUE)
test-release:
  {{re}} 'install.packages("{{tests_release_pkg}}", dependencies=TRUE)'

# print justfile variables
vars:
  @echo proj = {{proj}}
  @echo version = {{version}}
  @echo pkg = {{pkg}}
  @echo release = {{release}}
  @echo tests_release = {{tests_release}}
  @echo release_pkg = {{release_pkg}}
  @echo tests_release_pkg = {{tests_release_pkg}}
  @echo user_libs = {{user_libs}}
