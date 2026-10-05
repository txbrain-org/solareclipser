source("renv/activate.R")

# Pinned pandoc from `make pandoc`; rmarkdown looks here first.
local({
  pandoc_dir <- file.path(getwd(), ".tools", "pandoc-3.12", "bin")
  if (dir.exists(pandoc_dir)) Sys.setenv(RSTUDIO_PANDOC = pandoc_dir)
})
