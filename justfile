## https://just.systems/man/en/recipe-parameters.html
## https://just.systems/man/en/documentation-comments.html?highlight=comments#documentation-comments
## {{re}} 'rmarkdown::render("doc/solareclipser.Rmd", output_format = "all")'; \

set shell := ["bash", "-cu"]

proj := 'solareclipser'
version := `grep -r Version DESCRIPTION | awk '{print $2}'`
pkg := proj + '_' + version + '.tar.gz'

release := 'release'
#tests_release := 'tests/release'

release_pkg := release + '/' + pkg
#tests_release_pkg := tests_release + '/' + pkg

user_libs := `find ~/Work/nGit/R -type d -iname "r_libs_user_linux"`

solar_output_dir := 'tests/output/solar'

re := 'Rscript -e'
tests_d := 'tests/input'
tests_r := `find tests/input -type f -iname "*.R" -exec basename {} \;`
inspect_r := "\"source('tests/input/inspect.R')\""

pd_defaults_yml := "\
---
# General
# Reader
# General Writer
variables:
  margin-left: .5in
  margin-right: .5in
  margin-top: .5in
  margin-bottom: .5in
  maxwidth: inherit
  fontsize: 12pt
  mainfont: Lato
  monofont: FiraCode Nerd Font
  linkcolor: blue
  pagestyle: empty
highlight-style: tango
# Options affecting specific writers
pdf-engine: wkhtmltopdf
# ascii: true
...
"

tmpyml := proj + ".yml"
tmpmd := proj + ".md"
tmppdf := proj + ".pdf"

debug:
  @echo -n "{{pd_defaults_yml}}"
  @echo "tmpyml = {{tmpyml}}"
  @echo "tmpmd  = {{tmpmd}}"
  @echo "tmppdf = {{tmppdf}}"

# lists tests in {{tests_d}}
_tests-show:
  @find {{tests_d}} -type f -iname "*.R" -exec basename {} \;

# tests [show | {{t}}]
tests param:
  if [[ {{param}} == "show" ]]; then \
    just _tests-show; \
  else \
    {{re}} "source('tests/input/{{param}}')"; \
  fi

# https://rstudio.github.io/cheatsheets/html/package-development.html
# devtools [load_all | test | check | document | build | readme | install]
devtools param:
  @if [[ {{param}} == "load_all" ]]; then {{re}} 'devtools::load_all()'; fi
  @if [[ {{param}} == "test" ]]; then {{re}} 'devtools::test()'; fi
  @if [[ {{param}} == "check" ]]; then {{re}} 'devtools::check()'; fi # -> pre commit
  @if [[ {{param}} == "document" ]]; then {{re}} 'devtools::document()'; fi # -> ?fun
  @if [[ {{param}} == "build" ]]; then {{re}} 'devtools::build(path = "release/")'; fi
  @if [[ {{param}} == "readme" ]]; then {{re}} 'devtools::build_readme()'; fi
  @if [[ {{param}} == "install" ]]; then {{re}} 'devtools::install("release/")'; fi
  @if [[ {{param}} == "vignettes" ]]; then \
    {{re}} 'devtools::build_vignettes()' && \
    tmpdir=$(mktemp -d /tmp/solareclipser.pandoc.XXXXXXXX) && \
    touch $tmpdir/{{tmpyml}} && \
    echo "{{pd_defaults_yml}}" > $tmpdir/{{tmpyml}} ;\
    echo "touch $tmpdir/{{tmpmd}} &&"; \
    touch $tmpdir/{{tmpmd}} && \
    pandoc doc/solareclipser.html -t markdown -o $tmpdir/{{tmpmd}} ;\
    touch $tmpdir/{{tmppdf}} && \
    pandoc -d $tmpdir/{{tmpyml}} $tmpdir/{{tmpmd}} -t html -o $tmpdir/{{tmppdf}} && \
    cp $tmpdir/{{tmppdf}} doc/ ;\
  fi

_vignettes: (clean "install") (devtools "build") (devtools "install") (devtools "vignettes")

# _build && devtools readme
_build-all: _vignettes (devtools "readme")

# build [all | readme | vignettes]
build param:
  @if [[ {{param}} == "all" ]]; then just _build-all; fi
  @if [[ {{param}} == "vignettes" ]]; then just _vignettes; fi
  @if [[ {{param}} == "readme" ]]; then just devtools readme; fi

# rm {{user_libs}}/{{pkg}}
_clean-install:
  @if [[ ! -z {{user_libs}} && -d {{user_libs}}/{{proj}} ]]; then rm -rfv {{user_libs}}/{{proj}} 2> /dev/null; fi

# rm {{solar_output_dir}}
_clean-solar-output:
  @if [[ ! -z {{solar_output_dir}} && -d {{solar_output_dir}} ]]; then rm -rfv {{solar_output_dir}}/* 2> /dev/null; fi

# rm release/{{pkg}} && tests/release/{{pkg}}
_clean-release:
  @if [[ ! -z {{release_pkg}} && -f {{release_pkg}} ]]; then rm -rfv {{release_pkg}}; fi

# _clean [clean install | solar-output | release]
_clean param:
  @if [[ {{param}} == "install" ]]; then just _clean-install; fi
  @if [[ {{param}} == "solar-output" ]]; then just _clean-solar-output; fi
  @if [[ {{param}} == "release" ]]; then just _clean-release; fi

_clean-all: (_clean "install") (_clean "solar-output") (_clean "release")

# clean [all | install | solar-output | release]
clean param:
  @if [[ {{param}} == "all" ]]; then just _clean-all; fi
  @if [[ {{param}} == "install" ]]; then just _clean-install; fi
  @if [[ {{param}} == "solar-output" ]]; then just _clean-solar-output; fi
  @if [[ {{param}} == "release" ]]; then just _clean-release; fi
  
# install : build all
install: (build "all")
