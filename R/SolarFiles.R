#' R6 Class SolarFiles
#'
#' @description
#' TODO: add description
#'
#' @details
#' TODO: add list of files created by solar
#'
SolarFiles <- R6Class("SolarFiles",
  private = list(
    .solar_executable = "solar",
    .solar_output_dir = NA,

    .has_solar_executable = FALSE

    #.validate_executable = function() {
    #  private$.has_solar_executable <-
    #    system2("which", c(private$.solar_executable),
    #            stdout = FALSE, stderr = FALSE)
    #  if (private$.has_solar_executable == 0) {
    #    private$.has_solar_executable <- TRUE
    #  }
    #}
  ),
  public = list(
    initialize = function(solar_executable = NA, solar_output_dir = NA) {
      if (!is.na(solar_executable)) {
        private$.solar_executable <- solar_executable
      }
      if (!is.na(solar_output_dir)) {
        private$.solar_output_dir <- solar_output_dir
      }

      #private$.validate_executable()
      #if (!private$.has_solar_executable) {
      #  message("Solar executable not found")
      #}

      invisible(self)
    },

    get_solar_executable = function() {
      private$.solar_executable
    },

    print = function() {
      cat(format(self), sep = "\n")
      invisible(self)
    }
  )
)
