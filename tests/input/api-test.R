devtools::document()
devtools::load_all()
library(R6)
library(stringr)

controller <- Controller$new()
controller$cmd$load(arg1 = "arg1", arg2 = "arg2")
