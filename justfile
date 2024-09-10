proj := 'solareclipser'
version := `grep -r Version DESCRIPTION | awk '{print $2}'`
pkg := proj + '_' + version + '.tar.gz'

release := absolute_path('release')
tests_release := absolute_path('tests/release')

release_pkg := release + '/' + pkg
tests_release_pkg := tests_release + '/' + pkg

user_libs := `find ~/Work/nGit/R -type d -iname "r_libs_user_linux"`

re := 'Rscript -e'
inspect_r := "\"source('tests/debug/inspect.R')\""

run:
  {{re}} {{inspect_r}}

run-tests:
  {{re}} 'devtools::test()'

build:
  {{re}} 'devtools::build(path = "release/")'
  cp {{release_pkg}} {{tests_release}}

build-readme:
  {{re}} 'devtools::build_readme()'

check:
  {{re}} 'devtools::check()'

install:
  {{re}} 'devtools::install("release/")'

clean:
  @if [ -f {{release_pkg}} ]; then rm -f {{release_pkg}}; fi
  @if [ -f {{tests_release_pkg}} ]; then rm -f {{tests_release_pkg}}; fi

uninstall: clean
  rm -rv {{user_libs}}/{{pkg}}

test-release:
  {{re}} 'install.packages("{{tests_release_pkg}}", dependencies=TRUE)'

test:
  @echo proj = {{proj}}
  @echo version = {{version}}
  @echo pkg = {{pkg}}
  @echo release = {{release}}
  @echo tests_release = {{tests_release}}
  @echo release_pkg = {{release_pkg}}
  @echo tests_release_pkg = {{tests_release_pkg}}
  @echo user_libs = {{user_libs}}
