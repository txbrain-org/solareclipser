source("renv/activate.R")

# Pinned pandoc from `make pandoc`, which links .tools/pandoc to the
# PANDOC_VER in the Makefile; rmarkdown looks here first.
local({
  pandoc_dir <- file.path(getwd(), ".tools", "pandoc", "bin")
  if (dir.exists(pandoc_dir)) Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)
})
