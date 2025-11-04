#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <iomanip>
#include <cmath>
#include <algorithm>

#include <Rcpp.h>
#define COUT Rcpp::Rcout
#define CERR Rcpp::Rcerr

#include "fphi.h"
#include "pedigree.h"
#include "phenotypes.h"

// FORTRAN cdfchi routine (exact match to original SOLAR)
extern "C" void cdfchi_(int* which, double* p, double* q, double* chi, double* df, int* status, double* bound);

// Helper function to extract directory from a path
static std::string extract_directory(const char* path) {
    if (!path || strlen(path) == 0) {
        return "";
    }

    std::string fullpath(path);
    size_t last_slash = fullpath.find_last_of("/\\");

    if (last_slash == std::string::npos) {
        return ""; // No directory component
    }

    return fullpath.substr(0, last_slash);
}

// High-precision chi-square p-value calculation (matching original SOLAR)
static double chicdf(double chi, double df) {
    double p, q, bound;
    int status = 0;
    int which = 1;
    
    cdfchi_(&which, &p, &q, &chi, &df, &status, &bound);
    return q/2.0;  // Matches original SOLAR implementation
}


// Helper functions for constrained optimization (matching original SOLAR)
static inline double calculate_constraint(double x) {
    return x * x / (1.0 + x * x);
}

static inline double calculate_dconstraint(double x) {
    return 2 * x / std::pow(1 + x * x, 2);
}

static inline double calculate_ddconstraint(double x) {
    return -2 * (3 * x * x - 1) / std::pow((x * x + 1), 3);
}

// Log-likelihood calculation (exact match to original SOLAR)
static inline double calculate_fphi_loglik(double variance, const std::vector<double>& sigma, size_t n_subjects) {
    double log_sigma_sum = 0.0;
    for (double s : sigma) {
        log_sigma_sum += std::log(std::abs(s));
    }
    return -0.5 * (std::log(std::abs(variance)) * n_subjects + log_sigma_sum + n_subjects);
}

static inline double calculate_dloglik(const std::vector<double>& lambda_minus_one,
                                     const std::vector<double>& residual_squared,
                                     const std::vector<double>& sigma_inv_var, double variance) {
    double part_one = 0.0, part_two = 0.0;
    for (size_t i = 0; i < lambda_minus_one.size(); i++) {
        part_one += variance * lambda_minus_one[i] * sigma_inv_var[i];
        part_two += variance * lambda_minus_one[i] * residual_squared[i] * sigma_inv_var[i] * sigma_inv_var[i];
    }
    return -0.5 * (part_one - part_two);
}

static inline double calculate_ddloglik(const std::vector<double>& lambda_minus_one,
                                      const std::vector<double>& residual_squared,
                                      const std::vector<double>& sigma_inv_var, double variance) {
    double part_one = 0.0, part_two = 0.0;
    for (size_t i = 0; i < lambda_minus_one.size(); i++) {
        double lm1_sq = lambda_minus_one[i] * lambda_minus_one[i];
        double sig_sq = sigma_inv_var[i] * sigma_inv_var[i];
        part_one += variance * variance * lm1_sq * sig_sq;
        part_two += 2.0 * variance * variance * lm1_sq * residual_squared[i] * sigma_inv_var[i] * sig_sq;
    }
    return -0.5 * (-part_one + part_two);
}

// Matrix inversion for Hessian computation
static bool matrix_invert(std::vector<std::vector<double>>& matrix) {
    size_t n = matrix.size();
    std::vector<std::vector<double>> identity(n, std::vector<double>(n, 0.0));

    // Create identity matrix
    for (size_t i = 0; i < n; i++) {
        identity[i][i] = 1.0;
    }

    // Gaussian elimination with partial pivoting
    for (size_t i = 0; i < n; i++) {
        // Find pivot
        size_t max_row = i;
        for (size_t k = i + 1; k < n; k++) {
            if (std::abs(matrix[k][i]) > std::abs(matrix[max_row][i])) {
                max_row = k;
            }
        }

        // Swap rows
        if (max_row != i) {
            std::swap(matrix[i], matrix[max_row]);
            std::swap(identity[i], identity[max_row]);
        }

        // Check for singular matrix
        if (std::abs(matrix[i][i]) < 1e-10) {
            return false;
        }

        // Make diagonal element 1
        double diag = matrix[i][i];
        for (size_t j = 0; j < n; j++) {
            matrix[i][j] /= diag;
            identity[i][j] /= diag;
        }

        // Eliminate column
        for (size_t k = 0; k < n; k++) {
            if (k != i) {
                double factor = matrix[k][i];
                for (size_t j = 0; j < n; j++) {
                    matrix[k][j] -= factor * matrix[i][j];
                    identity[k][j] -= factor * identity[i][j];
                }
            }
        }
    }

    // Copy result back
    matrix = identity;
    return true;
}

// Additional helper functions for constraint optimization
static double reverse_constraint(double x) {
    return sqrt(x/(1-x));
}

static inline double calculate_ddloglik_with_constraint(const double t, const double dloglik, const double ddloglik) {
    return pow(calculate_dconstraint(t), 2)*ddloglik + calculate_ddconstraint(t)*dloglik;
}

static inline double calculate_dloglik_with_constraint(const double t, const double dloglik) {
    return calculate_dconstraint(t)*dloglik;
}

// Exact SOLAR find_max_loglik_2 implementation
static double find_max_loglik_2(const int precision, const std::vector<double>& Y,
                               const std::vector<std::vector<double>>& aux,
                               const std::vector<double>& X,
                               double& result_loglik, double& result_variance, double& result_se,
                               double& result_mean, double& result_mean_se,
                               double& result_e2, double& result_e2_se,
                               double& result_sd, double& result_sd_se) {
    size_t n_subjects = Y.size();
    
    // Initialize like SOLAR lines 143-147
    double parameter_t = 1.0;
    double h2r = 0.5;
    std::vector<double> theta(2);
    theta[0] = 0.5;
    theta[1] = 0.5;
    
    // Sigma = aux * theta (lines 148)
    std::vector<double> Sigma(n_subjects);
    for (size_t i = 0; i < n_subjects; i++) {
        Sigma[i] = aux[i][0] * theta[0] + aux[i][1] * theta[1];
    }
    
    // Omega = Sigma^-1 diagonal (line 149)
    std::vector<double> Omega_diag(n_subjects);
    for (size_t i = 0; i < n_subjects; i++) {
        Omega_diag[i] = 1.0 / Sigma[i];
    }
    
    // XTOX = X^T * Omega * X (lines 150-151)
    double XTOX = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        XTOX += X[i] * Omega_diag[i] * X[i];
    }
    
    if (XTOX == 0.0) {
        return 0.0; // Convergence failure
    }
    
    // beta = XTOX^-1 * X^T * Omega * Y (line 156)
    double XTOmegaY = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        XTOmegaY += X[i] * Omega_diag[i] * Y[i];
    }
    double beta = XTOmegaY / XTOX;
    
    // residual = Y - X*beta (line 157)
    std::vector<double> residual(n_subjects);
    std::vector<double> residual_squared(n_subjects);
    for (size_t i = 0; i < n_subjects; i++) {
        residual[i] = Y[i] - X[i] * beta;
        residual_squared[i] = residual[i] * residual[i];
    }
    
    // variance = residual^T * Omega * residual / n (line 159)
    double variance = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        variance += residual_squared[i] * Omega_diag[i];
    }
    variance /= n_subjects;
    
    double loglik = calculate_fphi_loglik(variance, Sigma, n_subjects);
    
    // lambda_minus_one = aux.col(1) - 1 (line 161)
    std::vector<double> lambda_minus_one(n_subjects);
    for (size_t i = 0; i < n_subjects; i++) {
        lambda_minus_one[i] = aux[i][1] - 1.0;
    }
    
    // sigma_inverse_var = (Sigma * variance)^-1 (line 162)
    std::vector<double> sigma_inverse_var(n_subjects);
    for (size_t i = 0; i < n_subjects; i++) {
        sigma_inverse_var[i] = 1.0 / (Sigma[i] * variance);
    }
    
    // Calculate derivatives (lines 163-164)
    double dloglik = calculate_dloglik(lambda_minus_one, residual_squared, sigma_inverse_var, variance);
    double ddloglik = calculate_ddloglik(lambda_minus_one, residual_squared, sigma_inverse_var, variance);
    double score = calculate_dloglik_with_constraint(parameter_t, dloglik);
    double hessian = calculate_ddloglik_with_constraint(parameter_t, dloglik, ddloglik);
    double delta = -score / hessian;
    double new_h2r = 0.0;
    
    // Update parameter_t and h2r (lines 169-172)
    if (delta == delta) { // Check for NaN
        parameter_t += delta;
        new_h2r = calculate_constraint(parameter_t);
    }
    
    // Main optimization loop (lines 174-206)
    const double end = std::pow(10, -precision);
    int iter = 0;
    while (delta == delta && std::abs(new_h2r - h2r) >= end && ++iter < 100) {
        h2r = new_h2r;
        
        theta[0] = 1.0 - h2r;
        theta[1] = h2r;
        
        // Update Sigma
        for (size_t i = 0; i < n_subjects; i++) {
            Sigma[i] = aux[i][0] * theta[0] + aux[i][1] * theta[1];
            sigma_inverse_var[i] = 1.0 / Sigma[i];
        }
        
        // Update Omega
        for (size_t i = 0; i < n_subjects; i++) {
            Omega_diag[i] = sigma_inverse_var[i];
        }
        
        // Recalculate XTOX
        XTOX = 0.0;
        for (size_t i = 0; i < n_subjects; i++) {
            XTOX += X[i] * Omega_diag[i] * X[i];
        }
        
        if (XTOX == 0.0) {
            return 0.0; // Convergence failure
        }
        
        // Recalculate beta
        XTOmegaY = 0.0;
        for (size_t i = 0; i < n_subjects; i++) {
            XTOmegaY += X[i] * Omega_diag[i] * Y[i];
        }
        beta = XTOmegaY / XTOX;
        
        // Update residual and variance
        for (size_t i = 0; i < n_subjects; i++) {
            residual[i] = Y[i] - X[i] * beta;
            residual_squared[i] = residual[i] * residual[i];
        }
        
        variance = 0.0;
        for (size_t i = 0; i < n_subjects; i++) {
            variance += residual_squared[i] * sigma_inverse_var[i];
        }
        variance /= n_subjects;
        
        // Update sigma_inverse_var with new variance
        for (size_t i = 0; i < n_subjects; i++) {
            sigma_inverse_var[i] /= variance;
        }
        
        loglik = calculate_fphi_loglik(variance, Sigma, n_subjects);
        dloglik = calculate_dloglik(lambda_minus_one, residual_squared, sigma_inverse_var, variance);
        ddloglik = calculate_ddloglik(lambda_minus_one, residual_squared, sigma_inverse_var, variance);
        score = calculate_dloglik_with_constraint(parameter_t, dloglik);
        hessian = calculate_ddloglik_with_constraint(parameter_t, dloglik, ddloglik);
        delta = -score / hessian;
        
        if (delta == delta) {
            parameter_t += delta;
            new_h2r = calculate_constraint(parameter_t);
        }
    }
    
    // Boundary testing (lines 207-233)
    if ((h2r >= 0.9 || h2r <= 0.1) && h2r == h2r) {
        double test_h2r = (h2r >= 0.9) ? 1.0 : 0.0;
        
        std::vector<double> test_theta(2);
        test_theta[0] = 1.0 - test_h2r;
        test_theta[1] = test_h2r;
        
        std::vector<double> test_sigma(n_subjects);
        std::vector<double> test_sigma_inverse(n_subjects);
        for (size_t i = 0; i < n_subjects; i++) {
            test_sigma[i] = aux[i][0] * test_theta[0] + aux[i][1] * test_theta[1];
            test_sigma_inverse[i] = 1.0 / test_sigma[i];
        }
        
        double test_XTOX = 0.0;
        for (size_t i = 0; i < n_subjects; i++) {
            test_XTOX += X[i] * test_sigma_inverse[i] * X[i];
        }
        
        if (test_XTOX != 0.0) {
            double test_XTOmegaY = 0.0;
            for (size_t i = 0; i < n_subjects; i++) {
                test_XTOmegaY += X[i] * test_sigma_inverse[i] * Y[i];
            }
            double test_beta = test_XTOmegaY / test_XTOX;
            
            double test_variance = 0.0;
            for (size_t i = 0; i < n_subjects; i++) {
                double test_residual = Y[i] - X[i] * test_beta;
                test_variance += test_residual * test_residual * test_sigma_inverse[i];
            }
            test_variance /= n_subjects;
            
            double test_loglik = calculate_fphi_loglik(test_variance, test_sigma, n_subjects);
            
            if (test_loglik > loglik) {
                beta = test_beta;
                theta = test_theta;
                h2r = test_h2r;
                variance = test_variance;
                loglik = test_loglik;
            }
        }
    }
    
    // Calculate final parameter estimates and their standard errors
    std::vector<double> final_sigma(n_subjects);
    std::vector<double> final_theta(2);
    final_theta[0] = 1.0 - h2r;
    final_theta[1] = h2r;

    for (size_t i = 0; i < n_subjects; i++) {
        final_sigma[i] = variance * (aux[i][0] * final_theta[0] + aux[i][1] * final_theta[1]);
    }

    // Recalculate final beta (mean parameter)
    std::vector<double> final_omega_inv(n_subjects);
    for (size_t i = 0; i < n_subjects; i++) {
        final_omega_inv[i] = 1.0 / final_sigma[i];
    }

    double final_XTOX = 0.0;
    double final_XTOmegaY = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        final_XTOX += X[i] * final_omega_inv[i] * X[i];
        final_XTOmegaY += X[i] * final_omega_inv[i] * Y[i];
    }
    double final_beta = final_XTOmegaY / final_XTOX;

    // Parameter values - match original SOLAR exactly
    result_mean = final_beta;
    result_e2 = 1.0 - h2r;  // Store as proportion, not absolute variance
    result_sd = std::sqrt(variance);

    // Calculate standard errors using exact SOLAR Hessian approach
    // Recalculate final residuals for Hessian computation
    std::vector<double> final_residual(n_subjects);
    for (size_t i = 0; i < n_subjects; i++) {
        final_residual[i] = Y[i] - X[i] * final_beta;
    }

    // Convert to match original SOLAR format for Hessian calculation
    std::vector<double> one_minus_lambda(n_subjects);
    std::vector<double> final_omega_diagonal(n_subjects);
    for (size_t i = 0; i < n_subjects; i++) {
        one_minus_lambda[i] = 1.0 - aux[i][1];  // 1 - eigenvalues
        final_omega_diagonal[i] = 1.0 / final_sigma[i];
    }

    // Compute observed Hessian (exact SOLAR implementation)
    double SD = std::sqrt(variance);

    // Beta-beta block (1x1 since X is all ones)
    double beta_hessian = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        beta_hessian += X[i] * final_omega_diagonal[i] * X[i];
    }

    // Beta-e2 cross terms
    double beta_var_comp_hessian = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        beta_var_comp_hessian += SD * SD * X[i] * final_omega_diagonal[i] * final_omega_diagonal[i] * one_minus_lambda[i] * final_residual[i];
    }

    // Beta-SD cross terms
    double beta_SD_hessian = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        beta_SD_hessian += 2.0 * X[i] * final_residual[i] * final_omega_diagonal[i] / SD;
    }

    // e2-e2 block
    double one_minus_lambda_squared_sum = 0.0;
    double residual_term_sum = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        double oml_sq = one_minus_lambda[i] * one_minus_lambda[i];
        double omega_sq = final_omega_diagonal[i] * final_omega_diagonal[i];
        one_minus_lambda_squared_sum += oml_sq * omega_sq;
        residual_term_sum += oml_sq * final_omega_diagonal[i] * omega_sq * final_residual[i] * final_residual[i];
    }
    double e2_hessian = -std::pow(SD, 4.0) * (0.5 * one_minus_lambda_squared_sum - residual_term_sum);

    // SD-e2 cross terms
    double SD_e2_hessian = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        SD_e2_hessian += SD * one_minus_lambda[i] * std::pow(final_residual[i] * final_omega_diagonal[i], 2);
    }

    // SD-SD block
    double residual_squared_omega_sum = 0.0;
    for (size_t i = 0; i < n_subjects; i++) {
        residual_squared_omega_sum += final_residual[i] * final_residual[i] * final_omega_diagonal[i];
    }
    double SD_hessian = -std::pow(SD, -2.0) * (n_subjects - 3.0 * residual_squared_omega_sum);

    // Build 3x3 Hessian matrix: [beta, e2, SD]
    std::vector<std::vector<double>> hessian_matrix(3, std::vector<double>(3, 0.0));
    hessian_matrix[0][0] = beta_hessian;
    hessian_matrix[0][1] = hessian_matrix[1][0] = beta_var_comp_hessian;
    hessian_matrix[0][2] = hessian_matrix[2][0] = beta_SD_hessian;
    hessian_matrix[1][1] = e2_hessian;
    hessian_matrix[1][2] = hessian_matrix[2][1] = SD_e2_hessian;
    hessian_matrix[2][2] = SD_hessian;

    // Invert Hessian to get covariance matrix
    if (matrix_invert(hessian_matrix)) {
        // Standard errors are square roots of diagonal elements
        result_mean_se = std::sqrt(std::abs(hessian_matrix[0][0]));
        result_e2_se = std::sqrt(std::abs(hessian_matrix[1][1]));  // Same as h2r SE in original
        result_se = result_e2_se;  // h2r and e2 have same SE in original SOLAR
        result_sd_se = std::sqrt(std::abs(hessian_matrix[2][2]));
    } else {
        result_se = 0.0;
        result_mean_se = 0.0;
        result_e2_se = 0.0;
        result_sd_se = 0.0;
    }

    result_loglik = loglik;
    result_variance = variance;
    return h2r;
}

int Fphi::run_fphi(
    Pedigree* pedigree,
    Phenotypes* phenotypes,
    const std::string& trait_name,
    const char* evd_data_basename
) {
    if (!evd_data_basename) {
        CERR << "Error: No EVD data filename specified" << std::endl;
        return 1;
    }

    if (!pedigree) {
        CERR << "Error: No pedigree loaded" << std::endl;
        return 1;
    }

    if (!phenotypes) {
        CERR << "Error: No phenotype file is currently loaded" << std::endl;
        return 1;
    }

    if (trait_name.empty()) {
        CERR << "Error: No trait has been selected" << std::endl;
        return 1;
    }

    // Extract output directory from evd_data_basename
    std::string output_dir = extract_directory(evd_data_basename);
    
    // Check that required EVD files exist (matching original structure)
    std::string ids_file = std::string(evd_data_basename) + ".ids";
    std::string eigenvals_file = std::string(evd_data_basename) + ".eigenvalues";
    std::string eigenvecs_file = std::string(evd_data_basename) + ".eigenvectors";
    std::string notes_file = std::string(evd_data_basename) + ".notes";
    
    // Try to read IDs file
    std::ifstream ids_stream(ids_file);
    if (!ids_stream) {
        CERR << "Error: Cannot read EVD IDs file: " << ids_file << std::endl;
        CERR << "Make sure create_evd_data has been run first" << std::endl;
        return 1;
    }
    
    std::vector<std::string> ids;
    std::string line;
    if (std::getline(ids_stream, line)) {
        std::stringstream ss(line);
        std::string id;
        while (ss >> id) {
            ids.push_back(id);
        }
    }
    ids_stream.close();
    
    if (ids.empty()) {
        CERR << "Error: No IDs found in EVD data" << std::endl;
        return 1;
    }
    
    size_t n_subjects = ids.size();
    
    // Try to read eigenvalues
    std::ifstream eigenvals_stream(eigenvals_file);
    if (!eigenvals_stream) {
        CERR << "Error: Cannot read eigenvalues file: " << eigenvals_file << std::endl;
        return 1;
    }
    
    std::vector<double> eigenvalues;
    if (std::getline(eigenvals_stream, line)) {
        std::stringstream ss(line);
        std::string val_str;
        while (ss >> val_str) {
            try {
                double val = std::stod(val_str);
                eigenvalues.push_back(val);
            } catch (const std::exception&) {
                CERR << "Error: Invalid eigenvalue: " << val_str << std::endl;
                return 1;
            }
        }
    }
    eigenvals_stream.close();
    
    if (eigenvalues.size() != n_subjects) {
        CERR << "Error: Mismatch between number of IDs (" << n_subjects 
                  << ") and eigenvalues (" << eigenvalues.size() << ")" << std::endl;
        return 1;
    }
    
    // Read eigenvectors matrix
    std::ifstream eigenvecs_stream(eigenvecs_file);
    if (!eigenvecs_stream) {
        CERR << "Error: Cannot read eigenvectors file: " << eigenvecs_file << std::endl;
        return 1;
    }
    
    std::vector<std::vector<double>> eigenvectors(n_subjects, std::vector<double>(n_subjects));
    if (std::getline(eigenvecs_stream, line)) {
        std::stringstream ss(line);
        std::string val_str;
        size_t idx = 0;
        
        // Read eigenvectors in column-major order (as written by create_evd)
        for (size_t col = 0; col < n_subjects && idx < n_subjects * n_subjects; col++) {
            for (size_t row = 0; row < n_subjects && ss >> val_str; row++, idx++) {
                try {
                    eigenvectors[row][col] = std::stod(val_str);
                } catch (const std::exception&) {
                    CERR << "Error: Invalid eigenvector value: " << val_str << std::endl;
                    return 1;
                }
            }
        }
    }
    eigenvecs_stream.close();

    // Get phenotype data for the current trait
    const auto& data = phenotypes->get_data();
    const auto& headers = phenotypes->get_headers();

    // Find trait column
    int trait_col = -1;
    int id_col = -1;

    for (size_t i = 0; i < headers.size(); i++) {
        if (headers[i] == "id" || headers[i] == "ID") {
            id_col = i;
        }
        if (headers[i] == trait_name) {
            trait_col = i;
        }
    }

    if (id_col == -1 || trait_col == -1) {
        CERR << "Error: Cannot find required columns in phenotype data" << std::endl;
        return 1;
    }
    
    // Extract phenotype values matching our IDs in the same order
    std::vector<double> raw_phenotype_values(n_subjects);
    bool found_all = true;
    
    for (size_t i = 0; i < n_subjects; i++) {
        bool found = false;
        for (const auto& row : data) {
            if (row.size() > std::max(id_col, trait_col) && row[id_col] == ids[i]) {
                const std::string& trait_val = row[trait_col];
                if (!trait_val.empty() && trait_val != "NA" && trait_val != ".") {
                    try {
                        raw_phenotype_values[i] = std::stod(trait_val);
                        found = true;
                        break;
                    } catch (const std::exception&) {
                        // Invalid value
                    }
                }
            }
        }
        if (!found) {
            CERR << "Error: Cannot find phenotype value for ID: " << ids[i] << std::endl;
            found_all = false;
        }
    }
    
    if (!found_all) {
        return 1;
    }
    
    // Create matrices exactly like SOLAR (lines 1091-1093)
    // Y = eigenvectors_transpose * trait_v (NO mean subtraction like SOLAR line 1092)
    std::vector<double> Y(n_subjects, 0.0);
    for (size_t i = 0; i < n_subjects; i++) {
        for (size_t j = 0; j < n_subjects; j++) {
            Y[i] += eigenvectors[j][i] * raw_phenotype_values[j];  // eigenvectors^T * trait_v
        }
    }
    
    // X = eigenvectors_transpose * cov_matrix (X is all ones for intercept only)
    std::vector<double> X(n_subjects, 0.0);
    for (size_t i = 0; i < n_subjects; i++) {
        for (size_t j = 0; j < n_subjects; j++) {
            X[i] += eigenvectors[j][i] * 1.0;  // eigenvectors^T * ones
        }
    }
    
    // aux matrix: [ones, eigenvalues] (lines 453-454)
    std::vector<std::vector<double>> aux(n_subjects, std::vector<double>(2));
    for (size_t i = 0; i < n_subjects; i++) {
        aux[i][0] = 1.0;
        aux[i][1] = eigenvalues[i];
    }
    
    // Call find_max_loglik_2 exactly like SOLAR (line 1096)
    double result_loglik, result_variance, result_se;
    double result_mean, result_mean_se, result_e2, result_e2_se, result_sd, result_sd_se;
    double h2r = find_max_loglik_2(11, Y, aux, X, result_loglik, result_variance, result_se,
                                  result_mean, result_mean_se, result_e2, result_e2_se,
                                  result_sd, result_sd_se);
    double loglik = result_loglik;
    
    // Calculate null model for p-value (lines 1104-1107)
    double residual_sum_sq = 0.0;
    for (double y : Y) {
        residual_sum_sq += y * y;
    }
    double null_variance = residual_sum_sq / n_subjects;
    std::vector<double> ones(n_subjects, 1.0);
    double sporadic_loglik = calculate_fphi_loglik(null_variance, ones, n_subjects);
    
    // Calculate p-value using likelihood ratio test
    double pvalue;
    if (sporadic_loglik < loglik) {
        double chi_stat = 2.0 * (loglik - sporadic_loglik);
        pvalue = chicdf(chi_stat, 1.0);
    } else {
        pvalue = 0.5;  // Non-significant result
    }
    
    // Create output file
    std::string output_file = std::string(evd_data_basename) + "_fphi_results.out";
    std::ofstream results_stream(output_file);
    if (results_stream) {
        results_stream.precision(11);  // decimal places for file output
        results_stream << std::fixed;  // Force fixed-point notation
        results_stream << "Trait,h2r,SE,loglik,sporadic_loglik,p_value,n_subjects" << std::endl;
        results_stream << trait_name << "," << h2r << "," << result_se << "," 
                      << loglik << "," << sporadic_loglik << ",";
        if (pvalue < 1e-6) {
            results_stream << std::scientific << std::setprecision(11) << pvalue;
        } else {
            results_stream << std::fixed << std::setprecision(6) << pvalue;
        }
        results_stream << "," << n_subjects << std::endl;
        results_stream.close();
    }

    // Create detailed parameters CSV file
    std::string params_file = std::string(evd_data_basename) + "_parameters.out";
    std::ofstream params_stream(params_file);
    if (params_stream) {
        params_stream.precision(11);
        params_stream << std::fixed;
        params_stream << "Parameter,Value,SE" << std::endl;
        params_stream << "mean," << result_mean << "," << result_mean_se << std::endl;
        params_stream << "e2," << result_e2 << "," << result_e2_se << std::endl;
        params_stream << "h2r," << h2r << "," << result_se << std::endl;
        params_stream << "sd," << result_sd << "," << result_sd_se << std::endl;
        params_stream.close();
    }

    return 0;
}
