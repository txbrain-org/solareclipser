library(R6)
library(stringr)

#' R6 Class Solar
#'
#' @description
#' This class is used to interact with `solar` and the files that are
#' created during analysis. The interface's methods and their arguments mimic
#' the `solar` CLI and their arguments when appropriate.
#'
#' @details
#' TODO: add more details
#'
#' @examples
#' \dontrun{
#'
#' #==================== Ex. fphi() ====================
#' solar <- Solar$new()
#' solar$load(obj = "pedigree",
#'            fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
#'            cond = "-t 0")
#' solar$load(obj = "phenotypes",
#'            fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
#' solar$trait("CC")
#' solar$create_evd_data(output_fbasename = "evd_data")
#' solar$fphi(evd_data = "evd_data")
#' solar$run()
#'
#' #==================== Ex. polygenic() ====================
#' solar <- Solar$new()
#' solar$load(obj = "pedigree",
#'            fpath = "tests/input/solar/HCP_imputed_filtered_ped.csv",
#'            cond = "-t 0")
#' solar$load(obj = "phenotypes",
#'            fpath = "tests/input/solar/HCP_WM_ave_norm.csv")
#' solar$trait("CC")$polygenic()
#' solar$run()
#'
#' #==================== Ex. save_output_dir ====================
#' solar <- Solar$new(save_output_dir = solar_output_dir)
#'
#' }
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

    set_solar_command = function(solar_command) {
      private$.solar_command <- solar_command
      invisible(self)
    },
    get_solar_command = function() {
      private$.solar_command
    },
    print_solar_command = function() {
      print(private$.solar_command)
      invisible(self)
    },

    set_loads = function(loads = NULL) {
      private$.loads <- loads
      invisible(self)
    },
    get_loads = function() {
      private$.loads
    },
    print_loads = function() {
      print(private$.loads)
      invisible(self)
    },

    set_run_rc = function(run_rc = NULL) {
      private$.run_rc <- run_rc
      invisible(self)
    },
    get_run_rc = function() {
      private$.run_rc
    },
    print_run_rc = function() {
      print(private$.run_rc)
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
      proj_wd <- getwd()
      temp_wd <- tempdir()

      # NOTE: initialize checks if the directory exists
      # TODO: fix the naming of this variable
      if (!is.null(private$.save_output_dir)) {
        temp_wd <- private$.save_output_dir
      }

      trait <- private$.solar_command$get_trait()$get_args()
      covariate <- private$.solar_command$get_covariate()$get_args()
      create_evd_data <- private$.solar_command$get_create_evd_data()
      fphi <- private$.solar_command$get_fphi()
      polygenic <- private$.solar_command$get_polygenic()$get_opts()

      strs <- load_strs_fmt(private)
      #print_string_info(strs)
      #for (str in strs) { print_string_info(str) }

      loads_str <- str_c(strs, collapse = "\n")
      trait <- str_c("trait", trait, sep = " ")
      if (!is.null(covariate)) {
        covariate <- str_c("covariate", covariate, sep = " ")
      }

      create_evd_data_fmt <- NULL
      if (private$.do_create_evd_data) {
        create_evd_data_fmt <- create_evd_data_str_fmt(create_evd_data)
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

      for (load in private$.loads) {
        if (!file.exists(load$get_fpath())) {
          stop("File does not exist: ", load$get_fpath())
        } else {
          file.copy(load$get_fpath(), temp_wd)
        }
      }

      tcl_f_realpath <- tempfile(fileext = ".tcl")
      # TODO: fix the naming of this variable
      if (!is.null(private$.save_output_dir)) {
        tcl_f_realpath <- file.path(private$.save_output_dir,
                                    basename(tcl_f_realpath))
      }
      tcl_f_basename <- basename(tcl_f_realpath)
      tcl_proc_name <- gsub("\\.tcl", "", tcl_f_basename)

      if (private$.do_create_evd_data) {
        if (private$.do_fphi) {
          cmd_fn_body <- str_c(loads_str, trait, covariate,
                               create_evd_data_fmt, fphi_fmt, sep = "\n")
        } else {
          cmd_fn_body <- str_c(loads_str, trait, covariate,
                               create_evd_data_fmt, sep = "\n")
        }
      }
      if (private$.do_polygenic) {
        cmd_fn_body <- str_c(loads_str, trait, covariate, polygenic, sep = "\n")
      }

      cmd_fn_all <- cmd_str_fmt(tcl_proc_name, cmd_fn_body)

      cat("------------------------------------------------------------\n")
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
          setwd(temp_wd)
          #print(getwd())

          private$.run_rc <- system2("solar", args = tcl_proc_name)
        }
      }

      setwd(proj_wd)
      invisible(self)
    }
  )
)

cmd_str_fmt <- function(tcl_proc_name, cmd_fn_body) {
    # proc tcl_proc_name {} { ... }
    cmd_fn_def_begin <- paste("proc", tcl_proc_name, "{} {", sep = " ")
    # indent the body of the function
    cmd_fn_body <- sapply(strsplit(cmd_fn_body, "\n"),
                          function(x) paste("  ", x, sep = ""))
    cmd_fn_def_end <- "}"
    cmd_fn_all <- c(cmd_fn_def_begin, cmd_fn_body, cmd_fn_def_end)
    return(cmd_fn_all)
}

create_evd_data_str_fmt <- function(create_evd_data) {
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

  return(create_evd_data_fmt)
}

load_strs_fmt <- function(private) {
  strs <- c()
  i <- 1
  for (load in private$.loads) {
    str <- str_c("load", private$.loads[[i]]$get_obj(),
                 private$.loads[[i]]$get_opts(),
                 basename(private$.loads[[i]]$get_fpath()),
                 private$.loads[[i]]$get_cond(),
                 sep = " ")
    strs <- c(strs, str)
    i <- i + 1
  }
  return(strs)
}

extract_load_fields <- function(loads, solar_command, debug = FALSE) {
  obj <- sapply(loads, function(x) x$get_obj())
  obj <- unlist(obj)
  
  opts <- sapply(loads, function(x) x$get_opts())
  opts <- unlist(opts)

  fpath <- sapply(loads, function(x) x$get_fpath())
  fpath <- unlist(fpath)

  cond <- sapply(loads, function(x) x$get_cond())
  cond <- unlist(cond)

  fpath_basename <- sapply(fpath, function(x) basename(x))
  fpath_basename <- unlist(fpath_basename)

  trait <- solar_command$get_trait()$get_args()
  covariate <- solar_command$get_covariate()$get_args()
  create_evd_data <- solar_command$get_create_evd_data()
  fphi <- solar_command$get_fphi()
  polygenic <- solar_command$get_polygenic()$get_opts()
  
  ret <- list(obj = obj, opts = opts, fpath = fpath, cond = cond,
              fpath_basename = fpath_basename, trait = trait,
              covariate = covariate, create_evd_data = create_evd_data,
              fphi = fphi, polygenic = polygenic)

  if (debug) {
    message("extract_load_fields() => {")
    message("  loads = {")
    message("    obj =", ret$obj)
    message("    opts =", ret$opts)
    message("    fpath =", ret$fpath)
    message("    cond =", ret$cond)
    message("    fpath_basename =", ret$fpath_basename)
    message("  }")
    message("  covariate = {")
    message("    opts =", ret$covariate)
    message("  }")
    message("  fphi = {")
    message("    opts =", ret$fphi$get_opts())
    message("    opts_fname =", ret$fphi$get_opts_fname())
    message("    precision =", ret$fphi$get_precision())
    message("    mask =", ret$fphi$get_mask())
    message("    evd_data =", ret$fphi$get_evd_data())
    message("  }")
    message("  trait = {")
    message("    args =", ret$trait)
    message("  }")
    message("  polygenic = {")
    message("    opts =", ret$polygenic)
    message("  }")
  }

  return(ret)
}

print_tcl_f_info <- function(tcl_f_realpath, tcl_f_basename, tcl_proc_name) {
  cat("tcl_f_realpath =", tcl_f_realpath, "\n")
  cat("tcl_f_basename =", tcl_f_basename, "\n")
  cat("tcl_proc_name =", tcl_proc_name, "\n")
}

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

