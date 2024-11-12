library(testthat)
library(withr)

test_that("fphi - testbench_init(tmp = TRUE)", {
  testbench <- testbench_init(tmp = TRUE)
  cc_evd_out_all_fpaths <- c(
    file.path(testbench$settings$output$dir, "CC_evd.eigenvalues"),
    file.path(testbench$settings$output$dir, "CC_evd.eigenvectors"),
    file.path(testbench$settings$output$dir, "CC_evd.ids"),
    file.path(testbench$settings$output$dir, "CC_evd.notes")
  )
  c_evd_out_fbn <- file.path("CC_evd")

  solar <- Solar$new(settings = testbench$settings)
  solar$cmd$load(obj = "pedigree",
                 fpath = testbench$pedigree_fpath,
                 cond = "-t 0")
  solar$cmd$load(obj = "phenotypes",
                 fpath = testbench$phenotypes_fpath)
  solar$cmd$trait("CC")
  solar$cmd$create_evd_data(output_fbasename = c_evd_out_fbn)
  solar$cmd$fphi(evd_data = c_evd_out_fbn)
  solar$run()

  label <- paste("is.null(", solar$get_run_rc(), ")")
  expect_false(is.null(solar$get_run_rc()), label = label)

  for (fpath in cc_evd_out_all_fpaths) {
    label <- paste("file.exists(", fpath, ")")
    expect_true(file.exists(fpath), label = label)
    expect_true(file.size(fpath) > 0, label = label)
  }
})

test_that("fphi - testbench_init(tmp = FALSE)", {
  testbench <- testbench_init(tmp = FALSE)
  cc_evd_out_all_fpaths <- c(
    file.path(testbench$settings$output$dir, "CC_evd.eigenvalues"),
    file.path(testbench$settings$output$dir, "CC_evd.eigenvectors"),
    file.path(testbench$settings$output$dir, "CC_evd.ids"),
    file.path(testbench$settings$output$dir, "CC_evd.notes")
  )
  c_evd_out_fbn <- file.path("CC_evd")

  solar <- Solar$new(settings = testbench$settings)
  solar$cmd$load(obj = "pedigree",
                 fpath = testbench$pedigree_fpath,
                 cond = "-t 0")
  solar$cmd$load(obj = "phenotypes",
                 fpath = testbench$phenotypes_fpath)
  solar$cmd$trait("CC")
  solar$cmd$create_evd_data(output_fbasename = c_evd_out_fbn)
  solar$cmd$fphi(evd_data = c_evd_out_fbn)
  solar$run()

  label <- paste("is.null(", solar$get_run_rc(), ")")
  expect_false(is.null(solar$get_run_rc()), label = label)

  for (fpath in cc_evd_out_all_fpaths) {
    label <- paste("file.exists(", fpath, ")")
    expect_true(file.exists(fpath), label = label)
    expect_true(file.size(fpath) > 0, label = label)
  }
})
