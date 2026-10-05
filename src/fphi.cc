#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <iomanip>
#include <cmath>
#include <algorithm>
#include <cerrno>
#include <cstdlib>
#include <unordered_map>

#include <Rcpp.h>
#define COUT Rcpp::Rcout
#include "solar_log.h"

#include "Eigen/Dense"
#include "fphi.h"
#include "pedigree.h"
#include "phenotypes.h"

// FORTRAN cdfchi routine (exact match to original SOLAR)
extern "C" void cdfchi_(int* which, double* p, double* q, double* chi, double* df, int* status, double* bound);

// Parse a number written by create_evd. Like std::stod, but a value that
// underflows (e.g. a subnormal like -6.0276e-322) is accepted as parsed
// instead of throwing out_of_range. Overflow and non-numbers still fail.
static bool parse_evd_value(const std::string& s, double& value) {
    const char* begin = s.c_str();
    char* end = nullptr;
    errno = 0;
    value = std::strtod(begin, &end);
    if (end == begin) return false;
    if (errno == ERANGE && std::fabs(value) > 1.0) return false;
    return true;
}

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

static inline double calculate_ddloglik_with_constraint(const double t, const double dloglik, const double ddloglik) {
    return std::pow(calculate_dconstraint(t), 2) * ddloglik + calculate_ddconstraint(t) * dloglik;
}

static inline double calculate_dloglik_with_constraint(const double t, const double dloglik) {
    return calculate_dconstraint(t) * dloglik;
}

// Log-likelihood calculation (exact match to original SOLAR)
static double calculate_fphi_loglik(double variance, const Eigen::VectorXd& sigma, size_t n_subjects) {
    return -0.5 * (std::log(std::abs(variance)) * n_subjects + sigma.array().abs().log().sum() + n_subjects);
}

static double calculate_dloglik(const Eigen::VectorXd& lambda_minus_one,
                                const Eigen::VectorXd& residual_squared,
                                const Eigen::VectorXd& sigma, double variance) {
    double part_one = variance * lambda_minus_one.dot(sigma);
    double part_two = variance * lambda_minus_one.dot(residual_squared.cwiseProduct(sigma.cwiseAbs2()));
    return -0.5 * (part_one - part_two);
}

static double calculate_ddloglik(const Eigen::VectorXd& lambda_minus_one,
                                 const Eigen::VectorXd& residual_squared,
                                 const Eigen::VectorXd& sigma, double variance) {
    Eigen::VectorXd lambda_minus_one_squared = lambda_minus_one.cwiseAbs2();
    Eigen::VectorXd sigma_squared = sigma.cwiseAbs2();
    double part_one = variance * variance * lambda_minus_one_squared.dot(sigma_squared);
    double part_two = 2.0 * variance * variance *
        lambda_minus_one_squared.dot(residual_squared.cwiseProduct(sigma.cwiseProduct(sigma_squared)));
    return -0.5 * (-part_one + part_two);
}

// Observed Hessian of [beta..., e2, SD] (SOLAR compute_observed_Hessian)
static Eigen::MatrixXd compute_observed_hessian(double SD, const Eigen::VectorXd& residual,
                                                const Eigen::VectorXd& one_minus_lambda,
                                                const Eigen::MatrixXd& SX,
                                                const Eigen::VectorXd& sigma_inverse) {
    const Eigen::Index p = SX.cols();
    Eigen::MatrixXd SX_transpose = SX.transpose();
    Eigen::MatrixXd beta_hessian = SX_transpose * sigma_inverse.asDiagonal() * SX;
    Eigen::VectorXd one_minus_lambda_squared = one_minus_lambda.cwiseAbs2();
    Eigen::VectorXd beta_var_comp_hessian = std::pow(SD, 2.0) * SX_transpose *
        sigma_inverse.cwiseAbs2().cwiseProduct(one_minus_lambda.cwiseProduct(residual));
    Eigen::VectorXd beta_SD_hessian = 2.0 * SX_transpose * residual.cwiseProduct(sigma_inverse) / SD;

    Eigen::MatrixXd hessian(p + 2, p + 2);
    hessian.topLeftCorner(p, p) = beta_hessian;
    hessian.block(0, p, p, 1) = beta_var_comp_hessian;
    hessian.block(p, 0, 1, p) = beta_var_comp_hessian.transpose();
    hessian.block(0, p + 1, p, 1) = beta_SD_hessian;
    hessian.block(p + 1, 0, 1, p) = beta_SD_hessian.transpose();

    Eigen::VectorXd residual_squared = residual.cwiseAbs2();
    double SD_hessian = -std::pow(SD, -2.0) * (residual.rows() - 3.0 * residual_squared.dot(sigma_inverse));
    double SD_e2_hessian = SD * one_minus_lambda.dot(residual.cwiseProduct(sigma_inverse).cwiseAbs2());
    double e2_hessian = -std::pow(SD, 4.0) *
        (0.5 * one_minus_lambda_squared.dot(sigma_inverse.cwiseAbs2()) -
         one_minus_lambda_squared.dot(sigma_inverse.cwiseProduct(sigma_inverse.cwiseProduct(residual).cwiseAbs2())));
    hessian(p, p) = e2_hessian;
    hessian(p + 1, p) = hessian(p, p + 1) = SD_e2_hessian;
    hessian(p + 1, p + 1) = SD_hessian;
    return hessian;
}

// Result of find_max_loglik_2
struct FphiFit {
    double h2r = 0.0, loglik = 0.0, variance = 0.0;
    Eigen::VectorXd beta, beta_se;  // one per column of X
    double e2_se = 0.0, sd_se = 0.0;
};

// SOLAR find_max_loglik_2: Newton search for h2r on the eigen-rotated trait
// Y and covariates X (one column per covariate, then the mean). Returns false
// on convergence failure (X^T Omega X singular).
static bool find_max_loglik_2(const int precision, const Eigen::VectorXd& Y,
                              const Eigen::MatrixXd& aux, const Eigen::MatrixXd& X, FphiFit& fit) {
    const size_t n_subjects = Y.rows();
    double parameter_t = 1.0;
    double h2r = 0.5;
    Eigen::VectorXd theta(2);
    theta << 0.5, 0.5;
    Eigen::VectorXd Sigma = aux * theta;
    Eigen::VectorXd sigma_inverse_var = Sigma.cwiseInverse();
    Eigen::MatrixXd X_transpose = X.transpose();
    Eigen::MatrixXd XTOX = X_transpose * sigma_inverse_var.asDiagonal() * X;
    if (XTOX.determinant() == 0) return false;

    Eigen::VectorXd beta = XTOX.inverse() * X_transpose * sigma_inverse_var.asDiagonal() * Y;
    Eigen::VectorXd residual = Y - X * beta;
    Eigen::VectorXd residual_squared = residual.cwiseAbs2();
    double variance = residual_squared.dot(sigma_inverse_var) / n_subjects;
    double loglik = calculate_fphi_loglik(variance, Sigma, n_subjects);
    Eigen::VectorXd lambda_minus_one = (aux.col(1).array() - 1.0).matrix();
    sigma_inverse_var = (Sigma * variance).cwiseInverse();
    double dloglik = calculate_dloglik(lambda_minus_one, residual_squared, sigma_inverse_var, variance);
    double ddloglik = calculate_ddloglik(lambda_minus_one, residual_squared, sigma_inverse_var, variance);
    double score = calculate_dloglik_with_constraint(parameter_t, dloglik);
    double hessian = calculate_ddloglik_with_constraint(parameter_t, dloglik, ddloglik);
    double delta = -score / hessian;
    double new_h2r = 0.0;
    if (delta == delta) {
        parameter_t += delta;
        new_h2r = calculate_constraint(parameter_t);
    }

    const double end = std::pow(10, -precision);
    int iter = 0;
    while (delta == delta && std::fabs(new_h2r - h2r) >= end && ++iter < 100) {
        h2r = new_h2r;
        theta << 1.0 - h2r, h2r;
        Sigma = aux * theta;
        sigma_inverse_var = Sigma.cwiseInverse();
        XTOX = X_transpose * sigma_inverse_var.asDiagonal() * X;
        if (XTOX.determinant() == 0) return false;
        beta = XTOX.inverse() * X_transpose * sigma_inverse_var.asDiagonal() * Y;
        residual = Y - X * beta;
        residual_squared = residual.cwiseAbs2();
        variance = residual_squared.dot(sigma_inverse_var) / n_subjects;
        sigma_inverse_var /= variance;
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

    // Test the boundary (h2r = 0 or 1) when the search ends near it
    if ((h2r >= 0.9 || h2r <= 0.1) && h2r == h2r) {
        double test_h2r = (h2r >= 0.9) ? 1.0 : 0.0;
        Eigen::VectorXd test_theta(2);
        test_theta << 1.0 - test_h2r, test_h2r;
        Eigen::VectorXd test_sigma = aux * test_theta;
        Eigen::VectorXd test_sigma_inverse = test_sigma.cwiseInverse();
        Eigen::MatrixXd test_XTOX = X_transpose * test_sigma_inverse.asDiagonal() * X;
        if (test_XTOX.determinant() != 0) {
            Eigen::VectorXd test_beta = test_XTOX.inverse() * X_transpose * test_sigma_inverse.asDiagonal() * Y;
            Eigen::VectorXd test_residual = Y - X * test_beta;
            double test_variance = test_residual.cwiseAbs2().dot(test_sigma_inverse) / n_subjects;
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

    // Standard errors from the observed Hessian
    residual = Y - X * beta;
    Sigma = variance * aux * theta;
    Eigen::VectorXd omega_diagonal = Sigma.cwiseInverse();
    Eigen::VectorXd one_minus_lambda = (1.0 - aux.col(1).array()).matrix();
    Eigen::MatrixXd H = compute_observed_hessian(std::sqrt(variance), residual, one_minus_lambda, X, omega_diagonal);

    const Eigen::Index p = X.cols();
    fit.h2r = h2r;
    fit.loglik = loglik;
    fit.variance = variance;
    fit.beta = beta;
    if (H.determinant() != 0) {
        // abs(): a negative variance gives an SE rather than SOLAR's nan
        Eigen::VectorXd errors = H.inverse().diagonal().cwiseAbs().cwiseSqrt();
        fit.beta_se = errors.head(p);
        fit.e2_se = errors(p);
        fit.sd_se = errors(p + 1);
    } else {
        // SOLAR reports nan; the port reports 0
        fit.beta_se = Eigen::VectorXd::Zero(p);
        fit.e2_se = 0.0;
        fit.sd_se = 0.0;
    }
    return true;
}

int Fphi::run_fphi(
    Pedigree* pedigree,
    Phenotypes* phenotypes,
    const std::string& trait_name,
    const std::vector<Covariate>& covariates,
    const char* evd_data_basename,
    FphiResult& result
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
            double val;
            if (!parse_evd_value(val_str, val)) {
                CERR << "Error: Invalid eigenvalue: " << val_str << std::endl;
                return 1;
            }
            eigenvalues.push_back(val);
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
    
    Eigen::MatrixXd eigenvectors(n_subjects, n_subjects);
    if (std::getline(eigenvecs_stream, line)) {
        std::stringstream ss(line);
        std::string val_str;
        size_t idx = 0;
        
        // Read eigenvectors in column-major order (as written by create_evd)
        for (size_t col = 0; col < n_subjects && idx < n_subjects * n_subjects; col++) {
            for (size_t row = 0; row < n_subjects && ss >> val_str; row++, idx++) {
                if (!parse_evd_value(val_str, eigenvectors(row, col))) {
                    CERR << "Error: Invalid eigenvector value: " << val_str << std::endl;
                    return 1;
                }
            }
        }
    }
    eigenvecs_stream.close();

    // Trait and covariate variable values for the EVD individuals, in order
    int id_col = phenotypes->find_column("id");
    int trait_col = phenotypes->has_trait(trait_name) ? phenotypes->find_column(trait_name) : -1;
    if (id_col == -1 || trait_col == -1) {
        CERR << "Error: Cannot find required columns in phenotype data" << std::endl;
        return 1;
    }
    std::vector<std::string> variables = covariate_variables(covariates);
    std::vector<int> var_cols;
    for (const auto& var : variables) {
        int col = phenotypes->find_column(var);
        if (col == -1) {
            CERR << "Error: Covariate variable '" << var << "' not found in phenotype data" << std::endl;
            return 1;
        }
        var_cols.push_back(col);
    }

    std::unordered_map<std::string, const std::vector<std::string>*> rows;
    for (const auto& row : phenotypes->get_data()) {
        if (row.size() > static_cast<size_t>(id_col)) rows.emplace(row[id_col], &row);
    }
    Eigen::VectorXd trait_v(n_subjects);
    Eigen::MatrixXd var_values(n_subjects, variables.size());
    for (size_t i = 0; i < n_subjects; i++) {
        auto it = rows.find(ids[i]);
        bool ok = it != rows.end();
        const std::vector<std::string>* row = ok ? it->second : nullptr;
        auto value = [&](int col, double& v) {
            return row->size() > static_cast<size_t>(col) && Phenotypes::parse_value((*row)[col], v);
        };
        ok = ok && value(trait_col, trait_v(i));
        for (size_t j = 0; ok && j < var_cols.size(); j++) ok = value(var_cols[j], var_values(i, j));
        if (!ok) {
            CERR << "Error: Cannot find phenotype values for ID: " << ids[i] << std::endl;
            return 1;
        }
    }

    // Rotate into the eigenbasis like SOLAR (lines 1091-1093): the trait is
    // not mean-centred; the covariate matrix carries the mean as its last column
    Eigen::MatrixXd cov_matrix = covariate_matrix(covariates, var_values);
    Eigen::MatrixXd eigenvectors_transpose = eigenvectors.transpose();
    Eigen::VectorXd Y = eigenvectors_transpose * trait_v;
    Eigen::MatrixXd X = eigenvectors_transpose * cov_matrix;
    Eigen::MatrixXd aux = Eigen::MatrixXd::Ones(n_subjects, 2);
    aux.col(1) = Eigen::Map<const Eigen::VectorXd>(eigenvalues.data(), n_subjects);

    FphiFit fit;
    if (!find_max_loglik_2(11, Y, aux, X, fit)) {
        CERR << "Error: Convergence failure (the covariates may be collinear)" << std::endl;
        return 1;
    }

    // Null (sporadic) model and likelihood ratio test (SOLAR lines 1102-1108
    // and calculate_pvalue). SOLAR only tests when h2r != 0; otherwise the
    // sporadic loglik is the polygenic one and p = 0.5.
    double pvalue = 0.5;
    double sporadic_loglik = fit.loglik;
    if (fit.h2r != 0.0) {
        // OLS residual of the (untransformed) trait on the covariates
        Eigen::VectorXd residual = trait_v - cov_matrix * cov_matrix.colPivHouseholderQr().solve(trait_v);
        double null_variance = residual.squaredNorm() / n_subjects;
        sporadic_loglik = calculate_fphi_loglik(null_variance, Eigen::VectorXd::Ones(n_subjects), n_subjects);

        // SOLAR passes the statistic to cdfchi unchecked; a negative one
        // (sporadic fits better) is outside cdfchi's domain, so treat it as 0
        double chi_stat = std::max(0.0, 2.0 * (fit.loglik - sporadic_loglik));
        pvalue = chicdf(chi_stat, 1.0);
    }

    const size_t p = covariates.size();
    result.trait = trait_name;
    result.pedigree_file = pedigree->filename();
    result.phenotype_file = phenotypes->get_filename();
    result.n_subjects = n_subjects;
    result.h2r = fit.h2r;
    result.h2r_se = fit.e2_se;  // h2r and e2 share an SE in SOLAR
    result.loglik = fit.loglik;
    result.sporadic_loglik = sporadic_loglik;
    result.p_value = pvalue;
    result.covariates.clear();
    for (size_t i = 0; i < p; i++) {
        result.covariates.push_back({covariates[i].fullname(), fit.beta(i), fit.beta_se(i)});
    }
    result.mean = fit.beta(p);
    result.mean_se = fit.beta_se(p);
    result.e2 = 1.0 - fit.h2r;
    result.e2_se = fit.e2_se;
    result.sd = std::sqrt(fit.variance);
    result.sd_se = fit.sd_se;

    return 0;
}
