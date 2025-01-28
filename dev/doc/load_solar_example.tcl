#solar example script

#Loads pedigree if it's an empirical pedigree you need to set the threshold with -t
load pedigree <pedigree filename>

#Loads phenotype file
load phenotype <phenotype filename>

#Select trait
trait <trait name>

#Select covariates
covar <list of covariates>

#Run polygenic or fphi 
polygenic
#or
fphi
