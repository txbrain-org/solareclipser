# TODO

Core SOLAR-Eclipse features missing from solareclipser, compared against the
original SOLAR 9.0.1 source in `zz_solar_meson/` (the `fphi` command is
`runfphiCmd` in `src/solarmain/src/fphi.cc`; its help text is in
`resources/solar.tcl`). The port currently covers the default single-trait
`fphi` run: one empirical pedigree, one trait, optional covariates.

Check new features against the original SOLAR install where possible, as
`dev/solar-reference.sh` and `tests/testthat/test-solar-reference.R` do.

## FPHI, in priority order

1. ~~**Covariates**~~ (`covariate age sex age*sex ...`) — done:
   `solar_select_covariates()`, ported from `load_fphi_matrices` and checked
   against SOLAR in `test-solar-reference.R`. Not supported: trait-specific
   covariates `age(q1)` and null covariates `q2()`.

2. **Many traits from one EVD** (`fphi -list <file> [-evd_data <base>]`).
   SOLAR: `run_fast_fphi_trait_list`.
   Port: one trait per `solar_run_fphi()` call, and the EVD is rebuilt every
   time.
   This is the point of FPHI and of the UKBB workflow (see
   `dev/doc/pedigree-review.md`). The `results` data frame can carry one row
   per trait.

3. **Theoretical pedigrees** (`load pedigree` with id, fa, mo, sex columns;
   kinship computed from the family structure).
   SOLAR: `pedigree.cc`, `kin.f`, `pinput.f`.
   Port: rejected with "Only empirical pedigree format (IDA,IDB,KIN CSV) is
   supported".
   Most family studies have a pedigree rather than a genotype-derived kinship
   matrix. The `threshold` docs ("0.0 for theoretical") already hint at it.

4. **`-fast`** (Wald approximation).
   SOLAR: `converge = false`.
   Port: always runs the full search.
   Much faster for large trait lists; matters once item 2 exists.

5. **`inormal`** (inverse-normal transform of a trait).
   SOLAR: `normal.cc`, `inorm_nifti.cc`.
   Standard preprocessing before FPHI. Could be a few lines of R
   (`qnorm((rank - 0.5) / n)`), matching SOLAR's handling of ties.

6. **`-mom`** (method of moments), **`-mask`** / NIfTI voxel output,
   **`-precision`**. Niche; NIfTI output only matters for voxelwise imaging.

## Wider SOLAR

- **`polygenic`**: the full maximum-likelihood variance-components model,
  with household effects (`house`) and covariate screening. SOLAR's
  reference method, which FPHI approximates. A much larger port.
- **Genetic correlation** between two traits (bivariate,
  `genetic_correlation.cc`).
- **Association / GWAS** (`gwas.cc`, `mga`) and **linkage** (`ibd`, `mibd`,
  `multipoint`): large subsystems, probably out of scope.
- **`pedifromsnps`**: builds an empirical kinship matrix from genotypes.
  Other tools can already produce one.

## Suggested order

Covariates (1) and multi-trait / EVD reuse (2) first: together they make the
package usable for real analyses and stay within the already-ported FPHI
code. Then theoretical pedigrees (3). `polygenic` is the next big step after
that.

## Release check

`make release` runs `make check CHECK_ERROR_ON=warning`, which currently
fails with 0 errors, 3 warnings, 1 note (R 4.6.1, 2026-10-05):

- WARNING, significant compiler warnings on install: the bundled `src/Eigen`
  triggers `-Wdeprecated-enum-enum-conversion`. Fix by linking RcppEigen
  instead, or updating the bundled Eigen.
- WARNING, pragmas suppressing diagnostics: also in the bundled Eigen; same
  fix.
- WARNING, compiled code may terminate R: `STOP`/`exit` in `cdfchi.f`. Not
  fixable without editing Fortran, which CLAUDE.md rules out.
- NOTE, non-standard top-level files `LICENSE.md` and `README.Rmd`: add them
  to `.Rbuildignore`.

Because of `cdfchi.f`, the strict check can't pass as things stand. Options:

1. Keep `release` strict (`CHECK_ERROR_ON=warning`) and accept that it fails
   until the package changes.
2. Have `release` stop only on errors: run `make release CHECK_ERROR_ON=error`
   for one release, or make `error` the default in the Makefile's
   `RELEASE_ERROR_ON`.
