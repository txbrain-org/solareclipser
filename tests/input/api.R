#library(R6)
#library(stringr)
#
##' R6 Class Main
##'
##' controller <- Controller$new()
##' controller$cmd$load(arg1 = "arg1", arg2 = "arg2")
##'
##' @export
#Controller <- R6Class("Controller",
#  private = list(
#    .cmd = list(
#      load = NULL
#    )
#  ),
#  public = list(
#    initialize = function() {
#      private$.cmd$load <- Model$new()
#    },
#    cmd = NULL,
#    init_cmd = list(
#      self$cmd <- list(
#        load = function(arg1 = NULL, arg2 = NULL) {
#          private$.cmd$load$load(arg1 = arg1, arg2 = arg2)
#        }
#    )
#  )
#)
#
##' R6 Class Model
##' @export
#Model <- R6Class("Model",
#  private = list(
#    .load = NULL
#  ),
#
#  public = list(
#    initialize = function(load = NULL) {
#      if (!is.null(load)) {
#        private$.load <- load
#      }
#    },
#    print = function() {
#      print(private$.load)
#    },
#
#    load = function(arg1 = NULL, arg2 = NULL) {
#      if (is.null(arg1) || is.null(arg2)) {
#        stop("arg1 and arg2 must be provided")
#      }
#      private$.load <- list(arg1 = arg1, arg2 = arg2)
#    }
#  )
#)
#
#
library(R6)

#' R6 Class Main
#'
#' controller <- Controller$new()
#' controller$cmd$load(arg1 = "arg1", arg2 = "arg2")
#'
#' @export
Controller <- R6Class("Controller",
  private = list(
    model = NULL
  ),
  public = list(
    cmd = NULL,

    initialize = function() {
      private$model <- Model$new()
      self$cmd <- list(
        load = function(arg1 = NULL, arg2 = NULL) {
          private$model$load(arg1 = arg1, arg2 = arg2)
        }
      )
    }
  )
)

#' R6 Class Model
#' @export
Model <- R6Class("Model",
  private = list(
    .load = NULL
  ),
  public = list(
    initialize = function(load = NULL) {
      if (!is.null(load)) {
        private$.load <- load
      }
    },
    print = function() {
      print(private$.load)
    },
    load = function(arg1 = NULL, arg2 = NULL) {
      if (is.null(arg1) || is.null(arg2)) {
        stop("arg1 and arg2 must be provided")
      }
      private$.load <- list(arg1 = arg1, arg2 = arg2)
    }
  )
)
