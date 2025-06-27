library(R6)
library(stringr)

#' @title R6 Class: SolarFiles
#'
#' @description
#' A file management class for organizing and accessing file paths generated or required by SOLAR analyses.
#'
#' @details
#' This class organizes common files used in SOLAR workflows into three categories: shared files, polygenic-related files, and FPHI-related files. 
#' It provides accessors and mutators to retrieve and update paths without performing file I/O.
#'
#' @section Usage Example:
#' ```r
#' files <- SolarFiles$new(settings = list(output = list(dir = "solar_output")))
#' files$set_polygenic_trait_d("height")
#' files$set_fphi_evd_data_bn("evd_matrix")
#' shared <- files$get_shared_files()
#' ```
#'
#' @section File Categories:
#' - **Shared files** (used across multiple steps):
#'   - `tclIndex`: TCL history
#'   - `pedigree.info`: Pedigree metadata
#'   - `pedindex.cde`: Pedigree index (coded)
#'   - `pedindex.out`: Pedigree index output
#'   - `phenotypes.info`: Phenotype metadata
#'   - `phi2.gz`: Kinship matrix
#'
#' - **Polygenic files**:
#'   - `trait_d`: Trait or list of traits
#'   - `trait_d_files`: Trait-specific output files (e.g., model results)
#'
#' - **FPHI files** (EVD decomposition):
#'   - `evd_data_bn`: Basename for EVD files
#'   - `eigenvalues_f`: Eigenvalues
#'   - `eigenvectors_f`: Eigenvectors
#'   - `ids_f`: IDs associated with EVD
#'   - `notes_f`: Notes or logs
#'
#' @section Accessors:
#' - `get_settings()`, `get_shared_files()`
#' - `get_polygenic_files()`, `get_fphi_files()`
#'
#' @section Mutators:
#' - `set_settings(settings)`
#' - `set_polygenic_trait_d(trait_d)`, `set_polygenic_trait_d_files(trait_d_files)`
#' - `set_fphi_evd_data_bn(evd_data_bn)`, `set_fphi_eigenvalues_f(eigenvalues_f)`
#' - `set_fphi_eigenvectors_f(eigenvectors_f)`, `set_fphi_ids_f(ids_f)`, `set_fphi_notes_f(notes_f)`
#'
#' @param settings A list object containing configuration, such as `output$dir`, passed at construction time.
#' @param shared A list object containing configuration, such as `output$dir`, passed at construction time.
#' @param polygenic A list object containing configuration, such as `output$dir`, passed at construction time.
#' @param fphi A list object containing configuration, such as `output$dir`, passed at construction time.
#'
#' @return An R6 object of class `SolarFiles`
#' @md
#' @export
SolarFiles <- R6Class("SolarFiles",
  private = list(
    .settings = NULL,
    .shared = list(
      tclIndex_f = "tclIndex",
      pedigree_info_f = "pedigree.info",
      pedindex_cde_f = "pedindex.cde",
      pedindex_out_f = "pedindex.out",
      phenotypes_info_f = "phenotypes.info",
      phi2_f = "phi2.gz"
    ),
    .polygenic = list(
      trait_d = NULL, # ex. "CC, WM, etc."
      trait_d_files = NULL
    ),
    .fphi = list(
      evd_data_bn = NULL, # from fphi(evd_data = ...)
      eigenvalues_f = NULL,
      eigenvectors_f = NULL,
      ids_f = NULL,
      notes_f = NULL
    )
  ),
  public = list(
    #' @description
    #' Initialize a new `SolarFiles` object with a settings list.
    #'
    #' @param settings A list containing configuration (must include `output$dir`).
    #' @return Invisibly returns the `SolarFiles` object.
    initialize = function(settings = NULL) {
      # NOTE: Solar checks if settings$output$dir exists
      if (!is.null(settings)) {
        private$.settings <- settings
      } else {
        stop("SolarFiles: settings object null")
      }
      invisible(self)
    },
    #' @description
    #' Print a summary of the object.
    #'
    #' @return Invisibly returns the object.
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },
    
    #' @description
    #' Set a new settings object.
    #'
    #' @param settings A list of updated settings.
    #' @return Invisibly returns the object.
    set_settings = function(settings) {
      private$.settings <- settings
      invisible(self)
    },
    #' @description
    #' Placeholder for setting internal polygenic metadata (currently no effect).
    #'
    #' @return Invisibly returns the object.
    set_polygenic = function() {
      invisible(self)
    },
    #' @description
    #' Set the trait descriptor(s) used in polygenic modeling.
    #'
    #' @param trait_d A character string or vector of traits (e.g., `"height"`, `c("height", "weight")`).
    #' @return Invisibly returns the object.
    set_polygenic_trait_d = function(trait_d) {
      private$.polygenic$trait_d <- trait_d
      invisible(self)
    },
    #' @description
    #' Set the list of output files associated with polygenic traits.
    #'
    #' @param trait_d_files A named list or vector of file names.
    #' @return Invisibly returns the object.
    set_polygenic_trait_d_files = function(trait_d_files) {
      private$.polygenic$trait_d_files <- trait_d_files
      invisible(self)
    },
    #' @description
    #' Set the base name for EVD data files used in FPHI.
    #'
    #' @param evd_data_bn A base name string (e.g., `"evd_matrix"`).
    #' @return Invisibly returns the object.
    set_fphi_evd_data_bn = function(evd_data_bn) {
      private$.fphi$evd_data_bn <- evd_data_bn
      invisible(self)
    },
    #' @description
    #' Set the eigenvalues file for EVD decomposition.
    #'
    #' @param eigenvalues_f A file path to the eigenvalues file.
    #' @return Invisibly returns the object.
    set_fphi_eigenvalues_f = function(eigenvalues_f) {
      private$.fphi$eigenvalues_f <- eigenvalues_f
      invisible(self)
    },
    #' @description
    #' Set the eigenvectors file for EVD decomposition.
    #'
    #' @param eigenvectors_f A file path to the eigenvectors file.
    #' @return Invisibly returns the object.
    set_fphi_eigenvectors_f = function(eigenvectors_f) {
      private$.fphi$eigenvectors_f <- eigenvectors_f
      invisible(self)
    },
    #' @description
    #' Set the file of IDs associated with EVD decomposition.
    #'
    #' @param ids_f A file path to the IDs file.
    #' @return Invisibly returns the object.
    set_fphi_ids_f = function(ids_f) {
      private$.fphi$ids_f <- ids_f
      invisible(self)
    },
    #' @description
    #' Set the notes file associated with EVD/FPHI analysis.
    #'
    #' @param notes_f A file path to a notes/log file.
    #' @return Invisibly returns the object.
    set_fphi_notes_f = function(notes_f) {
      private$.fphi$notes_f <- notes_f
      invisible(self)
    },

    #' @description
    #' Get the internal settings object.
    #'
    #' @return The current settings list.
    get_settings = function() {
      private$.settings
    },
    #' @description
    #' Get the list of shared SOLAR file names.
    #'
    #' @return A named list of file names used across commands (e.g., `"phi2.gz"`).
    get_shared_files = function() {
      private$.shared
    },
    #' @description
    #' Get metadata and file paths related to polygenic analysis.
    #'
    #' @return A list with `trait_d` and `trait_d_files` entries.
    get_polygenic_files = function() {
      private$.polygenic
    },
    #' @description
    #' Get metadata and file paths related to FPHI (EVD) analysis.
    #'
    #' @return A list containing EVD file components (`eigenvalues`, `eigenvectors`, etc.).
    get_fphi_files = function() {
      private$.fphi
    }
  )
)


#' @title R6 Class: SolarFilesController
#'
#' @description
#' A controller class for managing and accessing trait-specific output files in a `SolarFiles` object.
#'
#' @details
#' This class wraps around a `SolarFiles` instance and provides helper methods to set and retrieve
#' polygenic analysis output files (e.g., `.mod`, `.out`, `.stats`) based on current trait names.
#' It is particularly useful for post-processing or organizing model outputs after a SOLAR polygenic run.
#'
#' @section Usage Example:
#' ```r
#' files <- SolarFiles$new(settings = list(output = list(dir = "solar_output")))
#' files$set_polygenic_trait_d("height")
#' ctrl <- SolarFilesController$new(sf = files)
#' ctrl$set_polygenic_trait_d_files()
#' mod_files <- ctrl$get_mod_files()
#' ```
#'
#' @section Methods:
#' - `set_polygenic_trait_d_files()`: Scan directory and assign `trait_d_files` in `SolarFiles`.
#' - `get_polygenic_trait_d_files()`: Return all polygenic output files for current trait.
#' - `get_mod_files()`: Return only `.mod` model files.
#' - `get_out_files()`: Return only `.out` output files.
#' - `get_stats_files()`: Return only `.stats` statistics files.
#'
#' @return An R6 object of class `SolarFilesController`
#' @md
#' @export
SolarFilesController <- R6Class("SolarFilesController",
  inherit = SolarFiles,
  private = list(
    .sf = NULL
  ),
  public = list(
    #' @description
    #' Initialize a new `SolarFilesController` object using an existing `SolarFiles` instance.
    #'
    #' @param sf An object of class `SolarFiles`.
    #' @return Invisibly returns the `SolarFilesController` object.
    initialize = function(sf = NULL) {
      if (!is.null(sf)) {
        private$.sf <- sf
      } else {
        stop("SolarFilesController: SolarFiles object null")
      }
      invisible(self)
    },
    #' @description
    #' Print a summary of the object.
    #'
    #' @return Invisibly returns the object.
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },

    #' @description
    #' Populate and set the `trait_d_files` field in the linked `SolarFiles` object
    #' based on the trait name and file path structure.
    #'
    #' This function builds the trait directory path using the current settings and trait name,
    #' lists all files under that directory, and assigns them to `trait_d_files`.
    #'
    #' @return Invisibly returns the controller object.
    set_polygenic_trait_d_files = function() {
      path_to_files <- private$.sf$get_settings()$output$dir
      polygenic_files <- private$.sf$get_polygenic_files()
      ## if trait_d is "T1 T2 T3 ..." replace " " with "."
      polygenic_files$trait_d <-
        str_replace_all(polygenic_files$trait_d, " ", ".")
      trait_d_files <- str_c(path_to_files, "/", polygenic_files$trait_d)
      trait_d_files <- list.files(trait_d_files, full.names = TRUE)
      private$.sf$set_polygenic_trait_d_files(trait_d_files)
      invisible(self)
    },

    #' @description
    #' Retrieve the list of polygenic trait output files from the linked `SolarFiles` object.
    #'
    #' @return A character vector of file paths.
    get_polygenic_trait_d_files = function() {
      private$.sf$get_polygenic_files()$trait_d_files
    },
    #' @description
    #' Extract only the `.mod` files from the polygenic trait output directory.
    #'
    #' @return A character vector of `.mod` file paths.
    get_mod_files = function() {
      str <- private$.sf$get_polygenic_files()$trait_d_files
      mod_files <- str[str_detect(str, ".mod$")]
      mod_files
    },
    #' @description
    #' Extract only the `.out` files from the polygenic trait output directory.
    #'
    #' @return A character vector of `.out` file paths.
    get_out_files = function() {
      str <- private$.sf$get_polygenic_files()$trait_d_files
      out_files <- str[str_detect(str, ".out$")]
      out_files
    },
    #' @description
    #' Extract only the `.stats` files from the polygenic trait output directory.
    #'
    #' @return A character vector of `.stats` file paths.
    get_stats_files = function() {
      str <- private$.sf$get_polygenic_files()$trait_d_files
      stats_files <- str[str_detect(str, ".stats$")]
      stats_files
    }

  )
)

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
