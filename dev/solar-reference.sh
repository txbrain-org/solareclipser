#!/bin/sh
# Regenerate the original-SOLAR reference outputs that
# tests/testthat/test-solar-reference.R compares against.
#
# Runs the local SOLAR 9.0.1 install (tests/solarcli/solar901, not in git) on
# data-raw/ for trait CC at kinship thresholds 0 and 1, and saves the FPHI
# summary block of each run to tests/testthat/fixtures/solar-CC-t<t>.out.
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

for t in 0 1; do
    # SOLAR writes its workspace into the current directory, so use a fresh one
    mkdir "$work/t$t"
    ln -s "$root/data-raw/$ped" "$root/data-raw/$phen" "$work/t$t/"
    printf 'load pedigree %s -t %s\nload phenotype %s\ntrait CC\nfphi\nexit\n' \
        "$ped" "$t" "$phen" > "$work/t$t/run.tcl"
    (cd "$work/t$t" && solarmain -noce < run.tcl > solar.out 2>&1)
    # Keep the summary block: from its first row of asterisks to the end
    sed -n '/^\*\*\*/,$p' "$work/t$t/solar.out" > "$fixtures/solar-CC-t$t.out"
    echo "Wrote $fixtures/solar-CC-t$t.out"
done
