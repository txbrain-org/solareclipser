# load library
library(solareclipser)

# load data set
# data(dat30)

# univariate polygenic model
mod1 <- solarPolygenic(trait1 ~ 1, dat30)

# bivariate polygenic model
mod2 <- solarPolygenic(trait1 + trait2 ~ 1, dat30,
    polygenic.options = '-testrhoe -testrhog')

# specify directory with IBD matrices and run linkage model
# mibddir <- system.file('extdata', 'solarOutput',
  'solarMibdsCsv', package = 'solareclipser') 
link <- solarMultipoint(trait1 ~ 1, dat30,
  mibddir = mibddir, chr = 5)

# run association model in parallel
assoc <- solarAssoc(trait1 ~ 1, dat30, cores = 2,
  snpcovdata = genocovdat30, snpmap = mapdat30)

plot(assoc,"qq")
