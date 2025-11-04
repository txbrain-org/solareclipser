#include <Rcpp.h>
#define COUT Rcpp::Rcout
#define CERR Rcpp::Rcerr

#include "solar_session.h"
#include "pedigree_loader.h"
#include "create_evd.h"
#include "fphi.h"

int SolarSession::load_pedigree(const std::string& file, double threshold, const std::string& output_dir) {
    COUT << "Loading pedigree: " << file << std::endl;

    if (threshold > 0.0) {
        COUT << "  Using kinship threshold: " << threshold << std::endl;
    }

    COUT << "  Output directory: " << output_dir << std::endl;

    // Use PedigreeLoader Builder pattern with provided output directory
    auto loader = PedigreeLoader::Builder()
        .from_file(file)
        .with_threshold(threshold)
        .with_output_dir(output_dir)
        .build();

    if (!loader) {
        CERR << "Error: Failed to configure pedigree loader" << std::endl;
        return 1;
    }

    pedigree_ = loader->load();

    if (!pedigree_) {
        CERR << "Error: Failed to load pedigree" << std::endl;
        return 1;
    }

    // Store output directory and threshold for later use
    output_dir_ = output_dir;
    threshold_ = threshold;

    // Set sex variable
    Pedigree::SexVar(pedigree_->sex_len() > 0 ? 1 : 0);

    COUT << "Pedigree loaded successfully" << std::endl;
    return 0;
}

int SolarSession::load_phenotypes(const std::string& file) {
    if (!pedigree_) {
        CERR << "Error: Cannot load phenotypes - pedigree not loaded yet" << std::endl;
        CERR << "Please call solar_load_pedigree() first" << std::endl;
        return 1;
    }

    COUT << "Loading phenotypes: " << file << std::endl;

    phenotypes_ = std::make_unique<Phenotypes>();
    if (!phenotypes_->load(file)) {
        CERR << "Error: Failed to load phenotypes" << std::endl;
        phenotypes_.reset();
        return 1;
    }

    phenotypes_->describe();

    COUT << "Phenotypes loaded successfully" << std::endl;
    return 0;
}

int SolarSession::select_trait(const std::string& trait) {
    if (!phenotypes_) {
        CERR << "Error: Cannot select trait - phenotypes not loaded yet" << std::endl;
        CERR << "Please call solar_load_phenotype() first" << std::endl;
        return 1;
    }

    // Check if trait exists in phenotypes
    if (!phenotypes_->has_trait(trait)) {
        CERR << "Error: Trait '" << trait << "' not found in phenotype file" << std::endl;
        CERR << "Available traits:" << std::endl;
        const auto& headers = phenotypes_->get_headers();
        for (const auto& header : headers) {
            if (header != "id" && header != "ID") {
                CERR << "  - " << header << std::endl;
            }
        }
        return 1;
    }

    trait_ = trait;
    COUT << "Selected trait: " << trait_ << std::endl;
    return 0;
}

int SolarSession::run_fphi(const std::string& output_basename) {
    // Validate all prerequisites
    if (!pedigree_) {
        CERR << "Error: Cannot run FPHI - pedigree not loaded" << std::endl;
        CERR << "Please call solar_load_pedigree() first" << std::endl;
        return 1;
    }

    if (!phenotypes_) {
        CERR << "Error: Cannot run FPHI - phenotypes not loaded" << std::endl;
        CERR << "Please call solar_load_phenotype() first" << std::endl;
        return 1;
    }

    if (trait_.empty()) {
        CERR << "Error: Cannot run FPHI - trait not selected" << std::endl;
        CERR << "Please call solar_select_trait() first" << std::endl;
        return 1;
    }

    COUT << std::endl;
    COUT << "======================================" << std::endl;
    COUT << "FPHI Analysis" << std::endl;
    COUT << "======================================" << std::endl;
    COUT << "Trait: " << trait_ << std::endl;
    COUT << "Output Basename: " << output_basename << std::endl;
    COUT << "======================================" << std::endl;
    COUT << std::endl;

    // Step 1: Create EVD data
    COUT << "Creating EVD data..." << std::endl;
    int evd_result = CreateEVD::create_evd_data(
        pedigree_.get(),
        phenotypes_.get(),
        trait_,
        output_basename.c_str()
    );

    if (evd_result != 0) {
        CERR << "Error: Failed to create EVD data for trait '" << trait_ << "'" << std::endl;
        return 1;
    }

    // Step 2: Run FPHI analysis
    COUT << "Running FPHI analysis..." << std::endl;
    int fphi_result = Fphi::run_fphi(
        pedigree_.get(),
        phenotypes_.get(),
        trait_,
        output_basename.c_str()
    );

    if (fphi_result != 0) {
        CERR << "Error: FPHI analysis failed for trait '" << trait_ << "'" << std::endl;
        return 1;
    }

    COUT << std::endl;
    COUT << "======================================" << std::endl;
    COUT << "Analysis Complete" << std::endl;
    COUT << "======================================" << std::endl;
    COUT << "Output: " << output_basename << "_fphi_results.out" << std::endl;

    return 0;
}

void SolarSession::reset() {
    pedigree_.reset();
    phenotypes_.reset();
    trait_.clear();
    threshold_ = 0.0;
    output_dir_.clear();
}
