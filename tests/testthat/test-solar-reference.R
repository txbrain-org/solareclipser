# Compares format = "solar" with the summary block printed by the original
# SOLAR 9.0.1 fphi for trait CC. The references in fixtures/ are generated
# from data-raw/ (which the bundled datasets are built from) by
# dev/solar-reference.sh.

# Runs the pipeline for trait CC at `threshold`; returns the solar summary lines
run_solar_format <- function(threshold) {
  dir <- tempfile("fphi_")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE), add = TRUE)
  data("pedigree", package = "solareclipser")
  data("phenotypes", package = "solareclipser")
  ped_csv <- file.path(dir, "ped.csv")
  phen_csv <- file.path(dir, "phen.csv")
  write.csv(pedigree, ped_csv, row.names = FALSE, quote = FALSE)
  write.csv(phenotypes, phen_csv, row.names = FALSE, quote = FALSE)

  solar_reset()
  on.exit(solar_reset(), add = TRUE)
  stopifnot(solar_load_pedigree(ped_csv, threshold = threshold, output_dir = dir) == 0,
            solar_load_phenotype(phen_csv) == 0,
            solar_select_trait("CC") == 0)
  capture.output(rc <- solar_run_fphi(file.path(dir, "CC"), format = "solar"))
  stopifnot(rc == 0)
  readLines(file.path(dir, "CC_fphi.solar.out"))
}

drop_trailing_blank <- function(lines) {
  n <- length(lines)
  while (n > 0 && lines[n] == "") n <- n - 1
  lines[seq_len(n)]
}

as_number <- function(tok) {
  ifelse(tolower(tok) %in% c("nan", "-nan"), NaN, suppressWarnings(as.numeric(tok)))
}

# Line by line: words must match exactly and numbers to a relative tolerance.
# SOLAR stores kinship as float and the port as double, so numbers agree only
# to ~1e-7; the p-value and the near-zero mean are more sensitive, so the
# tokens keyed by `loose` get `loose_tol`. A number's key is the nearest word
# before it on its line (the parameter name, or e.g. "p" in "p = ...").
expect_solar_equal <- function(out, ref, tol = 1e-6,
                               loose = c("p", "mean"), loose_tol = 1e-4) {
  out <- drop_trailing_blank(out)
  ref <- drop_trailing_blank(ref)
  expect_equal(length(out), length(ref))
  for (i in seq_len(min(length(out), length(ref)))) {
    # The file names are echoed as passed in, so they differ by path
    if (grepl("^  (Pedigree|Phenotypes):", ref[i])) next
    o <- strsplit(trimws(out[i]), " +")[[1]]
    r <- strsplit(trimws(ref[i]), " +")[[1]]
    if (length(o) != length(r)) {
      expect_identical(out[i], ref[i], label = sprintf("line %d", i))
      next
    }
    key <- ""
    for (j in seq_along(r)) {
      rn <- as_number(r[j])
      if (is.na(rn) && !is.nan(rn)) {
        expect_identical(o[j], r[j], label = sprintf("line %d word %d", i, j))
        if (r[j] != "=") key <- r[j]
        next
      }
      on <- as_number(o[j])
      label <- sprintf("line %d (%s): %s vs SOLAR %s", i, key, o[j], r[j])
      if (is.nan(rn)) {
        # SOLAR leaves the SEs unset (nan) when the Hessian is singular; the
        # port reports 0 there instead (src/fphi.cc)
        expect(is.nan(on) || identical(on, 0), paste(label, "- expected nan or 0"))
      } else {
        t <- if (key %in% loose) loose_tol else tol
        expect(!is.na(on) && abs(on - rn) <= t * max(abs(rn), .Machine$double.eps),
               label)
      }
    }
  }
}

test_that("solar format matches original SOLAR for CC at threshold 0", {
  expect_solar_equal(run_solar_format(0), readLines(test_path("fixtures", "solar-CC-t0.out")))
})

test_that("solar format matches original SOLAR for CC at threshold 1", {
  # Every kinship is below 1, so the matrix is the identity: h2r stays at its
  # start value 0.5, the Hessian is singular and SOLAR reports every SE as nan
  # (the port as 0)
  expect_solar_equal(run_solar_format(1), readLines(test_path("fixtures", "solar-CC-t1.out")))
})
