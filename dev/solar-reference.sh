#!/bin/sh
# Regenerate the original-SOLAR reference outputs that
# tests/testthat/test-solar-reference.R compares against.
#
# Runs the local SOLAR 9.0.1 install (tests/solarcli/solar901, not in git) on
# data-raw/ for trait CC at kinship thresholds 0 and 1, and saves the FPHI
# summary block of each run to tests/testthat/fixtures/solar-CC-t<t>.out.
# Also runs CC at threshold 0 with covariates age^1,2#sex, on the phenotypes
# plus the synthetic age/sex columns of tests/testthat/helper-covariates.R,
# saved to solar-CC-t0-covar.out.
#
# Usage: dev/solar-reference.sh   (from the package root)
set -eu

root=$(pwd)
solar=$root/tests/solarcli/solar901
fixtures=$root/tests/testthat/fixtures
ped=HCP_imputed_filtered_ped.csv
phen=HCP_WM_ave_norm.csv

if [ ! -x "$solar/bin/solarmain" ]; then
    echo "SOLAR not found at $solar" >&2
    exit 1
fi

# The install's own launcher hardcodes paths, so set its environment here
export SOLAR_BIN=$solar/bin
export SOLAR_LIB=$solar/lib
export PATH=$SOLAR_BIN:$PATH
export LD_LIBRARY_PATH=$SOLAR_LIB${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
export TCL_LIBRARY=$SOLAR_LIB/tcl8.4
export TK_LIBRARY=$SOLAR_LIB/tk8.4
export SOLAR_PROGRAM_NAME=solar

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$fixtures"

# run <name> <threshold> <phenotype file> [<covariates>]
run() {
    # SOLAR writes its workspace into the current directory, so use a fresh one
    dir=$work/$1
    mkdir "$dir"
    ln -s "$root/data-raw/$ped" "$3" "$dir/"
    {
        printf 'load pedigree %s -t %s\nload phenotype %s\ntrait CC\n' "$ped" "$2" "$(basename "$3")"
        [ -z "${4:-}" ] || printf 'covariate %s\n' "$4"
        printf 'fphi\nexit\n'
    } > "$dir/run.tcl"
    (cd "$dir" && solarmain -noce < run.tcl > solar.out 2>&1)
    # Keep the summary block: from its first row of asterisks to the end
    sed -n '/^\*\*\*/,$p' "$dir/solar.out" > "$fixtures/solar-$1.out"
    echo "Wrote $fixtures/solar-$1.out"
}

run CC-t0 0 "$root/data-raw/$phen"
run CC-t1 1 "$root/data-raw/$phen"

Rscript -e 'source("tests/testthat/helper-covariates.R")' \
    -e "write_test_covariates(read.csv('data-raw/$phen'), '$work/phen_covar.csv')"
run CC-t0-covar 0 "$work/phen_covar.csv" 'age^1,2#sex'
