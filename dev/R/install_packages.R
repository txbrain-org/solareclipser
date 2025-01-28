required_pkgs <- c(
  "tidyverse",
  "sqldf",
  "irr"
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
