#' Kinship Matrix from Human Connectome Project
#'
#' IMPORTANT: The following description is AI generated and needs review.
#'
#' A kinship matrix containing pairwise kinship coefficients between individuals
#' from the Human Connectome Project. The kinship coefficients quantify the
#' genetic relatedness between pairs of individuals.
#'
#' @format A data frame with 5,216,656 rows and 3 variables:
#' \describe{
#'   \item{IDA}{Character. Identifier for the first individual in the pair}
#'   \item{IDB}{Character. Identifier for the second individual in the pair}
#'   \item{KIN}{Numeric. Kinship coefficient between IDA and IDB, ranging from
#'              0 (unrelated) to 1 (identical/self). A value of 0.5 indicates
#'              parent-offspring or full siblings, 0.25 indicates half-siblings
#'              or grandparent-grandchild, etc.}
#' }
#'
#' @details
#' This dataset contains kinship coefficients calculated from pedigree
#' information. The diagonal elements (IDA == IDB) have kinship = 1.0.
#' The matrix is symmetric, so kinship(IDA, IDB) == kinship(IDB, IDA).
#'
#' @source Human Connectome Project
#' @examples
#' \dontrun{
#' data(pedigree)
#' head(pedigree)
#'
#' # Find self-kinship entries (diagonal)
#' self_kin <- pedigree[pedigree$IDA == pedigree$IDB, ]
#'
#' # Find parent-offspring or sibling pairs (kinship ~ 0.5)
#' close_relatives <- pedigree[pedigree$KIN > 0.4 & pedigree$KIN < 0.6 &
#'                              pedigree$IDA != pedigree$IDB, ]
#' }
"pedigree"

#' Brain Imaging Phenotypes from Human Connectome Project
#'
#' IMPORTANT: The following description is AI generated and needs review.
#'
#' White matter tract phenotypes derived from diffusion tensor imaging (DTI)
#' for 1,052 individuals from the Human Connectome Project. The phenotypes
#' represent standardized measures of white matter microstructure across
#' major fiber tracts.
#'
#' @format A data frame with 1,052 rows and 25 variables:
#' \describe{
#'   \item{ID}{Numeric. Individual identifier matching the pedigree dataset}
#'   \item{CC}{Numeric. Corpus Callosum}
#'   \item{GCC}{Numeric. Genu of Corpus Callosum}
#'   \item{BCC}{Numeric. Body of Corpus Callosum}
#'   \item{SCC}{Numeric. Splenium of Corpus Callosum}
#'   \item{FX}{Numeric. Fornix}
#'   \item{CST}{Numeric. Corticospinal Tract}
#'   \item{IC}{Numeric. Internal Capsule}
#'   \item{ALIC}{Numeric. Anterior Limb of Internal Capsule}
#'   \item{PLIC}{Numeric. Posterior Limb of Internal Capsule}
#'   \item{RLIC}{Numeric. Retrolenticular part of Internal Capsule}
#'   \item{CR}{Numeric. Corona Radiata}
#'   \item{ACR}{Numeric. Anterior Corona Radiata}
#'   \item{SCR}{Numeric. Superior Corona Radiata}
#'   \item{PCR}{Numeric. Posterior Corona Radiata}
#'   \item{PTR}{Numeric. Posterior Thalamic Radiation}
#'   \item{SS}{Numeric. Sagittal Stratum}
#'   \item{EC}{Numeric. External Capsule}
#'   \item{CGC}{Numeric. Cingulum (cingulate gyrus)}
#'   \item{CGH}{Numeric. Cingulum (hippocampus)}
#'   \item{FXST}{Numeric. Fornix/Stria Terminalis}
#'   \item{SLF}{Numeric. Superior Longitudinal Fasciculus}
#'   \item{SFO}{Numeric. Superior Fronto-Occipital Fasciculus}
#'   \item{UNC}{Numeric. Uncinate Fasciculus}
#'   \item{TAP}{Numeric. Tapetum}
#' }
#'
#' @details
#' All phenotype values are standardized (z-scored) measures of white matter
#' microstructure. These phenotypes can be used with the pedigree data for
#' heritability analysis using the FPHI method.
#'
#' @source Human Connectome Project
#' @examples
#' \dontrun{
#' data(phenotypes)
#' head(phenotypes)
#'
#' # Summary statistics
#' summary(phenotypes$CC)
#'
#' # Correlation between different tracts
#' cor(phenotypes$GCC, phenotypes$BCC, use = "complete.obs")
#' }
"phenotypes"
