#include <Rcpp.h>
#include <memory>
#include <sstream>
#include "solar_session.h"
#include "fphi_output.h"
#include "solar_log.h"

using namespace Rcpp;

namespace {
    std::unique_ptr<SolarSession> g_default_session;

    SolarSession& get_default_session() {
        if (!g_default_session) {
            g_default_session = std::make_unique<SolarSession>();
        }
        return *g_default_session;
    }

    // Raise what a session call left in solar_log(): "Warning: " lines as R
    // warnings and, if the call failed (rc != 0), the other lines as an R error
    void check(int rc, const char* what) {
        std::istringstream log(solar_log().str());
        solar_log().str("");
        std::string line, error;
        while (std::getline(log, line)) {
            if (line.rfind("Warning: ", 0) == 0) {
                Rcpp::warning("%s", line.substr(9));
            } else if (!line.empty()) {
                if (line.rfind("Error: ", 0) == 0) line = line.substr(7);
                error += (error.empty() ? "" : "\n") + line;
            }
        }
        if (rc != 0) {
            Rcpp::stop(error.empty() ? std::string(what) + " failed" : error);
        }
    }
}

//' Load pedigree file
//'
//' Load a pedigree file for analysis. This must be called before loading phenotypes.
//'
//' @param pedigree_filename Path to the pedigree CSV file
//' @param threshold Kinship threshold (0.0 for theoretical pedigrees, >0 for empirical)
//' @param output_dir Directory where pedigree output files will be created
//' @return `TRUE`, invisibly. Signals an error on failure.
//' @export
// [[Rcpp::export(invisible = true)]]
bool solar_load_pedigree(std::string pedigree_filename, double threshold = 0.0, std::string output_dir = "") {
    solar_log().str("");
    check(get_default_session().load_pedigree(pedigree_filename, threshold, output_dir),
          "Loading the pedigree");
    return true;
}

//' Load phenotype file
//'
//' Load a phenotype file for analysis. Pedigree must be loaded first.
//'
//' @param phenotype_filename Path to the phenotype CSV file
//' @return `TRUE`, invisibly. Signals an error on failure.
//' @export
// [[Rcpp::export(invisible = true)]]
bool solar_load_phenotype(std::string phenotype_filename) {
    solar_log().str("");
    check(get_default_session().load_phenotypes(phenotype_filename), "Loading the phenotypes");
    return true;
}

//' Select trait for analysis
//'
//' Select a trait from the loaded phenotype file. Phenotypes must be loaded first.
//'
//' @param trait_name Name of the trait column in the phenotype file
//' @return `TRUE`, invisibly. Signals an error on failure.
//' @export
// [[Rcpp::export(invisible = true)]]
bool solar_select_trait(std::string trait_name) {
    solar_log().str("");
    check(get_default_session().select_trait(trait_name), "Selecting the trait");
    return true;
}

//' Run FPHI analysis
//'
//' Run FPHI heritability analysis for the selected trait.
//' Pedigree, phenotypes, and trait must all be loaded/selected first.
//'
//' By default nothing is printed and only the EVD working files
//' `<output_basename>.ids`, `.eigenvalues`, `.eigenvectors` and `.notes` are
//' created. To also get the results as text, list formats in `format`: each
//' is printed to standard output, in the order given, and when `write_files`
//' is `TRUE` written to its result file(s):
//'   - `"csv"`, `"tsv"`: a results table and a parameters table
//'     (read with [utils::read.csv()] / [utils::read.delim()]);
//'     `<output_basename>_fphi_results.out` and `_parameters.out` (csv),
//'     `_fphi_results.tsv` and `_parameters.tsv` (tsv)
//'   - `"json"`, `"yaml"`: one document holding results and parameters;
//'     `<output_basename>_fphi.json`, `_fphi.yaml`
//'   - `"solar"`: the summary block printed by the original SOLAR-Eclipse
//'     `fphi` command, for diffing against its output;
//'     `<output_basename>_fphi.solar.out`
//'
//' @param output_basename Base name for output files (default: "fphi_output")
//' @param format Character vector of text formats to print: any of "csv",
//'   "tsv", "json", "yaml", "solar" (default: none)
//' @param write_files Write the result files of the formats in `format`
//'   (default: TRUE)
//' @return A list of two data frames:
//'   - `results`: one row with `trait`, `h2r`, `se` (of h2r), `loglik`,
//'     `sporadic_loglik`, `p_value` and `n_subjects`
//'   - `parameters`: one row per fitted parameter (`mean`, `e2`, `h2r`,
//'     `sd`) with columns `parameter`, `value` and `se`
//'
//'   The pedigree and phenotype file names are kept in the list's
//'   `pedigree` and `phenotypes` attributes. Signals an error on failure.
//' @export
// [[Rcpp::export]]
List solar_run_fphi(std::string output_basename = "fphi_output",
                    CharacterVector format = CharacterVector::create(),
                    bool write_files = true) {
    std::vector<OutputFormat> formats;
    for (R_xlen_t i = 0; i < format.size(); i++) {
        std::string name = as<std::string>(format[i]);
        OutputFormat f;
        if (!parse_output_format(name, f)) {
            stop("Unknown output format '" + name +
                 "' (expected csv, tsv, json, yaml or solar)");
        }
        formats.push_back(f);
    }

    FphiResult r;
    solar_log().str("");
    check(get_default_session().run_fphi(output_basename, formats, write_files, r),
          "FPHI analysis");

    DataFrame results = DataFrame::create(
        _["trait"] = r.trait,
        _["h2r"] = r.h2r,
        _["se"] = r.h2r_se,
        _["loglik"] = r.loglik,
        _["sporadic_loglik"] = r.sporadic_loglik,
        _["p_value"] = r.p_value,
        _["n_subjects"] = static_cast<int>(r.n_subjects),
        _["stringsAsFactors"] = false);
    DataFrame parameters = DataFrame::create(
        _["parameter"] = CharacterVector::create("mean", "e2", "h2r", "sd"),
        _["value"] = NumericVector::create(r.mean, r.e2, r.h2r, r.sd),
        _["se"] = NumericVector::create(r.mean_se, r.e2_se, r.h2r_se, r.sd_se),
        _["stringsAsFactors"] = false);
    List out = List::create(_["results"] = results, _["parameters"] = parameters);
    out.attr("pedigree") = r.pedigree_file;
    out.attr("phenotypes") = r.phenotype_file;
    return out;
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
