library(R6)
library(stringr)

#' R6 Class SolarFiles
#'
#' @description
#' TODO: add description
#'
#' @details
#' TODO: add list of files created by solar
#'
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
    initialize = function(settings = NULL) {
      # NOTE: Solar checks if settings$output$dir exists
      if (!is.null(settings)) {
        private$.settings <- settings
      } else {
        stop("SolarFiles: settings object null")
      }
      invisible(self)
    },
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },

    get_settings = function() {
      private$.settings
    },
    get_shared_files = function() {
      private$.shared
    },
    get_polygenic_files = function() {
      private$.polygenic
    },
    get_fphi_files = function() {
      private$.fphi
    },

    set_settings = function(settings) {
      private$.settings <- settings
      invisible(self)
    },
    set_polygenic = function() {
      invisible(self)
    },
    set_polygenic_trait_d = function(trait_d) {
      private$.polygenic$trait_d <- trait_d
      invisible(self)
    },
    set_polygenic_trait_d_files = function(trait_d_files) {
      private$.polygenic$trait_d_files <- trait_d_files
      invisible(self)
    },
    set_fphi_evd_data_bn = function(evd_data_bn) {
      private$.fphi$evd_data_bn <- evd_data_bn
      invisible(self)
    },
    set_fphi_eigenvalues_f = function(eigenvalues_f) {
      private$.fphi$eigenvalues_f <- eigenvalues_f
      invisible(self)
    },
    set_fphi_eigenvectors_f = function(eigenvectors_f) {
      private$.fphi$eigenvectors_f <- eigenvectors_f
      invisible(self)
    },
    set_fphi_ids_f = function(ids_f) {
      private$.fphi$ids_f <- ids_f
      invisible(self)
    },
    set_fphi_notes_f = function(notes_f) {
      private$.fphi$notes_f <- notes_f
      invisible(self)
    }
  )
)

#' R6 Class SolarFilesController
#'
#' @description
#' TODO: add description
#'
#' @details
#' TODO: controller for SolarFiles
#'
#' @export
SolarFilesController <- R6Class("SolarFilesController",
  inherit = SolarFiles,
  private = list(
    .sf = NULL
  ),
  public = list(
    initialize = function(sf = NULL) {
      if (!is.null(sf)) {
        private$.sf <- sf
      } else {
        stop("SolarFilesController: SolarFiles object null")
      }
      invisible(self)
    },
    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    },

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

    get_polygenic_trait_d_files = function() {
      private$.sf$get_polygenic_files()$trait_d_files
    },

    get_mod_files = function() {
      str <- private$.sf$get_polygenic_files()$trait_d_files
      mod_files <- str[str_detect(str, ".mod$")]
      mod_files
    },

    get_out_files = function() {
      str <- private$.sf$get_polygenic_files()$trait_d_files
      out_files <- str[str_detect(str, ".out$")]
      out_files
    },

    get_stats_files = function() {
      str <- private$.sf$get_polygenic_files()$trait_d_files
      stats_files <- str[str_detect(str, ".stats$")]
      stats_files
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
