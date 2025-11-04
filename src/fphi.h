/*
 * fphi.h - FPHI statistical analysis
 * This module performs the core FPHI heritability estimation
 * Called by SolarSession after EVD data is prepared
 */

#ifndef FPHI_H
#define FPHI_H

#include <string>

// Forward declarations
class Pedigree;
class Phenotypes;

class Fphi {
public:
    // Run FPHI statistical analysis on EVD data with explicit parameters (no globals)
    // Expects files: <basename>.ids, <basename>.eigenvalues, <basename>.eigenvectors
    // Creates: <basename>_fphi_results.out, <basename>_parameters.out
    static int run_fphi(
        Pedigree* pedigree,
        Phenotypes* phenotypes,
        const std::string& trait_name,
        const char* evd_data_basename
    );
};

#endif // FPHI_H
