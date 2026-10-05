/*
 * fphi.h - FPHI statistical analysis
 * This module performs the core FPHI heritability estimation
 * Called by SolarSession after EVD data is prepared
 */

#ifndef FPHI_H
#define FPHI_H

#include <cstddef>
#include <string>

// Forward declarations
class Pedigree;
class Phenotypes;

// Everything FPHI reports for one trait; formatted by fphi_output.h
struct FphiResult {
    std::string trait;
    std::string pedigree_file;
    std::string phenotype_file;
    std::size_t n_subjects = 0;
    double h2r = 0.0, h2r_se = 0.0;
    double loglik = 0.0, sporadic_loglik = 0.0, p_value = 0.0;
    double mean = 0.0, mean_se = 0.0;
    double e2 = 0.0, e2_se = 0.0;
    double sd = 0.0, sd_se = 0.0;
};

class Fphi {
public:
    // Run FPHI statistical analysis on EVD data with explicit parameters (no globals)
    // Expects files: <basename>.ids, <basename>.eigenvalues, <basename>.eigenvectors
    // Fills `result`; writing it out is the caller's job (see fphi_output.h)
    static int run_fphi(
        Pedigree* pedigree,
        Phenotypes* phenotypes,
        const std::string& trait_name,
        const char* evd_data_basename,
        FphiResult& result
    );
};

#endif // FPHI_H
