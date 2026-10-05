/*
 * covariates.h - FPHI covariates, as set by SOLAR's `covariate` command
 *
 * A covariate is a product of terms, each a phenotype variable raised to a
 * power: "age", "age^2", "age*sex". The shorthands "age^1,2" (age age^2)
 * and "age#sex" (age sex age*sex) expand as in SOLAR (covariate.cc).
 * Trait-specific "(trait)" qualifiers and null covariates "var()" are not
 * supported.
 */

#ifndef COVARIATES_H
#define COVARIATES_H

#include <string>
#include <vector>

#include "Eigen/Dense"

struct CovariateTerm {
    std::string name;
    int exponent = 1;
};

struct Covariate {
    std::vector<CovariateTerm> terms;
    // As SOLAR prints it, e.g. "age^2*sex"
    std::string fullname() const;
};

// Parse one covariate spec and append the covariates it expands to, skipping
// any already in `covariates`. Returns false and sets `error` if invalid.
bool parse_covariate(const std::string& spec, std::vector<Covariate>& covariates,
                     std::string& error);

// The distinct variables used by `covariates` (case-insensitive), in order of
// first use
std::vector<std::string> covariate_variables(const std::vector<Covariate>& covariates);

// Design matrix as SOLAR fphi builds it (load_fphi_matrices): one column per
// covariate, then a column of ones for the mean. `values` has one row per
// individual and one column per covariate_variables() entry. Each variable is
// centred on its mean, except sex, which is recoded 2 -> 1 and anything else
// -> 0 when any value is 2 (otherwise used as is); a covariate is the product
// of its terms' adjusted variables raised to their exponents.
Eigen::MatrixXd covariate_matrix(const std::vector<Covariate>& covariates,
                                 const Eigen::MatrixXd& values);

#endif // COVARIATES_H
