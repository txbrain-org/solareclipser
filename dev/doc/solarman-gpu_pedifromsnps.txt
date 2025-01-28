# solar::gpu_pedifromsnps --
# Purpose: Calculates empirical pedigree matrix from a set of PLINK files using NVIDIA GPU hardware 
#
# Usage: gpu_pedifromsnps -i <filename> -o <filename> -freq <filename>
#        [optional: -corr <decimal> -gpus <list of GPU ids> -all -normalize
#                   -batch_size <integer number> -thread_size <integer number> -snp_stride <integer number>
#                   -per-chromo -id_list <filename> ]            
# Requirements:
#  	-Dynamically linked version of solar-eclipse
#       -CUDA capable NVIDIA graphics card with a minimum architecture of 3.5
#       -Linux version of solar-eclipse
#	-CUDA drivers must be from toolkit 9.0 or later (Not applicable if built locally from source code)
#       They can be downloaded https://developer.nvidia.com/cuda-10.2-download-archive
#
#   Command Arguments:
#   
#   -i <plink base filename> Base filename for plink .bed,.bim., and .fam.  Required
#
#   -o <filename> Output filename of the matrix calculated. Required
#
#   -freq <filename from plink_freq command> Filename of the output calculated 
#    by the plink_freq command. Required
#
#   -all  Selects all availible usable NVIDIA GPUs  
#
#   -snp_stride <integer in range [1,10]> Number of SNPs calculated perform GPU 
#    kernel block
#
#   -id_list <Name of file containing subject IDs> Output will only contain subjects with ids
#    included in the specified file
#
#   -per-chromo Creates a separate matrix for each chromosome found within the plink file
#
#   -batch_size <integer number in range [1,20000]> Number of SNPs calculated per iteration of a 
#    GPU stream.  It's possible a number within this range could be too large, which will lead
#    to an error or crash.  Calibrate it relative to the number of subjects. If not value is
#    specified then this command to estimate the largest number given memory constraints
#
#   -thread_size <integer multiple of 32 no greater than 1024> Number of GPU threads used in GPU 
#    kernels. 
#
#   -corr <decimal value> Used to determine the exponent of the variance. Default value is
#    -1. Other values are discouraged
#
#   -gpus <GPU integer IDs separate by commas> List of NVIDIA GPU IDs that the command will use
#                                     
#   -normalize Option to normalize the final result such that the diagonal contains only 1's 
#   
#
# 	gpu_pedifromsnps is a GPU optimized version of the pedifromsnps command.  
#   This command only allows for the method one algorithm that's described in help pedifromsnps.      
