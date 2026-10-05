test_that("load_pedigree writes one pedigree.info line per family", {
  # Three families at threshold 0.05: {A1, A2}, {B1, B2}, {C1}.
  # Cross-family pairs have kinship 0.01, below the threshold.
  ids <- c("A1", "A2", "B1", "B2", "C1")
  family <- c("A", "A", "B", "B", "C")
  pairs <- expand.grid(IDA = ids, IDB = ids, stringsAsFactors = FALSE)
  same_family <- family[match(pairs$IDA, ids)] == family[match(pairs$IDB, ids)]
  pairs$KIN <- ifelse(pairs$IDA == pairs$IDB, 1, ifelse(same_family, 0.5, 0.01))

  pedigree_tmp_csv <- tempfile(fileext = ".csv")
  write.csv(pairs, pedigree_tmp_csv, row.names = FALSE, quote = FALSE)
  output_dir <- tempfile("ped_")
  dir.create(output_dir)

  rc <- solar_load_pedigree(pedigree_tmp_csv, threshold = 0.05, output_dir = output_dir)
  expect_equal(rc, 0)

  info <- readLines(file.path(output_dir, "pedigree.info"))
  expect_equal(info[3], "3 3 5 3")  # nped nfam nind nfou
  expect_equal(info[4:length(info)], rep("1 1 1 0 n", 3))

  solar_reset()
  unlink(output_dir, recursive = TRUE)
  unlink(pedigree_tmp_csv)
})
