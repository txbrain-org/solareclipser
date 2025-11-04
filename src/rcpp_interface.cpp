#include <Rcpp.h>
#include <memory>
#include "solar_session.h"

using namespace Rcpp;

namespace {
    std::unique_ptr<SolarSession> g_default_session;

    SolarSession& get_default_session() {
        if (!g_default_session) {
            g_default_session = std::make_unique<SolarSession>();
        }
        return *g_default_session;
    }
}

//' Load pedigree file
//'
//' Load a pedigree file for analysis. This must be called before loading phenotypes.
//'
//' @param pedigree_filename Path to the pedigree CSV file
//' @param threshold Kinship threshold (0.0 for theoretical pedigrees, >0 for empirical)
//' @param output_dir Directory where pedigree output files will be created
//' @return Returns 0 on success, 1 on failure
//' @export
// [[Rcpp::export]]
int solar_load_pedigree(std::string pedigree_filename, double threshold = 0.0, std::string output_dir = "") {
    return get_default_session().load_pedigree(pedigree_filename, threshold, output_dir);
}

//' Load phenotype file
//'
//' Load a phenotype file for analysis. Pedigree must be loaded first.
//'
//' @param phenotype_filename Path to the phenotype CSV file
//' @return Returns 0 on success, 1 on failure
//' @export
// [[Rcpp::export]]
int solar_load_phenotype(std::string phenotype_filename) {
    return get_default_session().load_phenotypes(phenotype_filename);
}

//' Select trait for analysis
//'
//' Select a trait from the loaded phenotype file. Phenotypes must be loaded first.
//'
//' @param trait_name Name of the trait column in the phenotype file
//' @return Returns 0 on success, 1 on failure
//' @export
// [[Rcpp::export]]
int solar_select_trait(std::string trait_name) {
    return get_default_session().select_trait(trait_name);
}

//' Run FPHI analysis
//'
//' Run FPHI heritability analysis for the selected trait.
//' Pedigree, phenotypes, and trait must all be loaded/selected first.
//'
//' Creates output files:
//'   - <output_basename>.ids
//'   - <output_basename>.eigenvalues
//'   - <output_basename>.eigenvectors
//'   - <output_basename>.notes
//'   - <output_basename>_fphi_results.out
//'   - <output_basename>_parameters.out
//'
//' @param output_basename Base name for output files (default: "fphi_output")
//' @return Returns 0 on success, 1 on failure
//' @export
// [[Rcpp::export]]
int solar_run_fphi(std::string output_basename = "fphi_output") {
    return get_default_session().run_fphi(output_basename);
}

//' Reset session state
//'
//' Clear all loaded data (pedigree, phenotypes, selected trait).
//' Useful for starting a new analysis or freeing memory.
//'
//' @export
// [[Rcpp::export]]
void solar_reset() {
    g_default_session.reset();
}
