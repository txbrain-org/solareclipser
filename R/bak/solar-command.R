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
SolarCommand <- R6Class("SolarCommand",
  private = list(
    .load = NULL,
    .loads = c(),
    .trait = NULL,
    .covariate = NULL,
    .polygenic = NULL,
    .solar_files = NULL
  ),

  public = list(
    initialize = function() {
      private$.load <- Load$new()
      private$.trait <- Trait$new()
      private$.covariate <- Covariate$new()
      private$.polygenic <- Polygenic$new()
      private$.solar_files <- SolarFiles$new()
    },

    # Loads pedigree if it's an empirical pedigree
    # you need to set the threshold with -t
    #   load pedigree <pedigree filename>
    #
    # Loads phenotype file
    #   load phenotype <phenotype filename>
    #
    # Select trait
    #   trait <trait name>
    #
    # Select covariates
    #   covar <list of covariates>
    #
    # Run polygenic or fphi
    #   polygenic
    # or
    #   fphi
    run = function() {
      proj_wd <- getwd()
      temp_wd <- tempdir()

      #-- Section creating the string for loads
      loads <- c()
      loads <- self$get_loads()
      #print_string_info(loads)

      obj <- sapply(loads, function(x) x$get_obj())
      obj <- unlist(obj)
      #print_string_info(obj)
      cat("obj =", obj, "\n")

      args <- sapply(loads, function(x) x$get_args())
      args <- unlist(args)
      #print_string_info(args)
      cat("args =", args, "\n")

      opts <- sapply(loads, function(x) x$get_opts())
      opts <- unlist(opts)
      #print_string_info(opts)
      cat("opts =", opts, "\n")

      args_basename <- sapply(args, function(x) basename(x))
      args_basename <- unlist(args_basename)
      #print_string_info(args_basename)
      cat("args_basename =", args_basename, "\n")

      trait <- self$get_trait()
      trait <- trait$get_args()
      #print_string_info(trait)
      cat("trait =", trait, "\n")

      covariate <- self$get_covariate()
      covariate <- covariate$get_args()
      #print_string_info(covariate)
      cat("covariate =", covariate, "\n")

      polygenic <- self$get_polygenic()
      polygenic <- polygenic$get_opts()
      cat("polygenic =", polygenic, "\n")


      cat("------------------------------------------------------------\n")

      strs <- c()
      i <- 1
      for (load in loads) {
        obj <- load$get_obj()
        opts <- load$get_opts()
        args_bn <- args_basename[i]
        str <- str_c("load", obj, opts, args_bn, sep = " ")
        strs <- c(strs, str)
        i <- i + 1
      }
      #print_string_info(strs)
      #for (str in strs) { print_string_info(str) }

      loads_str <- str_c(strs, collapse = "\n")
      trait <- str_c("trait", trait, sep = " ")
      covariate <- str_c("covariate", covariate, sep = " ")
      polygenic <- str_c("polygenic", polygenic, sep = " ")

      cat(loads_str, "\n")
      cat(trait, "\n")
      cat(covariate, "\n")
      cat(polygenic, "\n")

      for (file in args) {
        if (!file.exists(file)) {
          stop("File does not exist: ", file)
        } else {
          # copy file to temp dir
          file.copy(file, temp_wd)
        }
      }

      tcl_f_realpath <- tempfile(fileext = ".tcl")
      tcl_f_basename <- basename(tcl_f_realpath)
      # remove .tcl from basename
      tcl_proc_name <- gsub("\\.tcl", "", tcl_f_basename)
      #cat("tcl_f_realpath =", tcl_f_realpath, "\n")
      #cat("tcl_f_basename =", tcl_f_basename, "\n")
      #cat("tcl_proc_name =", tcl_proc_name, "\n")

      # proc tcl_proc_name {} { ... }
      cmd_fn_def_begin <- paste("proc", tcl_proc_name, "{} {", sep = " ")
      cmd_fn_body <- str_c(loads_str, trait, covariate, polygenic, sep = "\n")
      # indent the body of the function
      cmd_fn_body <- sapply(strsplit(cmd_fn_body, "\n"), function(x) paste("  ", x, sep = ""))
      cmd_fn_def_end <- "}"
      cmd_fn_all <- c(cmd_fn_def_begin, cmd_fn_body, cmd_fn_def_end)

      cat("\n")
      cat(cmd_fn_all, sep = "\n")
      cat("\n")

      if(dir.exists(temp_wd)) {
        if(!file.exists(tcl_f_realpath)) {
          message(tcl_f_realpath, " does not exist, creating...")
          f_con <- file(tcl_f_realpath, open = "w")
          writeLines(cmd_fn_all, con = f_con)
          close(f_con)
          #file.show(tcl_f_realpath)

          # run tcl file
          setwd(temp_wd)
          # print the current working directory
          #print(getwd())

          system2("solar", args = tcl_proc_name)
          system2("ls", args = "-l")

          # copy temp_wd to another /tmp dir so we can inspect the files
          
        }
      }

      #system2("ls", args = "-l")
      setwd(proj_wd)
      invisible(self)
    },

    about = function() {
      invisible(self)
    },

    #load = function(obj, file_name) {
    load = function(obj = NA, opts = NA, args = NA) {
      private$.load <- Load$new(obj, opts, args)
      private$.loads <- c(private$.loads, private$.load)
      invisible(self)
    },

    trait = function(args) {
      private$.trait <- Trait$new(args)
      invisible(self)
    },

    covariate = function(covariate) {
      private$.covariate <- Covariate$new(covariate)
      invisible(self)
    },

    polygenic = function() {
      private$.polygenic <- Polygenic$new()
      invisible(self)
    },

    get_load = function() {
      private$.load
    },

    get_trait = function() {
      private$.trait
    },

    get_covariate = function() {
      private$.covariate
    },

    get_polygenic = function() {
      private$.polygenic
    },

    get_loads = function() {
      private$.loads
    },

    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },

    print_private = function(field = NULL) {
      if (is.null(field)) {
        private$.load$print()
        private$.trait$print()
        private$.covariate$print()
        private$.polygenic$print()
        private$.solar_files$print()
        invisible(self)
        return()
      }
      if (field == "load") {
        private$.load$print()
      }
      if (field == "trait") {
        private$.trait$print()
      }
      if (field == "covariate") {
        private$.covariate$print()
      }
      if (field == "polygenic") {
        private$.polygenic$print()
      }
      if (field == "solar_files") {
        private$.solar_files$print()
      }
      if (field == "loads") {
        sapply(private$.loads, function(x) x$print())
      }
      invisible(self)
    },

    finalize = function() {
      #message("finalize(SolarCommand)")
    }
  )
)

#' R6 Class Load
#'
#' @description
#' TODO: add description.
#'
#' @details
#' From the Solar manual:
#'
#'   load <object-type> [<opts>] <args>
#'
#' EXAMPLES:
#'   load pedigree <filename>
#'   load phenotypes <filename>
#'   load matrix [-sample | -allow] <filename> <name1> [<name2>]
#'   load matrix [-cols <tcl-list>] <filename> ;# MathMatrix
#'   load model <filename>
#'   load freq [-nosave] <filename>
#'   load marker [-xlinked] <filename>
#'   load map [-haldane | -kosambi] <filename>
#'
Load <- R6Class("Load",
  private = list(
    .obj = c(),
    .opts = c(),
    .args = c(),

    .valid_objs = c("pedigree", "phenotypes", "matrix",
                    "model", "freq", "marker", "map"),
    .valid_opts = c("-sample", "-allow", "-cols", "-nosave",
                    "-xlinked", "-haldane", "-kosambi"),

    # TODO: Write tests then add more opts
    .current_supported_objs = c("pedigree", "phenotypes"),
  ),

  public = list(
    initialize = function(obj = NULL, opts = NULL, args = NULL) {
      if (!is.null(obj)) {
        if (!obj %in% private$.valid_objs) {
          stop("SolarLoad: Invalid object type - ", obj)
        }
        if (!obj %in% private$.current_supported_objs) {
          stop("SolarLoad: Object type not currently supported - ", obj)
        }
        private$.obj <- obj
      }
      # opts aren't missing and has "-"
      if (!is.null(opts) && grepl("-", opts)) {
        if (!opts %in% private$.valid_opts) {
          stop("SolarLoad: Invalid option: ", opts)
        }
        if (!opts %in% private$.current_supported_opts) {
          stop("SolarLoad: Option not currently supported: ", opts)
        }
        private$.opts <- opts
      }
      if (!is.null(args)) {
        if (!file.exists(args)){
          stop("SolarLoad: File does not exist: ", args)
        }
        private$.args <- args
      }
    },

    get_obj = function() {
      private$.obj
    },
    get_opts = function() {
      private$.opts
    },
    get_args = function() {
      private$.args
    },

    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },

    finalize = function() {
      #message("finalize(Load)")
    }
  )
)

#' R6 Class Trait
#'
#' @description
#' TODO: add description.
#'
#' @details
#' From the Solar manual:
#'
#' USAGE:
#'   trait                               ; show current trait info
#'   trait <trait1>                      ; selects one trait
#'   trait [<traiti> ]+                  ; multivariate (up to 20)
#'   trait -noparm [<traiti> ]+          ; don't touch parameters at all
#'   [define <defname> = <expression>]+  ; Define any expressions as
#'   trait [<phenotype>|<defname> ]+     ; traits...see "help define"
#'
#' EXAMPLES:
#'   trait bmi
#'   trait q1 q2
#'   define a = 10 * log(q4)
#'   trait a q3
#'
Trait <- R6Class("Trait",
  private = list(
    .args = NULL
    # TODO: Add valid traits, this will have to come after the file loaded
    # .valid_args = c()
  ),
  public = list(
    initialize = function(args = NULL) {
      if (!is.null(args)) {
        private$.args <- args
      }
    },
    print = function() {
      if (!is.null(private$.args)) {
        cat(format(self), sep = "\n")
        invisible(self)
      }
    },
    finalize = function() {
      #message("finalize(Trait)")
    },
    get_args = function() {
      private$.args
    }
  )
)

#' R6 Class Covariate
#'
#' @description
#' TODO: add description.
#'
#' @details
#' From the Solar manual:
#'
#' USAGE:
#'   covariate <variable>[^n | ^1,2[,3...]][*<variable> | #<variable>
#'                                               [([trait])]]*
#'   Creates a new covariate.  See below for examples.
#'                                        ;
#'   covariate                      ; display all covariate info
#'   covariate delete <string>      ; deletes covariate and beta(s)
#'   covariate delete_all           ; deletes all covariates and beta(s)
#'                                  ;
#'   covariate <variable>()         ; Null Covariate: require var in
#'                                  ;   sample without covariation
#'                                  ;
#'                                  ; Covariate Suspension (for
#'                                  ;   temporary hypothesis testing).
#'   covariate suspend <string>     ; temporarily disable covariate
#'   covariate restore <string>     ; re-activate suspended covariate
#'
#' EXAMPLES:
#'   covariate age                       ; Simple covariate Age
#'   covariate age*sex                   ; Age by Sex interaction (only)
#'   covariate age*diabet*diameds        ; 3-way interaction
#'   covariate age^2                     ; Age squared as a simple covariate
#'   covariate age^1,2                   ; Shorthand for: age age^2
#'   covariate age#diabet                ; Shorthand for the following:
#'                                       ;   covariate age diabet age*diabet
#'   covariate age^1,2,3#sex             ; Shorthand for all the following:
#'       covariate sex age age*sex age^2 age^2*sex age^3 age^3*sex
#'
#'   covariate sex age(q1) age*sex(q3)   ; Trait-specific Covariates:
#'                                       ;   covariate sex applied to all traits
#'                                       ;   covariate age applied to trait q1
#'                                       ;   covariate age*sex applied to q3
#'
Covariate <- R6Class("Covariate",
  private = list(
    .args = c()
    # TODO: Add valid covar, this will have to come after the file loaded
    # .valid_covars = c()
  ),
  public = list(
    initialize = function(args = NULL) {
      if (!is.null(args)) {
        private$.args <- args
      }
    },
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    finalize = function() {
      #message("finalize(Covariate)")
    },
    get_args = function() {
      private$.args
    }
  )
)

#' R6 Class Polygenic
#'
#' @description
#' TODO: Add description
#'
#' @details
#' From the Solar manual:
#'
#' USAGE:
#'   polygenic [-screen] [-all] [-p | -prob <p>] [-fix <covar>]
#'             [-testcovar <covar>] [-testrhoe] [-testrhog] [-testrhoc]
#'             [-sporadic] [-keephouse] [-testrhop] [-rhopse] [-fphi]
#'
#'   (screencov is an alias for 'polygenic -screen')
#'   (sporadic is an alias for 'polygenic -sporadic')
#'
#'   Typically before giving this command, you will give trait,
#'   covariate, and house (if applicable) commands.  You will also load
#'   pedigree and phenotypes files if they have not already been loaded.
#'
#' EXAMPLES:
#'   solar> load pedigree ped
#'   solar> load phenotypes phen
#'   solar> trait hbp
#'   solar> covariate age sex age*sex smoke
#'   solar> polygenic -screen
#'
Polygenic <- R6Class("Polygenic",
  private = list(
    .opts = NULL,
    .valid_opts = c("-screen", "-all", "-p", "-prob", "-fix",
                    "-testcovar", "-testrhoe", "-testrhog", "-testrhoc",
                    "-sporadic", "-keephouse", "-testrhop", "-rhopse",
                    "-fphi")
  ),
  public = list(
    initialize = function(opts = NULL) {
      if (!is.null(NULL) && grepl("-", opts)) {
        if (!opts %in% private$.valid_opts) {
          stop("SolarPolygenic: Invalid option - ", opts)
        }
        private$.opts <- opts
      }
    },
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    finalize = function() {
      #message("finalize(Polygenic)")
    },
    get_opts = function() {
      private$.opts
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

