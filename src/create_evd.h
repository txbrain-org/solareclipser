#ifndef CREATE_EVD_H
#define CREATE_EVD_H

#include <vector>
#include <string>

// Forward declarations
class Pedigree;
class Phenotypes;

// Simplified EVD data creation for the standalone implementation
class CreateEVD {
public:
    // Create EVD data files with explicit parameters (no globals)
    static int create_evd_data(
        Pedigree* pedigree,
        Phenotypes* phenotypes,
        const std::string& trait_name,
        const char* output_basename
    );

    // Compute eigenvalue decomposition of phi2 matrix
    static int compute_eigen_decomposition(const std::vector<std::string>& valid_ids, const char* output_basename);

    // Show help for create_evd_data command
    static void show_help();
};

#endif
