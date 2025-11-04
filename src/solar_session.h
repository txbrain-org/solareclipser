#ifndef SOLAR_SESSION_H
#define SOLAR_SESSION_H

#include <memory>
#include <string>
#include "pedigree.h"
#include "phenotypes.h"

/**
 * SolarSession - Session manager for FPHI analysis
 *
 * Provides a stateful API for running FPHI analysis:
 * 1. load_pedigree() - Load pedigree data
 * 2. load_phenotypes() - Load phenotype data
 * 3. select_trait() - Select trait for analysis
 * 4. run_fphi() - Run FPHI analysis
 *
 * This class encapsulates all analysis state without using globals,
 * making it suitable for the R package interface.
 */
class SolarSession {
public:
    SolarSession() = default;
    ~SolarSession() = default;

    // Prevent copying (use move if needed)
    SolarSession(const SolarSession&) = delete;
    SolarSession& operator=(const SolarSession&) = delete;

    // === API Methods ===

    /**
     * Load pedigree file
     * @param file Path to pedigree CSV file
     * @param threshold Kinship threshold (0.0 for theoretical, >0 for empirical)
     * @param output_dir Directory where pedigree output files will be created
     * @return 0 on success, 1 on failure
     */
    int load_pedigree(const std::string& file, double threshold, const std::string& output_dir);

    /**
     * Load phenotype file
     * @param file Path to phenotype CSV file
     * @return 0 on success, 1 on failure
     * @requires load_pedigree() must be called first
     */
    int load_phenotypes(const std::string& file);

    /**
     * Select trait for analysis
     * @param trait Name of trait column in phenotype file
     * @return 0 on success, 1 on failure
     * @requires load_phenotypes() must be called first
     */
    int select_trait(const std::string& trait);

    /**
     * Run FPHI analysis
     * @param output_basename Base name for output files
     * @return 0 on success, 1 on failure
     * @requires select_trait() must be called first
     *
     * Creates output files:
     *   - <output_basename>.ids
     *   - <output_basename>.eigenvalues
     *   - <output_basename>.eigenvectors
     *   - <output_basename>.notes
     *   - <output_basename>_fphi_results.out
     *   - <output_basename>_parameters.out
     */
    int run_fphi(const std::string& output_basename);

    // === Query Methods ===

    bool has_pedigree() const { return pedigree_ != nullptr; }
    bool has_phenotypes() const { return phenotypes_ != nullptr; }
    bool has_trait() const { return !trait_.empty(); }

    std::string get_trait_name() const { return trait_; }
    Pedigree* get_pedigree() const { return pedigree_.get(); }
    Phenotypes* get_phenotypes() const { return phenotypes_.get(); }

    /**
     * Reset session state (clear all loaded data)
     */
    void reset();

private:
    std::unique_ptr<Pedigree> pedigree_;
    std::unique_ptr<Phenotypes> phenotypes_;
    std::string trait_;
    double threshold_ = 0.0;
    std::string output_dir_;  // Output directory for all analysis files
};

#endif // SOLAR_SESSION_H
