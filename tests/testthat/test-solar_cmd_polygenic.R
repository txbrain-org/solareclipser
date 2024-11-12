library(testthat)
library(withr)

test_that("polygenic - testbench_init(tmp = TRUE)", {
  testbench <- testbench_init(tmp = TRUE)

  solar <- Solar$new(settings = testbench$settings)
  solar$cmd$load(obj = "pedigree",
                 fpath = testbench$pedigree_fpath,
                 cond = "-t 0")
  solar$cmd$load(obj = "phenotypes",
                 fpath = testbench$phenotypes_fpath)
  solar$cmd$trait("CC")
  solar$cmd$polygenic()
  solar$run()

  label <- paste("is.null(", solar$get_run_rc(), ")")
  expect_false(is.null(solar$get_run_rc()), label = label)
})

test_that("polygenic - testbench_init(tmp = FALSE)", {
  testbench <- testbench_init(tmp = FALSE)

  solar <- Solar$new(settings = testbench$settings)
  solar$cmd$load(obj = "pedigree",
                 fpath = testbench$pedigree_fpath,
                 cond = "-t 0")
  solar$cmd$load(obj = "phenotypes",
                 fpath = testbench$phenotypes_fpath)
  solar$cmd$trait("CC")
  solar$cmd$polygenic()
  solar$run()

  label <- paste("is.null(", solar$get_run_rc(), ")")
  expect_false(is.null(solar$get_run_rc()), label = label)
})
