#' Kinship Matrix from Human Connectome Project
#'
#' An empirical kinship matrix for 2,284 Human Connectome Project
#' participants, as one row per ordered pair of individuals: the format
#' [solar_load_pedigree()] reads. It is estimated from genetic data rather
#' than a recorded pedigree, so it includes small negative values.
#'
#' @format A data frame with 5,216,656 rows (2,284 x 2,284 pairs) and 3
#'   variables:
#' \describe{
#'   \item{IDA}{Character. Identifier of the first individual in the pair}
#'   \item{IDB}{Character. Identifier of the second individual in the pair}
#'   \item{KIN}{Numeric. Twice the kinship coefficient between IDA and IDB:
#'              1 for an individual with itself (and about 1 for monozygotic
#'              twins), about 0.5 for first-degree relatives, about 0.25 for
#'              second-degree relatives, and near 0 (from -0.07) for
#'              unrelated pairs}
#' }
#'
#' @details
#' The matrix is complete and symmetric: every pair appears in both orders
#' with the same value, and every individual has a self-pair with `KIN = 1`.
#' 999 of the individuals in [phenotypes] are in it.
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
#' White matter phenotypes for 1,052 Human Connectome Project participants,
#' one per tract region, derived from diffusion tensor imaging (DTI).
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
#' Every trait has mean 0 and the same standard deviation (0.995), with no
#' missing values, consistent with a rank-based inverse-normal
#' transformation. 999 of the individuals are in [pedigree]; FPHI analyses
#' only those. There are no covariate columns.
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
