library(R6)
library(stringr)

#' R6 Class SolarCommand
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
    .create_evd_data = NULL,
    .fphi = NULL
  ),

  public = list(
    initialize = function() {
      private$.load <- Load$new()
      private$.trait <- Trait$new()
      private$.covariate <- Covariate$new()
      private$.polygenic <- Polygenic$new()
    },

    set_load = function(obj = NULL, opts = NULL, fpath = NULL, cond = NULL) {
      private$.load <- Load$new(obj, opts, fpath, cond)
      invisible(self)
    },

    set_trait = function(args = NULL) {
      private$.trait <- Trait$new(args)
      invisible(self)
    },

    set_covariate = function(covariate = NULL) {
      private$.covariate <- Covariate$new(covariate)
      invisible(self)
    },

    set_polygenic = function() {
      private$.polygenic <- Polygenic$new()
      invisible(self)
    },

    set_create_evd_data = function(output_fbasename = NULL,
                                   plink_fbasename = NULL,
                                   use_covs = FALSE) {

      private$.create_evd_data <-
        CreateEvdData$new(output_fbasename, plink_fbasename, use_covs)

      invisible(self)
    },

    set_fphi = function(opts = NULL, opts_fname = NULL,
                        precision = NULL, mask = NULL,
                        evd_data = NULL) {
      private$.fphi <- FPHI$new(opts, opts_fname, precision, mask, evd_data)
      invisible(self)
    },

    get_load = function() {
      private$.load
    },

    get_loads = function() {
      private$.loads
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

    get_create_evd_data = function() {
      private$.create_evd_data
    },

    get_fphi = function() {
      private$.fphi
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
        private$.create_evd_data$print()
        private$.fphi$print()
        invisible(self)
        return()
      }
      if (field == "load") {
        private$.load$print()
      }
      if (field == "loads") {
        sapply(private$.loads, function(x) x$print())
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
      if (field == "create_evd_data") {
        private$.create_evd_data$print()
      }
      if (field == "fphi") {
        private$.fphi$print()
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
#'   load pedigree    <filename>
#'   load phenotypes  <filename>
#'   load matrix      [-sample | -allow] <filename> <name1> [<name2>]
#'   load matrix      [-cols <tcl-list>] <filename> ;# MathMatrix
#'   load model       <filename>
#'   load freq        [-nosave] <filename>
#'   load marker      [-xlinked] <filename>
#'   load map         [-haldane | -kosambi] <filename>
#'
Load <- R6Class("Load",
  private = list(
    .obj = c(),
    .opts = c(),
    .fpath = c(),
    .cond = c(),

    .valid_objs = c("pedigree", "phenotypes", "matrix",
                    "model", "freq", "marker", "map"),
    .valid_opts = c("-sample", "-allow", "-cols", "-nosave",
                    "-xlinked", "-haldane", "-kosambi"),

    # TODO: Write tests then add more opts
    .current_supported_objs = c("pedigree", "phenotypes")
  ),

  public = list(
    initialize = function(obj = NULL, opts = NULL, fpath = NULL, cond = NULL) {
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
      if (!is.null(fpath)) {
        if (!file.exists(fpath)) {
          stop("SolarLoad: File does not exist: ", fpath)
        }
        private$.fpath <- fpath
      }
      if (!is.null(cond)) {
        private$.cond <- cond
      }
    },

    get_obj = function() {
      private$.obj
    },
    get_opts = function() {
      private$.opts
    },
    get_fpath = function() {
      private$.fpath
    },
    get_cond = function() {
      private$.cond
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
    #TODO: trim whitespace at end of args
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
    .args = NULL
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

#' R6 Class CreateEvdData
#'
#' @description
#' TODO: Add description
#'
#' @details
#' From the Solar manual:
#'
#' create_evd_data performs an EVD on the loaded pedigree for gwas or. gpu_gwas
#' commands. This is useful for a data set with a large number of subjects.
#'
#' USAGE:
#' create_evd_data --o <output base filename>
#'                 --plink <plink set base filename> --use_covs
#'
#' Prior to running the command select the trait that you plan to run gwas,
#' gpu_gwas, or gpu_fphi with the trait command. The --plink option specifies a
#' plink data set that will determine which ids will be used in running the
#' EVD. The --use_covs options will include the ID set of covariates specified
#' through the covariate command.  This command now allows you to enter two
#' traits at once in order to get their corresponding ID set.
#'
#' EXAMPLES:
#' Output consists of three files labeled:
#'   <output base filename>.ids --list of subject ids
#'   <output base filename>.eigenvalues --list of eigenvalues
#'   <output base filename>.eigenvectors --list of eigenvectors
#'   <output base filename>.notes --notes on the creation of the EVD data set
#'
CreateEvdData <- R6Class("CreateEvdData",
  private = list(
    .output_fbasename = NULL,
    .plink_fbasename = NULL,
    .use_covs = FALSE
  ),
  public = list(
    initialize = function(output_fbasename = NULL, plink_fbasename = NULL,
                          use_covs = FALSE) {

      if (!is.null(output_fbasename)) {
        private$.output_fbasename <- output_fbasename
      } else {
        stop("CreateEvdData: output_fbasename is required")
      }

      if (!is.null(plink_fbasename)) {
        private$.plink_fbasename <- plink_fbasename
      }
      if (!is.null(use_covs)) {
        private$.use_covs <- use_covs
      }
    },
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    finalize = function() {
      #message("finalize(Trait)")
    },
    get_output_fbasename = function() {
      private$.output_fbasename
    },
    get_plink_fbasename = function() {
      private$.plink_fbasename
    },
    get_use_covs = function() {
      private$.use_covs
    }
  )
)

#' R6 Class FPHI
#'
#' @description
#' TODO: Add description
#'
#' @details
#'   From the Solar manual:
#'   Purpose: Fast test and heritability approximation
#'
#' USAGE:
#' fphi [optional
#'      -fast -debug -list <file containing trait names>
#'      -precision <h2 decimal count>
#'      -mask <name of nifti template volume>
#'      -evd_data <base filename of EVD data]
#'
#'      -fast Performs a quick estimation run
#'      -debug Displays values at each iteration
#'      -list performs fast fphi on a list of trait (does not include covariate
#'        data)
#'      -precision number of decimals to calculate h2r
#'      -mask outputs fphi -fast results of the list of voxels from -list option
#'      -evd_data When using the -list option the EVD data option can be used
#'        to avoid having to calculate EVD data within the command
#'
#' Fast permutation and heritability inference (FPHI). FPHI is based on the
#' eigenvalue decomposition on the kinship matrix and a search through values
#' of h2r for accurate approximation of heritability values and statistical
#' inference. The default setting is the full search out to 9 decimal places of
#' h2r. The "-fast" option uses the Wald approximation. Both use log likelyhood
#' p-value estimation.  The default setting should provide very accurate h2
#' estimates that are nearly identical to the standard maximum likelihood
#' inference. The h2 values obtained using Wald approximation are usually
#' within 3% of the classical MLE values.  The same functionality is available
#' for GPU computing. Use gpu_fphi for heritability calculations in very large
#' datasets. For details see Ganjgahi et al., "Fast and powerful heritability
#' inference for family-based neuroimaging studies”.
#'
#' EXAMPLES:
#'
FPHI <- R6Class("FPHI",
  private = list(
    .opts = NULL, # -fast -debug -list
    .opts_fname = NULL, # -list <file containing trait names>

    .precision = NULL, # -precision <h2 decimal count>
    .mask = NULL, # -mask <name of nifti template volume>
    .evd_data = NULL # -evd_data <base filename of EVD data
  ),
  public = list(
    initialize = function(opts = NULL, opts_fname = NULL,
                          precision = NULL, mask = NULL,
                          evd_data = NULL) {
      if (!is.null(opts)) {
        private$.opts <- opts
      }
      if (!is.null(opts_fname)) {
        private$.opts_fname <- opts_fname
      }
      if (!is.null(precision)) {
        private$.precision <- precision
      }
      if (!is.null(mask)) {
        private$.mask <- mask
      }
      if (!is.null(evd_data)) {
        private$.evd_data <- evd_data
      }
    },
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    finalize = function() {
      #message("finalize(FPHI)")
    },
    get_opts = function() {
      private$.opts
    },
    get_opts_fname = function() {
      private$.opts_fname
    },
    get_precision = function() {
      private$.precision
    },
    get_mask = function() {
      private$.mask
    },
    get_evd_data = function() {
      private$.evd_data
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

