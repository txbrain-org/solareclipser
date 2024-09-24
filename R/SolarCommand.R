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
SolarCommand <- R6Class("SolarCommand",
  private = list(
    .load = NULL,
    .loads = c(),
    .trait = NULL,
    .covariate = NULL,
    .polygenic = NULL,
    .create_evd_data = NULL,
    .fphi = NULL,
    .pedifromsnps = NULL
  ),

  public = list(
    initialize = function() {
      private$.load <- Load$new()
      private$.trait <- Trait$new()
      private$.covariate <- Covariate$new()
      private$.polygenic <- Polygenic$new()
      #private$.create_evd_data <- CreateEvdData$new()
      #private$.fphi <- FPHI$new()
      #private$.pedifromsnps <- PedifromSNPs$new()
    },


    load = function(obj = NULL, opts = NULL, fpath = NULL, cond = NULL) {
      private$.load <- Load$new(obj, opts, fpath, cond)
      private$.loads <- c(private$.loads, private$.load)
      invisible(self)
    },

    trait = function(args = NULL) {
      private$.trait <- Trait$new(args)
      invisible(self)
    },

    polygenic = function(opts = NULL) {
      private$.polygenic <- Polygenic$new(opts)
      invisible(self)
    },

    covariate = function(args = NULL) {
      private$.covariate <- Covariate$new(args)
      invisible(self)
    },

    create_evd_data = function(output_fbasename = NULL, plink_fbasename = NULL,
                               use_covs = FALSE) {
      private$.create_evd_data <-
        CreateEvdData$new(output_fbasename, plink_fbasename, use_covs)
      invisible(self)
    },

    fphi = function(opts = NULL, opts_fname = NULL,
                    precision = NULL, mask = NULL,
                    evd_data = NULL) {
      private$.fphi <- FPHI$new(opts, opts_fname, precision, mask, evd_data)
      invisible(self)
    },

    pedifromsnps = function(input_fbase = NULL, output_fbase = NULL,
                            freq_fbase = NULL, corr = NULL,
                            per_chromo = FALSE, king = FALSE,
                            method_two = FALSE, batch_size = NULL,
                            id_list = NULL, n_threads = NULL) {
      private$.pedifromsnps <-
        PedifromSNPs$new(input_fbase, output_fbase, freq_fbase, corr,
                         per_chromo, king, method_two, batch_size, id_list,
                         n_threads)
      invisible(self)
    },

    get_load = function() { private$.load },
    get_loads = function() { private$.loads },
    get_trait = function() { private$.trait },
    get_covariate = function() { private$.covariate },
    get_polygenic = function() { private$.polygenic },
    get_create_evd_data = function() { private$.create_evd_data },
    get_fphi = function() { private$.fphi },
    get_pedifromsnps = function() { private$.pedifromsnps },

    print = function() {
      cat(format(self), sep = "\n")
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
#' USAGE: load <object-type> [<opts>] <args>
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
#' From the Solar manual:
#'
#' Purpose: Fast test and heritability approximation
#'
#' USAGE:
#'    fphi [options]
#'
#' OPTIONAL
#'    -fast -debug -list <file containing trait names>
#'    -precision <h2 decimal count>
#'    -mask <name of nifti template volume>
#'    -evd_data <base filename of EVD data]
#'
#' DESCRIPTION
#'    -fast
#'        Performs a quick estimation run
#'    -debug
#'        Displays values at each iteration
#'    -list
#'        performs fast fphi on a list of trait (does not include covariate
#'        data)
#'    -precision
#'        number of decimals to calculate h2r
#'    -mask
#'        outputs fphi -fast results of the list of voxels from -list option
#'    -evd_data
#'        When using the -list option the EVD data option can be used to avoid
#'        having to calculate EVD data within the command
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
      cat(".opts = ", private$.opts, "\n")
      cat(".opts_fname = ", private$.opts_fname, "\n")
      cat(".precision = ", private$.precision, "\n")
      cat(".mask = ", private$.mask, "\n")
      cat(".evd_data = ", private$.evd_data, "\n")
      invisible(self)
    },
    print_self = function() {
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

#' R6 Class Pedifromsnps
#'
#' @description
#' TODO: add description.
#'
#' @details
#' From the Solar manual:
#'
#' Purpose: Creates a empirical pedigree matrix from a plink data set
#'
#' USAGE:
#' pedifromsnps -i <input base name of plink data>
#'              -o <output csv file name>
#'              --freq <file made with plink_freq>
#' OPTIONAL:
#'    -corr <alpha value>
#'    -per-chromo -king -method_two -normalize
#'    -batch_size <batch size value>
#'    -id_list <file w/ subject IDs>
#'    -n_threads <number of CPU threads>
#'
#' DESCPRIPTION:
#'    -i <file>
#'        The base file name of the plink .bed, .bim, and .fam files.
#'    -o <file>
#'        The base file name for the output.
#'    -freq <file>
#'        Name of output file from plink_freq command.
#'    -n_threads <n>
#'        Number of CPU threads used for matrix calculation.
#'        Default: Automatically set based on hardware
#'    -per-chromo
#'        Outputs a separate matrix for each chromosome.
#'        Default: Disabled
#'    -corr <alpha value>
#'        Compute method one correlation GRM using this alpha value.
#'        Default: -1
#'	  -method_two
#'        Computes correlation GRM using a second method described below.
#'        Default: Disabled
#'    -king
#'        Computes Robust King GRM instead of using a correlation method.
#'	      Default: Disabled
#'    -batch_size <batch size value>
#'        Number of loci computed at a single time per CPU thread.
#'        Default: 500
#'    -id_list <file w/ subject IDs>
#'        Specified file contains a list of subject IDs separated by spaces.
#'        The resulting GRM will only use these IDs and excluded all others.
#'        Default: All IDs are used
#'    -normalize
#'        When used during the creation of a correlation GRM the final
#'        values are normalized using the square roots of the diagonal values.
#'        The result being that diagonal elements are 1 and off-diagonal
#'        elements are bounded by 1 and -1.  Z*_i_j = Z_i_j/sqrt(Z_i_i*Z_j_j)
#'        where Z* is the final value and Z is the unnormalized value, i refers
#'        to the index of subject i while j refers to the index of subject j.
#'
PedifromSNPs <- R6Class("PedifromSNPs",
  private = list(
    # Required
    .input_fbase = NULL,
    .output_fbase = NULL,
    .freq_fbase = NULL,
    # Optional
    .corr = NULL,
    .per_chromo = FALSE,
    .king = FALSE,
    .method_two = FALSE,
    .batch_size = NULL,
    .id_list = NULL,
    .n_threads = NULL
  ),
  public = list(
    initialize = function(input_fbase = NULL, output_fbase = NULL,
                          freq_fbase = NULL, corr = NULL, per_chromo = FALSE,
                          king = FALSE, method_two = FALSE, batch_size = NULL,
                          id_list = NULL, n_threads = NULL) {
      if (!is.null(input_fbase)) {
        private$.input_fbase <- input_fbase
      } else {
        stop("Pedifromsnps: input_fbase is required")
      }
      if (!is.null(output_fbase)) {
        private$.output_fbase <- output_fbase
      } else {
        stop("Pedifromsnps: output_fbase is required")
      }
      if (!is.null(freq_fbase)) {
        private$.freq_fbase <- freq_fbase
      } else {
        stop("Pedifromsnps: freq_fbase is required")
      }
      if (!is.null(corr)) {
        private$.corr <- corr
      }
      if (!is.null(per_chromo)) {
        private$.per_chromo <- per_chromo
      }
      if (!is.null(king)) {
        private$.king <- king
      }
      if (!is.null(method_two)) {
        private$.method_two <- method_two
      }
      if (!is.null(batch_size)) {
        private$.batch_size <- batch_size
      }
      if (!is.null(id_list)) {
        private$.id_list <- id_list
      }
      if (!is.null(n_threads)) {
        private$.n_threads <- n_threads
      }
    },
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    finalize = function() {
      #message("finalize(Pedifromsnps)")
    },
    get_input_fbase = function() {
      private$.input_fbase
    },
    get_output_fbase = function() {
      private$.output_fbase
    },
    get_freq_fbase = function() {
      private$.freq_fbase
    },
    get_corr = function() {
      private$.corr
    },
    get_per_chromo = function() {
      private$.per_chromo
    },
    get_king = function() {
      private$.king
    },
    get_method_two = function() {
      private$.method_two
    },
    get_batch_size = function() {
      private$.batch_size
    },
    get_id_list = function() {
      private$.id_list
    },
    get_n_threads = function() {
      private$.n_threads
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

