fphi [optional -fast -debug -list <file containing trait names>
               -precision <h2 decimal count>
               -mask <name of nifti template volume>
               -evd_data <base filename of EVD data>]

   -fast  : Performs a quick estimation run 
   -debug : Displays values at each iteration 
   -list  : performs fast fphi on a list of trait (does not include covariate data)

   -precision number of decimals to calculate h2r
   -mask  : outputs fphi -fast results of the list of voxels from -list option  
   -evd_data : When using the -list option the EVD data option can be used to avoid having to calculate EVD data within the command      


----

Uses max num of cores normally.
