library(R6)
library(stringr)

#' R6 Class Solar
#'
#' @description
#' TODO: add description.
#'
#' @details
#' Example solar command steps:
#'   load phen HCP_WM_ave_norm.csv
#'   trait CC
#'   polygen
#'
#' @export
Solar <- R6Class("Solar",
  private = list(
    .solar_command = NULL,
    .save_output_dir = NULL,

    .loads = NULL,

    .do_polygenic = FALSE,
    .do_create_evd_data = FALSE,
    .do_fphi = FALSE,

    .run_rc = NULL
  ),

  public = list(
    initialize = function(save_output_dir = NULL) {
      if (!is.null(save_output_dir)) {
        private$.save_output_dir <- save_output_dir
      } else {
        private$.save_output_dir <- tempdir()
      }
      private$.solar_command <-
        SolarCommand$new()
      invisible(self)
    },
    print = function(opts = NULL) {
      if (!is.null(opts)) {
        if (opts == "all") {
          cat("<Solar>\n")
          cat("  save_output_dir:    ", private$.save_output_dir, "\n")
          cat("  do_polygenic:       ", private$.do_polygenic, "\n")
          cat("  do_create_evd_data: ", private$.do_create_evd_data, "\n")
          cat("  do_fphi:            ", private$.do_fphi, "\n")
          print(private$.loads)
          print(private$.solar_command)
        }
        return(invisible(self))
      }
      cat(format(self), sep = "\n")
      invisible(self)
    },
    finalize = function() {
      #message("finalize(SolarCommand)")
    },

    get_solar_command = function() {
      private$.solar_command
      invisible(self)
    },
    set_solar_command = function(solar_command) {
      private$.solar_command <- solar_command
      invisible(self)
    },

    set_loads = function(loads = NULL) {
      private$.loads <- loads
      invisible(self)
    },
    get_loads = function() {
      private$.loads
      invisible(self)
    },

    set_run_rc = function(run_rc = NULL) {
      private$.run_rc <- run_rc
      invisible(self)
    },
    get_run_rc = function() {
      private$.run_rc
      invisible(self)
    },

    load = function(obj = NULL, opts = NULL, fpath = NULL, cond = NULL) {
      private$.solar_command$set_load(obj = obj,
                                      opts = opts,
                                      fpath = fpath,
                                      cond = cond)
      private$.loads <- c(private$.loads,
                          private$.solar_command$get_load())
      invisible(self)
    },

    trait = function(args = NULL) {
      private$.solar_command$set_trait(args)
      invisible(self)
    },

    covariate = function(covariate = NULL) {
      private$.solar_command$set_covariate(covariate)
      invisible(self)
    },

    polygenic = function() {
      private$.solar_command$set_polygenic()
      private$.do_polygenic <- TRUE
      invisible(self)
    },

    create_evd_data = function(output_fbasename = NULL,
                               plink_fbasename = NULL,
                               use_covs = FALSE) {
      private$.solar_command$set_create_evd_data(output_fbasename,
                                                 plink_fbasename,
                                                 use_covs)
      private$.do_create_evd_data <- TRUE
      invisible(self)
    },

    fphi = function(opts = NULL, opts_fname = NULL,
                    precision = NULL, mask = NULL,
                    evd_data = NULL) {
      private$.solar_command$set_fphi(opts, opts_fname,
                                      precision, mask,
                                      evd_data)
      private$.do_fphi <- TRUE
      invisible(self)
    },

    run = function() {
      #private$.solar_command$run()
      proj_wd <- getwd()
      temp_wd <- tempdir()

      # NOTE: initialize checks if the directory exists
      # TODO: fix the naming of this variable
      if (!is.null(private$.save_output_dir)) {
        temp_wd <- private$.save_output_dir
      }

      # (obj = NULL, opts = NULL, fpath = NULL, cond = NULL)
      #-- Section creating the string for loads
      loads <- private$.loads
      #print(private$.loads)

      obj <- sapply(private$.loads, function(x) x$get_obj())
      obj <- unlist(obj)
      #print_string_info(obj)
      #cat("obj =", obj, "\n")

      opts <- sapply(private$.loads, function(x) x$get_opts())
      opts <- unlist(opts)
      #print_string_info(opts)
      #cat("opts =", opts, "\n")

      fpath <- sapply(private$.loads, function(x) x$get_fpath())
      fpath <- unlist(fpath)
      #print_string_info(fpath)
      #cat("fpath =", fpath, "\n")

      cond <- sapply(private$.loads, function(x) x$get_cond())
      cond <- unlist(cond)
      #print_string_info(cond)
      #cat("cond =", cond, "\n")

      fpath_basename <- sapply(fpath, function(x) basename(x))
      fpath_basename <- unlist(fpath_basename)
      #print_string_info(fpath_basename)
      #cat("fpath_basename =", fpath_basename, "\n")

      trait <- private$.solar_command$get_trait()$get_args()
      #print_string_info(trait)
      #cat("trait =", trait, "\n")

      covariate <- private$.solar_command$get_covariate()$get_args()
      #print_string_info(covariate)
      #cat("covariate =", covariate, "\n")

      create_evd_data <- private$.solar_command$get_create_evd_data()
      #create_evd_data$print()

      fphi <- private$.solar_command$get_fphi()
      ##fphi$print()

      polygenic <- private$.solar_command$get_polygenic()$get_opts()
      #polygenic <- polygenic$get_opts()
      #print_string_info(polygenic)
      #cat("polygenic =", polygenic, "\n")

      cat("------------------------------------------------------------\n")

      strs <- c()
      i <- 1
      for (load in loads) {
        obj <- load$get_obj()
        opts <- load$get_opts()
        fpath_bn <- fpath_basename[i]
        cond <- load$get_cond()
        str <- str_c("load", obj, opts, fpath_bn, cond, sep = " ")
        strs <- c(strs, str)
        i <- i + 1
      }
      #print_string_info(strs)
      #for (str in strs) { print_string_info(str) }

      loads_str <- str_c(strs, collapse = "\n")
      trait <- str_c("trait", trait, sep = " ")
      if (!is.null(covariate)) {
        covariate <- str_c("covariate", covariate, sep = " ")
      }

      create_evd_data_fmt <- NULL
      if (private$.do_create_evd_data) {
        create_evd_data_fmt <-
          str_c("create_evd_data --o ", create_evd_data$get_output_fbasename())

        if (!is.null(create_evd_data$get_plink_fbasename())) {
          create_evd_data_fmt <-
            str_c(create_evd_data_fmt, " --plink ",
                  create_evd_data$get_plink_fbasename())
        }

        if (create_evd_data$get_use_covs() == TRUE) {
          create_evd_data_fmt <- str_c(create_evd_data_fmt, " --use_covs")
        }
      }

      # TODO: implement the rest of the options
      # .opts = NULL, # -fast -debug -list
      # .opts_fname = NULL, # -list <file containing trait names>
      # .precision = NULL, # -precision <h2 decimal count>
      # .mask = NULL, # -mask <name of nifti template volume>
      # .evd_data = NULL # -evd_data <base filename of EVD data
      if (private$.do_fphi) {
        if (!is.null(fphi$get_evd_data())) {
          fphi_fmt <-
            str_c("fphi --evd_data", fphi$get_opts(), fphi$get_opts_fname(),
                  fphi$get_precision(), fphi$get_mask(), fphi$get_evd_data(),
                  sep = " ")
        }
      }

      if (private$.do_polygenic) {
        polygenic <- str_c("polygenic", polygenic, sep = " ")
      }

      #cat(loads_str, "\n")
      #cat(trait, "\n")
      #cat(covariate, "\n")
      #cat(polygenic, "\n")
      #cat(create_evd_data_fmt, "\n")
      #cat(fphi_fmt, "\n")

      for (file in fpath) {
        if (!file.exists(file)) {
          stop("File does not exist: ", file)
        } else {
          # copy file to temp dir
          file.copy(file, temp_wd)
        }
      }

      tcl_f_realpath <- tempfile(fileext = ".tcl")
      # TODO: fix the naming of this variable
      if (!is.null(private$.save_output_dir)) {
        tcl_f_realpath <- file.path(private$.save_output_dir, basename(tcl_f_realpath))
      }
      tcl_f_basename <- basename(tcl_f_realpath)
      # remove .tcl from basename
      tcl_proc_name <- gsub("\\.tcl", "", tcl_f_basename)
      #cat("tcl_f_realpath =", tcl_f_realpath, "\n")
      #cat("tcl_f_basename =", tcl_f_basename, "\n")
      #cat("tcl_proc_name =", tcl_proc_name, "\n")

      # proc tcl_proc_name {} { ... }
      cmd_fn_def_begin <- paste("proc", tcl_proc_name, "{} {", sep = " ")

      if (private$.do_create_evd_data) {
        if (private$.do_fphi) {
          cmd_fn_body <- str_c(loads_str, trait, covariate, create_evd_data_fmt, fphi_fmt, sep = "\n")
        } else {
          cmd_fn_body <- str_c(loads_str, trait, covariate, create_evd_data_fmt, sep = "\n")
        }
      }
      if (private$.do_polygenic) {
        cmd_fn_body <- str_c(loads_str, trait, covariate, polygenic, sep = "\n")
      }
      # indent the body of the function
      cmd_fn_body <- sapply(strsplit(cmd_fn_body, "\n"), function(x) paste("  ", x, sep = ""))
      cmd_fn_def_end <- "}"
      cmd_fn_all <- c(cmd_fn_def_begin, cmd_fn_body, cmd_fn_def_end)

      cat("\n")
      cat(cmd_fn_all, sep = "\n")
      cat("\n")
      cat("------------------------------------------------------------\n")

      if(dir.exists(temp_wd)) {
        if(!file.exists(tcl_f_realpath)) {
          #message(tcl_f_realpath, " does not exist, creating...")
          f_con <- file(tcl_f_realpath, open = "w")
          writeLines(cmd_fn_all, con = f_con)
          close(f_con)
          #file.show(tcl_f_realpath)

          # run tcl file
          setwd(temp_wd)
          # print the current working directory
          #print(getwd())

          
          private$.run_rc <- system2("solar", args = tcl_proc_name)
          #system2("ls", args = "-l")
        }
      }

      setwd(proj_wd)
      invisible(self)
    }
  )
)

print_string_info <- function(str) {
  message()
  message("print_string_info() => {")
  message("  str = \"", str, "\"")
  message("  class(str) = ", class(str))
  message("  nchar(str) = ", nchar(str))
  message(str(str), appendLF = FALSE)
  message("}")
  message()
}

