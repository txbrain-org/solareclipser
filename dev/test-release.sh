#!/usr/bin/env bash
# Download a solareclipser release tarball and test it in a fresh R library:
# install its dependencies from CRAN, install the tarball, run the bundled
# example and the package tests (optionally R CMD check) against it.
#
# R runs with --vanilla from a temp dir and only sees a new empty library (plus
# R's own base packages), so no renv, .Rprofile or site/user library is used.
#
# Usage: dev/test-release.sh [options]
#   -v VERSION   release version to download (default 1.0.0)
#   -r REF       git ref (branch/tag/sha) to download it from (default main)
#   -t TARBALL   test this local tarball instead of downloading one
#   -c           also run R CMD check --as-cran on the tarball (needs pandoc)
#   -k           keep the work dir (default: removed on exit)
#   -h           show this help
#
# Environment:
#   REPOS   CRAN repo for dependencies. Default: Posit Package Manager Linux
#           binaries on Ubuntu-based systems (no compiling, no system libs
#           needed), else https://cloud.r-project.org (source packages; fs,
#           a testthat dependency, then needs libuv1-dev or cmake)
#   JOBS    parallel compile jobs (default nproc)

set -euo pipefail

PKG=solareclipser
GH_REPO=txbrain-org/solareclipser
VERSION=1.0.0
REF=main
TARBALL=
CHECK=0
KEEP=0
UBUNTU_CODENAME=$( . /etc/os-release 2>/dev/null; echo "${UBUNTU_CODENAME:-}")
if [[ -n $UBUNTU_CODENAME ]]; then
  REPOS=${REPOS:-https://packagemanager.posit.co/cran/__linux__/$UBUNTU_CODENAME/latest}
else
  REPOS=${REPOS:-https://cloud.r-project.org}
fi
JOBS=${JOBS:-$(nproc)}

usage() { sed -n '2,/^$/s/^# \{0,1\}//p' "$0"; }

while getopts "v:r:t:ckh" opt; do
  case $opt in
    v) VERSION=$OPTARG ;;
    r) REF=$OPTARG ;;
    t) TARBALL=$(realpath "$OPTARG") ;;
    c) CHECK=1 ;;
    k) KEEP=1 ;;
    h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

step() { printf '\n==> %s\n' "$*"; }

for cmd in R Rscript tar gfortran; do
  command -v "$cmd" >/dev/null || { echo "error: $cmd not found" >&2; exit 1; }
done

WORK=$(mktemp -d -t "$PKG-release-XXXXXX")
if [[ $KEEP == 1 ]]; then
  trap 'echo; echo "work dir kept: $WORK"' EXIT
else
  trap 'rm -rf "$WORK"' EXIT
fi
LIB=$WORK/lib
mkdir -p "$LIB" "$WORK/dl" "$WORK/src" "$WORK/run"
cd "$WORK/run"

# Fresh library only: R_LIBS_SITE/R_LIBS_USER would otherwise add the system
# site and user libraries to .libPaths()
export R_LIBS="$LIB" R_LIBS_USER="$LIB" R_LIBS_SITE="$LIB"
export MAKEFLAGS="-j$JOBS"
# When building fs from source without system libuv, build its bundled copy
# (needs cmake)
export USE_BUNDLED_LIBUV=1
R_VANILLA=(Rscript --vanilla)

if [[ -n $TARBALL ]]; then
  step "Using local tarball $TARBALL"
  cp "$TARBALL" "$WORK/dl/"
  TARBALL=$WORK/dl/$(basename "$TARBALL")
else
  URL=https://raw.githubusercontent.com/$GH_REPO/$REF/release/${PKG}_$VERSION.tar.gz
  TARBALL=$WORK/dl/${PKG}_$VERSION.tar.gz
  step "Downloading $URL"
  if command -v curl >/dev/null; then
    curl -fSL -o "$TARBALL" "$URL"
  else
    "${R_VANILLA[@]}" -e "download.file('$URL', '$TARBALL', mode = 'wb')"
  fi
fi
sha256sum "$TARBALL"
tar -xzf "$TARBALL" -C "$WORK/src"
SRC=$WORK/src/$PKG
grep -E '^(Package|Version):' "$SRC/DESCRIPTION"

step "R and library"
"${R_VANILLA[@]}" -e 'cat(R.version.string, "\n"); print(.libPaths())'

# Imports/LinkingTo plus the Suggests the tests use; -c also needs the
# vignette builders
DEPS='"Rcpp", "testthat", "jsonlite", "yaml"'
[[ $CHECK == 1 ]] && DEPS+=', "knitr", "rmarkdown"'
step "Installing dependencies from $REPOS"
"${R_VANILLA[@]}" -e "
  options(repos = c(CRAN = '$REPOS'), Ncpus = $JOBS)
  # Posit Package Manager serves Linux binaries only for this user agent
  options(HTTPUserAgent = sprintf('R/%s R (%s)', getRversion(),
    paste(getRversion(), R.version['platform'], R.version['arch'], R.version['os'])))
  pkgs <- c($DEPS)
  install.packages(pkgs, lib = '$LIB')
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop('failed to install: ', toString(missing))
"

step "Installing $(basename "$TARBALL")"
R --vanilla CMD INSTALL --library="$LIB" "$TARBALL"

step "Running inst/examples/minimal.R"
"${R_VANILLA[@]}" -e "
  library($PKG)
  stopifnot(normalizePath(find.package('$PKG')) == normalizePath(file.path('$LIB', '$PKG')))
  cat('$PKG', format(packageVersion('$PKG')), 'from', find.package('$PKG'), '\n')
  source(system.file('examples', 'minimal.R', package = '$PKG'), echo = TRUE)
  stopifnot(is.data.frame(res\$results), nrow(res\$results) > 0)
"

step "Running tests against the installed package"
"${R_VANILLA[@]}" -e "
  testthat::test_dir('$SRC/tests/testthat', package = '$PKG',
                     load_package = 'installed', stop_on_failure = TRUE)
"

if [[ $CHECK == 1 ]]; then
  step "R CMD check --as-cran"
  command -v pandoc >/dev/null || [[ -n ${RSTUDIO_PANDOC:-} ]] ||
    echo "warning: pandoc not found; the vignette will not build" >&2
  (cd "$WORK" && _R_CHECK_FORCE_SUGGESTS_=false \
    R --vanilla CMD check --as-cran --no-manual "$TARBALL")
fi

step "OK: $(basename "$TARBALL") passed"
