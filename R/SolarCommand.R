library(R6)
library(stringr)

#' @title R6 Class: SolarCommand
#'
#' @description
#' A command builder class for interfacing with SOLAR subcommands.
#'
#' @details
#' This class orchestrates SOLAR subcommands such as `load`, `trait`, `polygenic`, `fphi`, `pedifromsnps`, etc.
#' Each call stores command configuration objects for later execution.
#'
#' @section Usage Example:
#' ```r
#' cmd <- SolarCommand$new()
#' cmd$load("pedigree", fpath = "ped.csv")
#' cmd$trait("height")
#' cmd$polygenic()
#' ```
#'
#' @section Subcommand Builders:
#' - `load(obj, opts, fpath, cond)`: Register a load command.
#' - `trait(args)`: Set trait(s).
#' - `covariate(args)`: Add covariate(s).
#' - `polygenic(opts)`: Configure polygenic model.
#' - `create_evd_data(...)`: Register an EVD creation call.
#' - `fphi(...)`: Configure fphi heritability analysis.
#' - `pedifromsnps(...)`: Configure SNP-to-pedigree conversion.
#'
#' @section Accessors:
#' - `get_load()`, `get_loads()`, `get_trait()`, `get_covariate()`, `get_polygenic()`
#' - `get_create_evd_data()`, `get_fphi()`, `get_pedifromsnps()`
#'
#' @return An R6 object of class `SolarCommand`
#' @md
#' @export
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
    #' @return A new `SolarCommand` object with initialized subcommand slots (`load`, `trait`, `covariate`, `polygenic`).
    #' @md
    initialize = function() {
      private$.load <- Load$new()
      private$.trait <- Trait$new()
      private$.covariate <- Covariate$new()
      private$.polygenic <- Polygenic$new()
      #private$.create_evd_data <- CreateEvdData$new()
      #private$.fphi <- FPHI$new()
      #private$.pedifromsnps <- PedifromSNPs$new()
    },

    #' @param obj Character. Object type to load (e.g., `"pedigree"`, `"phenotypes"`).
    #' @param opts Character. Optional flags (e.g., `-sample`, `-allow`, etc.).
    #' @param fpath Character. Path to the input file.
    #' @param cond Character. Additional condition string (e.g., `-t 0`).
    #' @return An object of class `Load`
    #' @md
    load = function(obj = NULL, opts = NULL, fpath = NULL, cond = NULL) {
      private$.load <- Load$new(obj, opts, fpath, cond)
      private$.loads <- c(private$.loads, private$.load)
      invisible(self)
    },

    #' @param args Character. Trait name(s) or expressions to analyze.
    #' @return An object of class `Trait`
    #' @md
    trait = function(args = NULL) {
      private$.trait <- Trait$new(args)
      invisible(self)
    },
    
    #' @param opts Character. Optional SOLAR polygenic flags (e.g., `-screen`, `-sporadic`, etc.).
    #' @return An object of class `Polygenic`
    #' @md
    polygenic = function(opts = NULL) {
      private$.polygenic <- Polygenic$new(opts)
      invisible(self)
    },

    #' @param args Character. Covariate expression(s), including interactions or trait-specific covariates.
    #' @return An object of class `Covariate`
    #' @md
    covariate = function(args = NULL) {
      private$.covariate <- Covariate$new(args)
      invisible(self)
    },

    #' @param output_fbasename Character. Base name for EVD output files (required).
    #' @param plink_fbasename Character. Base name for PLINK input (optional).
    #' @param use_covs Logical. Whether to include covariates in the EVD sample.
    #' @return An object of class `CreateEvdData`
    #' @md
    create_evd_data = function(output_fbasename = NULL, plink_fbasename = NULL,
                               use_covs = FALSE) {
      private$.create_evd_data <-
        CreateEvdData$new(output_fbasename, plink_fbasename, use_covs)
      invisible(self)
    },

    #' @param opts Character. Additional fphi options (`-fast`, `-debug`, etc.).
    #' @param opts_fname Character. File containing list of traits.
    #' @param precision Numeric. Decimal precision for `h2` estimates.
    #' @param mask Character. Path to NIfTI mask file.
    #' @param evd_data Character. Base filename of EVD data to reuse.
    #' @return An object of class `FPHI`
    #' @md
    fphi = function(opts = NULL, opts_fname = NULL,
                    precision = NULL, mask = NULL,
                    evd_data = NULL) {
      private$.fphi <- FPHI$new(opts, opts_fname, precision, mask, evd_data)
      invisible(self)
    },

    #' @param input_fbase Character. Base filename for PLINK input data (required).
    #' @param output_fbase Character. Output base filename (required).
    #' @param freq_fbase Character. Frequency file from PLINK (required).
    #' @param corr Numeric. Alpha for correlation matrix computation (optional).
    #' @param per_chromo Logical. Output per chromosome (optional).
    #' @param king Logical. Use KING method (optional).
    #' @param method_two Logical. Use method 2 for GRM (optional).
    #' @param batch_size Integer. Loci per thread per batch (optional).
    #' @param id_list Character. Path to file listing subject IDs (optional).
    #' @param n_threads Integer. Number of threads to use (optional).
    #' @return An object of class `PedifromSNPs`
    #' @md
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

    #' @return The last `Load` object configured via `$load()`.
    #' @md
    get_load = function() { private$.load },

    #' @return A list of all `Load` objects configured via `$load()`.
    #' @md
    get_loads = function() { private$.loads },

    #' @return The current `Trait` object.
    #' @md
    get_trait = function() { private$.trait },

    #' @return The current `Covariate` object.
    #' @md
    get_covariate = function() { private$.covariate },

    #' @return The current `Polygenic` object.
    #' @md
    get_polygenic = function() { private$.polygenic },

    #' @return The current `CreateEvdData` object.
    #' @md
    get_create_evd_data = function() { private$.create_evd_data },

    #' @return The current `FPHI` object.
    #' @md
    get_fphi = function() { private$.fphi },

    #' @return The current `PedifromSNPs` object.
    #' @md
    get_pedifromsnps = function() { private$.pedifromsnps },

    #' @return Invisibly returns self.
    #' @md
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    }
  )
)


#' @title R6 Class: Load
#'
#' @description
#' Represents the SOLAR `load` subcommand for importing various data objects into the analysis environment.
#'
#' @details
#' This class is responsible for validating and storing configuration related to SOLAR's `load` command. The `load` command is used
#' to import data such as pedigrees, phenotypes, matrices, and other inputs required by SOLAR for genetic analysis.
#' Currently, only the `"pedigree"` and `"phenotypes"` object types are supported.
#'
#' ## SOLAR Manual Syntax:
#' ```
#' load <object-type> [<opts>] <args>
#' ```
#'
#' ## Examples:
#' - `load pedigree ped.csv`
#' - `load phenotypes phen.csv`
#' - `load matrix -sample matrix.dat A B`
#' - `load freq -nosave allele_freq.txt`
#' - `load marker -xlinked marker.dat`
#'
#' Unsupported object types will throw an error unless added to `.current_supported_objs`.
#'
#' @param obj Character. Required. Type of object to load. Must be one of: `"pedigree"`, `"phenotypes"`, `"matrix"`, `"model"`, `"freq"`, `"marker"`, `"map"`.
#' @param opts Character. Optional. Valid flags or modifiers, e.g., `-sample`, `-allow`, `-cols`, `-nosave`, etc.
#' @param fpath Character. Required if `obj` is specified. File path for the object to be loaded.
#' @param cond Character. Optional. Additional trailing command content (e.g., secondary arguments or conditions).
#'
#' @return An R6 object of class `Load`, storing configuration for one `load` subcommand.
#' @md
#'
#' @seealso [SolarCommand] for orchestrating multiple SOLAR subcommands.
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
    #' @param obj Character. Optional. Type of object to load (e.g., `"pedigree"`, `"phenotypes"`). Must be one of the valid SOLAR object types.
    #' @param opts Character. Optional. Additional SOLAR `load` command options (e.g., `"-sample"`, `"-allow"`). Must begin with `-` and be valid.
    #' @param fpath Character. Optional. Path to the file associated with the load command. Must exist if provided.
    #' @param cond Character. Optional. Any additional trailing arguments for the command (e.g., `"name1"`, `"name2"`).
    #'
    #' @return A new `Load` object containing validated parameters for a SOLAR `load` command.
    #' @md
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

    #' @return A character string representing the type of object to load (e.g., `"pedigree"` or `"phenotypes"`).
    #' @md
    get_obj = function() {
      private$.obj
    },

    #' @return A character string representing any optional SOLAR load flags (e.g., `"-sample"`, `"-allow"`).
    #' @md
    get_opts = function() {
      private$.opts
    },

    #' @return A character string containing the path to the file being loaded.
    #' @md
    get_fpath = function() {
      private$.fpath
    },

    #' @return A character string representing any additional condition or trailing argument specified with the `load` command.
    #' @md
    get_cond = function() {
      private$.cond
    },

    #' @return Invisibly returns `self`. Outputs a human-readable string representation of the `Load` object.
    #' @md
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    }
  )
)


#' @title R6 Class: Trait
#'
#' @description
#' Represents the SOLAR `trait` subcommand for specifying one or more traits for analysis.
#'
#' @details
#' The `trait` command defines the dependent variable(s) for analysis in SOLAR. It supports univariate or multivariate traits,
#' and can reference phenotype names or user-defined expressions (using `define`). The user must set this before running most SOLAR analyses.
#'
#' ## SOLAR Manual Syntax:
#' ```
#' trait                            ; show current trait info
#' trait <trait1>                   ; single trait
#' trait <trait1> <trait2> ...      ; multivariate (up to 20)
#' trait -noparm <trait1> ...      ; preserve prior parameters
#' define <name> = <expression>    ; define derived traits
#' trait <phenotype|defname>       ; select raw or defined traits
#' ```
#'
#' ## Examples:
#' - `trait bmi`
#' - `trait q1 q2`
#' - `define a = 10 * log(q4)` then `trait a q3`
#'
#' @md
Trait <- R6Class("Trait",
  private = list(
    .args = NULL
    # TODO: Add valid traits, this will have to come after the file loaded
    # .valid_args = c()
  ),
  public = list(
    #TODO: trim whitespace at end of args
    #' @param args Character. Optional. One or more trait names or expressions. Can include user-defined variables via `define`.
    #'
    #' @return A new `Trait` object containing the specified trait configuration.
    #' @md
    initialize = function(args = NULL) {
      if (!is.null(args)) {
        private$.args <- args
      }
    },
    #' @return Invisibly returns `self`. Prints the trait configuration to the console if defined.
    #' @md
    print = function() {
      if (!is.null(private$.args)) {
        cat(format(self), sep = "\n")
        invisible(self)
      }
    },
    #' @return A character string representing the specified trait(s), or `NULL` if not set.
    #' @md
    get_args = function() {
      private$.args
    }
  )
)


#' @title R6 Class: Covariate
#'
#' @description
#' Represents the SOLAR `covariate` subcommand for modeling fixed effects, interactions, and trait-specific covariates.
#'
#' @details
#' The `covariate` command adds covariates to the analysis model in SOLAR. This may include simple variables, polynomial terms,
#' interaction terms, and trait-specific covariates. Covariates can be suspended, restored, or removed dynamically.
#'
#' ## SOLAR Manual Syntax:
#' ```
#' covariate <variable>[^n | ^1,2,...]*<interaction or #variable>
#' covariate                       ; display current covariates
#' covariate delete <name>         ; remove a specific covariate
#' covariate delete_all            ; remove all covariates
#' covariate suspend <name>        ; temporarily disable covariate
#' covariate restore <name>        ; re-enable suspended covariate
#' ```
#'
#' ## Examples:
#' - `covariate age`
#' - `covariate age*sex`
#' - `covariate age^2`
#' - `covariate age^1,2,3#sex`
#' - `covariate sex age(q1) age*sex(q3)`
#'
#' @md
Covariate <- R6Class("Covariate",
  private = list(
    .args = NULL
    # TODO: Add valid covar, this will have to come after the file loaded
    # .valid_covars = c()
  ),
  public = list(
    #' @param args Character. One or more covariate specifications. Supports expressions, interactions, and trait-specific formats.
    #'
    #' @return A new `Covariate` object containing the covariate configuration for SOLAR.
    #' @md
    initialize = function(args = NULL) {
      if (!is.null(args)) {
        private$.args <- args
      }
    },
    #' @return Invisibly returns `self`. Outputs the covariate specification to the console.
    #' @md
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    #' @return A character string or expression representing the current covariate specification, or `NULL` if not defined.
    #' @md
    get_args = function() {
      private$.args
    }
  )
)


#' @title R6 Class: Polygenic
#'
#' @description
#' Represents the SOLAR `polygenic` subcommand, which fits a polygenic model for heritability estimation using the loaded traits and covariates.
#'
#' @details
#' The `polygenic` command performs variance component modeling using pedigree and trait data. It tests for heritability and optionally
#' includes covariate effects, fixed parameters, and variance component structures. Common options include model screening, sporadic traits,
#' and residual correlation testing.
#'
#' ## SOLAR Manual Syntax:
#' ```
#' polygenic [-screen] [-all] [-p | -prob p] [-fix covar]
#'           [-testcovar covar] [-testrhoe] [-testrhog] [-testrhoc]
#'           [-sporadic] [-keephouse] [-testrhop] [-rhopse] [-fphi]
#' ```
#'
#' ## Notes:
#' - `screencov` is an alias for `polygenic -screen`
#' - `sporadic` is an alias for `polygenic -sporadic`
#'
#' ## Example Workflow:
#' ```
#' load pedigree ped
#' load phenotypes phen
#' trait hbp
#' covariate age sex age*sex smoke
#' polygenic -screen
#' ```
#'
#' @md
Polygenic <- R6Class("Polygenic",
  private = list(
    .opts = NULL,
    .valid_opts = c("-screen", "-all", "-p", "-prob", "-fix",
                    "-testcovar", "-testrhoe", "-testrhog", "-testrhoc",
                    "-sporadic", "-keephouse", "-testrhop", "-rhopse",
                    "-fphi")
  ),
  public = list(
    #' @param opts Character. Optional. One of the valid SOLAR `polygenic` flags, such as `"-screen"`, `"-sporadic"`, `"-testcovar"`, etc.
    #'             Only a single option is supported at a time in this implementation.
    #'
    #' @return A new `Polygenic` object with the specified modeling option.
    #' @md
    initialize = function(opts = NULL) {
      if (!is.null(NULL) && grepl("-", opts)) {
        if (!opts %in% private$.valid_opts) {
          stop("SolarPolygenic: Invalid option - ", opts)
        }
        private$.opts <- opts
      }
    },
    #' @return Invisibly returns `self`. Prints a formatted summary of the polygenic configuration.
    #' @md
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    #' @return Invisibly returns `self`. Prints a formatted summary of the polygenic configuration.
    #' @md
    get_opts = function() {
      private$.opts
    }
  )
)


#' @title R6 Class: CreateEvdData
#'
#' @description
#' Represents the SOLAR `create_evd_data` subcommand, which performs eigenvalue decomposition (EVD) on the kinship matrix to accelerate genome-wide analyses.
#'
#' @details
#' The `create_evd_data` command is typically used prior to `gwas`, `gpu_gwas`, or `gpu_fphi`. It produces an eigenvalue decomposition
#' of the kinship matrix for a given set of individuals, which can substantially improve computational efficiency for large sample sizes.
#'
#' The command uses trait and covariate selection to define the sample set. If `--plink` is provided, the sample is determined using the `.fam` file from PLINK.
#' If `--use_covs` is set, individuals from covariate specification are included as well.
#'
#' ## SOLAR Manual Syntax:
#' ```
#' create_evd_data --o <output base filename>
#'                 --plink <plink set base filename>
#'                 --use_covs
#' ```
#'
#' ## Output Files:
#' - `<basename>.ids`: List of subject IDs
#' - `<basename>.eigenvalues`: Eigenvalue vector
#' - `<basename>.eigenvectors`: Matrix of eigenvectors
#' - `<basename>.notes`: Notes describing the run
#'
#' @md
CreateEvdData <- R6Class("CreateEvdData",
  private = list(
    .output_fbasename = NULL,
    .plink_fbasename = NULL,
    .use_covs = FALSE
  ),
  public = list(
    #' @param output_fbasename Character. Required. Base name used to generate EVD output files.
    #' @param plink_fbasename Character. Optional. Base name for input PLINK data set (.bed/.bim/.fam).
    #' @param use_covs Logical. Optional. If `TRUE`, includes IDs defined by the covariate command in the EVD sample.
    #'
    #' @return A new `CreateEvdData` object encapsulating configuration for SOLAR's `create_evd_data` command.
    #' @md
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
    #' @return Invisibly returns `self`. Prints a summary of the `CreateEvdData` object configuration.
    #' @md
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    #' @return A character string containing the base name for EVD output files.
    #' @md
    get_output_fbasename = function() {
      private$.output_fbasename
    },
    #' @return A character string representing the base name of the PLINK input set, or `NULL` if not set.
    #' @md
    get_plink_fbasename = function() {
      private$.plink_fbasename
    },
    #' @return A logical value indicating whether covariates were included in the EVD sample selection.
    #' @md
    get_use_covs = function() {
      private$.use_covs
    }
  )
)


#' @title R6 Class: FPHI
#'
#' @description
#' Represents the SOLAR `fphi` subcommand for fast heritability approximation using eigenvalue decomposition of the kinship matrix.
#'
#' @details
#' `fphi` is a performance-optimized method in SOLAR for estimating heritability (`h2`) using analytic or permutation-based inference.
#' It leverages EVD data to speed up computation. The `-fast` option uses the Wald approximation; the default behavior conducts
#' a full grid search for maximum-likelihood `h2` values up to 9 decimal places.
#'
#' Optional inputs include:
#' - `-list`: Path to a file containing trait names.
#' - `-mask`: NIfTI template for voxel-based analysis.
#' - `-precision`: Number of decimals for `h2` inference.
#' - `-evd_data`: Precomputed EVD base filename to reuse.
#'
#' This is especially useful for high-dimensional neuroimaging traits and large family-based datasets.
#'
#' ## SOLAR Manual Syntax:
#' ```
#' fphi [options]
#' ```
#'
#' ## Example Options:
#' - `-fast`
#' - `-debug`
#' - `-list traitlist.txt`
#' - `-precision 4`
#' - `-mask brain_mask.nii.gz`
#' - `-evd_data evd/pedigree`
#'
#' @md
FPHI <- R6Class("FPHI",
  private = list(
    .opts = NULL, # -fast -debug -list
    .opts_fname = NULL, # -list <file containing trait names>

    .precision = NULL, # -precision <h2 decimal count>
    .mask = NULL, # -mask <name of nifti template volume>
    .evd_data = NULL # -evd_data <base filename of EVD data
  ),
  public = list(
    #' @param opts Character. Optional. SOLAR `fphi` flags such as `"-fast"` or `"-debug"`.
    #' @param opts_fname Character. Optional. Path to a file listing trait names (used with `-list`).
    #' @param precision Numeric. Optional. Number of decimal places to estimate `h2` (e.g., `4` for 0.0001).
    #' @param mask Character. Optional. Path to a NIfTI mask file used to constrain voxel-based analysis.
    #' @param evd_data Character. Optional. Base filename of EVD data to reuse, avoiding recomputation.
    #'
    #' @return A new `FPHI` object containing configuration for a SOLAR `fphi` command.
    #' @md
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
    #' @return Invisibly returns `self`. Prints all internal FPHI configuration values to the console.
    #' @md
    print = function() {
      cat(".opts = ", private$.opts, "\n")
      cat(".opts_fname = ", private$.opts_fname, "\n")
      cat(".precision = ", private$.precision, "\n")
      cat(".mask = ", private$.mask, "\n")
      cat(".evd_data = ", private$.evd_data, "\n")
      invisible(self)
    },
    #' @return Invisibly returns `self`. Alias for `print()`, used for explicit self-inspection.
    #' @md
    print_self = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    #' @return A character string of flags passed to the `fphi` command (e.g., `"-fast"`).
    #' @md
    get_opts = function() {
      private$.opts
    },
    #' @return A character string representing the filename passed via `-list`, or `NULL` if not used.
    #' @md
    get_opts_fname = function() {
      private$.opts_fname
    },
    #' @return A numeric value indicating the decimal precision requested for `h2` estimation.
    #' @md
    get_precision = function() {
      private$.precision
    },
    #' @return A character string specifying the path to the NIfTI mask file, or `NULL` if not provided.
    #' @md
    get_mask = function() {
      private$.mask
    },
    #' @return A character string representing the base name of EVD data to reuse.
    #' @md
    get_evd_data = function() {
      private$.evd_data
    }
  )
)


#' @title R6 Class: PedifromSNPs
#'
#' @description
#' Represents the SOLAR `pedifromsnps` subcommand, which constructs a pedigree relationship matrix from SNP data in PLINK format.
#'
#' @details
#' The `pedifromsnps` command creates an empirical genetic relatedness matrix (GRM) using SNP data provided in PLINK binary format.
#' It supports multiple computation methods including correlation-based GRMs, KING-robust estimators, and per-chromosome GRMs.
#'
#' Required inputs include:
#' - `-i`: PLINK input base filename (without extension)
#' - `-o`: Output base filename
#' - `--freq`: Frequency file from PLINK
#'
#' Optional settings allow users to control correlation alpha, enable KING or method 2 GRMs, apply subject ID filters, adjust batch size, or multithread the computation.
#'
#' ## SOLAR Manual Syntax:
#' ```
#' pedifromsnps -i <plink input basename>
#'              -o <output basename>
#'              --freq <plink frequency file>
#'              [options]
#' ```
#'
#' ## Optional Flags:
#' - `-corr <alpha>`: Alpha value for correlation GRM
#' - `-per-chromo`: Output GRMs per chromosome
#' - `-king`: Use KING robust relatedness
#' - `-method_two`: Use second GRM computation method
#' - `-normalize`: Normalize correlation GRMs
#' - `-batch_size <n>`: Batch size for multithreaded computation
#' - `-id_list <file>`: Restrict GRM to listed subject IDs
#' - `-n_threads <n>`: Number of CPU threads to use
#'
#' @md
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
    #' @param input_fbase Character. Required. Base filename of the PLINK input set (.bed, .bim, .fam).
    #' @param output_fbase Character. Required. Base filename for output GRM and metadata files.
    #' @param freq_fbase Character. Required. Path to frequency file generated by PLINK (e.g., `plink.frq`).
    #' @param corr Numeric. Optional. Alpha value for correlation-based GRM estimation.
    #' @param per_chromo Logical. Optional. Whether to compute separate GRMs per chromosome. Default is `FALSE`.
    #' @param king Logical. Optional. Whether to use the KING robust method for GRM computation. Default is `FALSE`.
    #' @param method_two Logical. Optional. Use second correlation GRM computation method. Default is `FALSE`.
    #' @param batch_size Integer. Optional. Number of loci processed per thread per batch. Default is `500`.
    #' @param id_list Character. Optional. Path to file listing subject IDs to include in GRM.
    #' @param n_threads Integer. Optional. Number of CPU threads to use. Default is system-determined.
    #'
    #' @return A new `PedifromSNPs` object containing configuration for the SOLAR `pedifromsnps` command.
    #' @md
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
    #' @return Invisibly returns `self`. Prints a summary of the GRM configuration.
    #' @md
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    #' @return A character string containing the base filename for PLINK input files.
    #' @md
    get_input_fbase = function() {
      private$.input_fbase
    },
    #' @return A character string representing the GRM output base filename.
    #' @md
    get_output_fbase = function() {
      private$.output_fbase
    },
    #' @return A character string containing the path to the PLINK frequency file.
    #' @md
    get_freq_fbase = function() {
      private$.freq_fbase
    },
    #' @return A numeric value indicating the correlation GRM alpha parameter.
    #' @md
    get_corr = function() {
      private$.corr
    },
    #' @return Logical. `TRUE` if per-chromosome GRM output is enabled; otherwise `FALSE`.
    #' @md
    get_per_chromo = function() {
      private$.per_chromo
    },
    #' @return Logical. `TRUE` if KING GRM computation is enabled; otherwise `FALSE`.
    #' @md
    get_king = function() {
      private$.king
    },
    #' @return Logical. `TRUE` if GRM method two is selected; otherwise `FALSE`.
    #' @md
    get_method_two = function() {
      private$.method_two
    },
    #' @return Logical. `TRUE` if GRM method two is selected; otherwise `FALSE`.
    #' @md
    get_batch_size = function() {
      private$.batch_size
    },
    #' @return A character string representing the path to a subject ID list file.
    #' @md
    get_id_list = function() {
      private$.id_list
    },
    #' @return Integer. The number of threads to use for parallel GRM computation.
    #' @md
    get_n_threads = function() {
      private$.n_threads
    }
  )
)

#' @description Print class, length, and structure of a string for debugging.
#' @param str Character. The string to inspect.
#' @return NULL (invisible). Prints diagnostics via `message()`.
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
