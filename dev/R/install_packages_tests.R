required_pkgs <- c(
  "devtools",
  "testthat",
  "usethis",
  "roxygen2",
  "knitr"
)

for (p in seq_along(required_pkgs))
{
  if (!require(required_pkgs[p], character.only = TRUE))
  {
    install.packages(required_pkgs[p])
    library(required_pkgs[p], character.only = TRUE)
  }
}

rm(p, required_pkgs)
