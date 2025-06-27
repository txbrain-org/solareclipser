library(R6)
library(stringr)

#' @title R6 Class: Solar
#'
#' @description
#' This class is used to interact with `solar` and the files that are
#' created during analysis. The interface's methods and their arguments mimic
#' the `solar` CLI and their arguments when appropriate.
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
#' }
#' @field cmd A named list of command functions including `load`, `trait`, `polygenic`, `create_evd_data`, `fphi`, and `pedifromsnp`, each of which configures and runs a corresponding SOLAR subcommand.
#'
#' @section Methods:
#'
#' - `initialize(settings = NULL)`: Constructor method. Accepts optional settings for output directory and flags.
#' - `print()`: Displays a formatted summary of the Solar object.
#' - `finalize()`: Finalizer hook to clean up when the object is garbage-collected.
#' - `set_run_rc(run_rc = NULL)`: Store the return code from a run.
#' - `get_run_rc()`: Retrieve the return code.
#' - `set_settings(settings = NULL)`: Set configuration settings.
#' - `run()`: Builds and executes the SOLAR command pipeline.
#'
#' @param settings A named list of configuration values including `output$dir`, `output$tcl`, and `output$stdout_and_stderr`.
#' @param run_rc Return code from a previous SOLAR run (numeric or character).
#' @param obj Object to be passed to the `load` command.
#' @param opts Options to pass to `load`, `fphi`, or other SOLAR commands.
#' @param fpath Path to input data.
#' @param cond A condition or filter to apply in data loading.
#' @param args Arguments for `trait` or `covariate` commands.
#' @param output_fbasename Base filename for EVD data output.
#' @param plink_fbasename Base filename for PLINK input data.
#' @param use_covs Logical, whether to use covariates in the analysis.
#' @param opts_fname Path to a file with options.
#' @param precision Precision level for `fphi`.
#' @param mask Path to a NIfTI mask image.
#' @param evd_data Path to EVD data base file.
#' @param input_fbase,output_fbase,freq_fbase Base filenames for `pedifromsnp` processing.
#' @param corr,per_chromo,king,method_two Logical flags for `pedifromsnp` behavior.
#' @param batch_size,id_list,n_threads Parallelization parameters for `pedifromsnp`.
#'
#' @return An object of class `Solar`.
#'
#' @md
#' @export
Solar <- R6Class("Solar",
  private = list(
    .solar_command = NULL,
    .loads = NULL,

    .do_polygenic = FALSE,
    .do_create_evd_data = FALSE,
    .do_fphi = FALSE,

    .run_rc = NULL,

    .settings = list(
      output = list(
        dir = NULL,
        tcl = FALSE,
        stdout_and_stderr = FALSE
      )
    )
  ),

  public = list(
    cmd = NULL,

    #' @param settings Named list with configuration like `output$dir`, `output$tcl`, etc.
    #' @md
    initialize = function(settings = NULL) {
      private$.solar_command <- SolarCommand$new()

      self$cmd <- list(
        load = function(obj = NULL, opts = NULL, fpath = NULL, cond = NULL) {
          private$.solar_command$load(obj = obj, opts = opts,
                                      fpath = fpath, cond = cond)
          private$.loads <- private$.solar_command$get_loads()
          invisible(self$cmd)
        },
        trait = function(args = NULL) {
          private$.solar_command$trait(args)
          invisible(self$cmd)
        },
        polygenic = function() {
          private$.solar_command$polygenic()
          private$.do_polygenic <- TRUE
          invisible(self$cmd)
        },
        create_evd_data = function(output_fbasename = NULL,
                                   plink_fbasename = NULL, use_covs = FALSE) {
          private$.solar_command$create_evd_data(output_fbasename,
                                                 plink_fbasename, use_covs)
          private$.do_create_evd_data <- TRUE
          invisible(self$cmd)
        },
        fphi = function(opts = NULL, opts_fname = NULL,
                        precision = NULL, mask = NULL, evd_data = NULL) {
          private$.solar_command$fphi(opts, opts_fname,
                                      precision, mask, evd_data)
          private$.do_fphi <- TRUE
          invisible(self$cmd)
        },
        pedifromsnp = function(input_fbase = NULL, output_fbase = NULL,
                               freq_fbase = NULL, corr = NULL,
                               per_chromo = FALSE, king = FALSE,
                               method_two = FALSE, batch_size = NULL,
                               id_list = NULL, n_threads = NULL) {
          private$.solar_command$pedifromsnps(input_fbase, output_fbase,
                                              freq_fbase, corr, per_chromo,
                                              king, method_two, batch_size,
                                              id_list, n_threads)
          invisible(self$cmd)
        }
      )

      if (!is.null(settings)) {
        # TODO: check for existence of settings$output$dir
        if (!is.null(settings$output$dir)) {
          private$.settings$output$dir <- settings$output$dir
        }
        if (!is.null(settings$output$tcl)) {
          private$.settings$output$tcl <- settings$output$tcl
        }
        if (!is.null(settings$output$stdout_and_stderr)) {
          private$.settings$output$stdout_and_stderr <-
            settings$output$stdout_and_stderr
        }
      }
      invisible(self)
    },

    #' @return Invisibly returns the object.
    #' @md
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },

    #' @param run_rc Integer or character. Return code from `system2()`.
    #' @md
    set_run_rc = function(run_rc = NULL) {
      private$.run_rc <- run_rc
      invisible(self)
    },

    #' @return Return code (integer or character).
    #' @md
    get_run_rc = function() {
      private$.run_rc
    },

    #' @param settings Named list with `output$dir`, `tcl`, etc.
    #' @md
    set_settings = function(settings = NULL) {
      private$.settings <- settings
      invisible(self)
    },

    #' @return Invisibly returns the object.
    #' @md
    run = function() {
      proj_wd <- getwd()
      temp_wd <- tempdir()

      # NOTE: initialize checks if the directory exists
      # TODO: fix the naming of this variable
      if (!is.null(private$.settings$output$dir)) {
        temp_wd <- private$.settings$output$dir
      }

      trait <- private$.solar_command$get_trait()$get_args()
      covariate <- private$.solar_command$get_covariate()$get_args()
      create_evd_data <- private$.solar_command$get_create_evd_data()
      fphi <- private$.solar_command$get_fphi()
      polygenic <- private$.solar_command$get_polygenic()$get_opts()

      strs <- load_strs_fmt(private)
      #print_string_info(strs)
      #for (str in strs) { print_string_info(str) }

      loads_str <- stringr::str_c(strs, collapse = "\n")
      trait <- stringr::str_c("trait", trait, sep = " ")
      if (!is.null(covariate)) {
        covariate <- stringr::str_c("covariate", covariate, sep = " ")
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
            stringr::str_c("fphi --evd_data", fphi$get_opts(), fphi$get_opts_fname(),
                  fphi$get_precision(), fphi$get_mask(), fphi$get_evd_data(),
                  sep = " ")
        }
      }

      if (private$.do_polygenic) {
        polygenic <- stringr::str_c("polygenic", polygenic, sep = " ")
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
      if (!is.null(private$.settings$output$dir)) {
        tcl_f_realpath <- file.path(private$.settings$output$dir,
                                    basename(tcl_f_realpath))
      }
      tcl_f_basename <- basename(tcl_f_realpath)
      tcl_proc_name <- gsub("\\.tcl", "", tcl_f_basename)

      if (private$.do_create_evd_data) {
        if (private$.do_fphi) {
          cmd_fn_body <- stringr::str_c(loads_str, trait, covariate,
                               create_evd_data_fmt, fphi_fmt, sep = "\n")
        } else {
          cmd_fn_body <- stringr::str_c(loads_str, trait, covariate,
                               create_evd_data_fmt, sep = "\n")
        }
      }
      if (private$.do_polygenic) {
        cmd_fn_body <- stringr::str_c(loads_str, trait, covariate, polygenic, sep = "\n")
      }

      cmd_fn_all <- cmd_str_fmt(tcl_proc_name, cmd_fn_body)

      if (private$.settings$output$tcl) {
        message("==============================> tcl <==============================\n")
        cat("\n")
        cat(cmd_fn_all, sep = "\n")
        cat("\n")
        message("===================================================================\n")
      }
      
      if(dir.exists(temp_wd)) {
        if(!file.exists(tcl_f_realpath)) {
          #message(tcl_f_realpath, " does not exist, creating...")
          f_con <- file(tcl_f_realpath, open = "w")
          writeLines(cmd_fn_all, con = f_con)
          close(f_con)
          #file.show(tcl_f_realpath)
          setwd(temp_wd)
          #print(getwd())

          if (private$.settings$output$stdout_and_stderr) {
            # TODO: Maybe print solar settings here
            #print("stdout_and_stderr = TRUE")
            private$.run_rc <- system2("solar", args = tcl_proc_name,
                                       stdout = TRUE, stderr = TRUE)

            # do ==... stdout_and_stderr ... ===
            message("=======================> stdout_and_stderr <=======================\n")
            cat(private$.run_rc, sep = "\n")
            message("===================================================================\n")
          } else {
            # TODO: Maybe print solar settings here
            #print("stdout_and_stderr = FALSE")
            # TODO: maybe the message should be an optional output
            message("Executing solar command... ", appendLF = FALSE)
            private$.run_rc <- system2("solar", args = tcl_proc_name,
                                       stdout = TRUE, stderr = TRUE)
            message("Done.")
          }
        }
      }

      setwd(proj_wd)
      invisible(self)
    }
  )
)

#' @title Format a TCL Command Procedure for SOLAR
#' @description Creates a TCL procedure string with the correct header and body.
#'
#' @param tcl_proc_name Character. The name of the TCL procedure.
#' @param cmd_fn_body Character. The body of the TCL command.
#'
#' @return A character vector representing the full TCL function.
#'
#' @md
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

#' @title Format EVD Data Creation Command
#' @description Constructs the SOLAR command string for EVD data creation.
#'
#' @param create_evd_data An object returned by `get_create_evd_data()` containing output file paths and flags.
#'
#' @return A single character string representing the `create_evd_data` command.
#'
#' @md
create_evd_data_str_fmt <- function(create_evd_data) {
  create_evd_data_fmt <-
    stringr::str_c("create_evd_data --o ", create_evd_data$get_output_fbasename())

  if (!is.null(create_evd_data$get_plink_fbasename())) {
    create_evd_data_fmt <-
      stringr::str_c(create_evd_data_fmt, " --plink ",
            create_evd_data$get_plink_fbasename())
  }

  if (create_evd_data$get_use_covs() == TRUE) {
    create_evd_data_fmt <- stringr::str_c(create_evd_data_fmt, " --use_covs")
  }

  return(create_evd_data_fmt)
}

#' @title Format Load Commands
#' @description Formats the `load` statements from internal `private$.loads` object.
#'
#' @param private A reference to the private environment of the Solar class.
#'
#' @return A character vector of `load` command strings for use in TCL output.
#'
#' @md
load_strs_fmt <- function(private) {
  strs <- c()
  i <- 1
  for (load in private$.loads) {
    str <- stringr::str_c("load", private$.loads[[i]]$get_obj(),
                 private$.loads[[i]]$get_opts(),
                 basename(private$.loads[[i]]$get_fpath()),
                 private$.loads[[i]]$get_cond(),
                 sep = " ")
    strs <- c(strs, str)
    i <- i + 1
  }
  return(strs)
}

#' @title Extract Load and Trait Configuration
#' @description Extracts relevant fields from the internal command and load objects for debugging or downstream logic.
#'
#' @param loads A list of `load` command objects.
#' @param cmd A command object containing trait and covariate info.
#' @param debug Logical. If `TRUE`, prints field values.
#'
#' @return A named list of extracted fields (e.g., `obj`, `fpath`, `trait`, etc.)
#'
#' @md
extract_load_fields <- function(loads, cmd, debug = FALSE) {
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

  trait <- cmd$get_trait()$get_args()
  covariate <- cmd$get_covariate()$get_args()
  create_evd_data <- cmd$get_create_evd_data()
  fphi <- cmd$get_fphi()
  polygenic <- cmd$get_polygenic()$get_opts()
  
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

#' @title Print TCL File Information
#' @description Utility to print full TCL file paths and metadata.
#'
#' @param tcl_f_realpath Full path to TCL script.
#' @param tcl_f_basename Basename of TCL script.
#' @param tcl_proc_name Name of the TCL procedure.
#'
#' @return None. Prints output to console.
#'
#' @md
print_tcl_f_info <- function(tcl_f_realpath, tcl_f_basename, tcl_proc_name) {
  cat("tcl_f_realpath =", tcl_f_realpath, "\n")
  cat("tcl_f_basename =", tcl_f_basename, "\n")
  cat("tcl_proc_name =", tcl_proc_name, "\n")
}

#' @title Print Info About a String
#' @description Prints debug information about a character string including its content, class, and length.
#'
#' @param str A character string.
#'
#' @return None. Output is printed to console for inspection.
#'
#' @md
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
