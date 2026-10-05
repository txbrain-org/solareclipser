#include <algorithm>
#include <cctype>
#include <cmath>

#include "covariates.h"

namespace {

bool iequals(const std::string& a, const std::string& b) {
    return a.size() == b.size() &&
           std::equal(a.begin(), a.end(), b.begin(), [](unsigned char x, unsigned char y) {
               return std::tolower(x) == std::tolower(y);
           });
}

// One variable of a spec: name, exponent ("^n") or degree ("^1,2[,3[,4]]")
struct Part {
    std::string name;
    int exponent = 1;
    int degree = 1;
};

bool parse_part(const std::string& s, bool allow_degree, Part& part, std::string& error) {
    size_t caret = s.find('^');
    size_t comma = s.find(',');
    if (comma != std::string::npos && caret == std::string::npos) {
        error = "Invalid exponent expression or use of comma";
        return false;
    }
    part.name = s.substr(0, caret);
    if (part.name.empty()) {
        error = "Missing covariate variable name";
        return false;
    }
    if (caret == std::string::npos) return true;

    std::string exp = s.substr(caret + 1);
    if (comma != std::string::npos) {
        if (!allow_degree) {
            error = "Covariate comma shortcut only allowed for first variable";
            return false;
        }
        if (exp == "1,2") part.degree = 2;
        else if (exp == "1,2,3") part.degree = 3;
        else if (exp == "1,2,3,4") part.degree = 4;
        else {
            error = "Invalid exponent expression or use of comma";
            return false;
        }
        return true;
    }
    if (exp.empty() || !std::all_of(exp.begin(), exp.end(), ::isdigit) ||
        (part.exponent = std::stoi(exp)) < 1) {
        error = "Invalid exponent expression";
        return false;
    }
    return true;
}

Covariate make(std::initializer_list<CovariateTerm> terms) {
    Covariate c;
    c.terms = terms;
    return c;
}

}  // namespace

std::string Covariate::fullname() const {
    std::string name;
    for (size_t i = 0; i < terms.size(); i++) {
        if (i > 0) name += "*";
        name += terms[i].name;
        if (terms[i].exponent != 1) name += "^" + std::to_string(terms[i].exponent);
    }
    return name;
}

bool parse_covariate(const std::string& spec, std::vector<Covariate>& covariates,
                     std::string& error) {
    if (spec.empty()) {
        error = "Missing covariate variable name";
        return false;
    }
    if (spec.find_first_of("()") != std::string::npos) {
        error = "Trait-specific covariates and null covariates are not supported: " + spec;
        return false;
    }
    if (std::any_of(spec.begin(), spec.end(), ::isspace)) {
        error = "Spaces are not allowed within a covariate: " + spec;
        return false;
    }
    bool star = spec.find('*') != std::string::npos;
    bool pound = spec.find('#') != std::string::npos;
    if (star && pound) {
        error = "Pound and Star are not allowed in same covariate term";
        return false;
    }

    std::vector<Part> parts;
    char sep = pound ? '#' : '*';
    size_t start = 0;
    for (;;) {
        size_t end = spec.find(sep, start);
        Part part;
        if (!parse_part(spec.substr(start, end - start), parts.empty(), part, error)) {
            return false;
        }
        parts.push_back(part);
        if (end == std::string::npos) break;
        start = end + 1;
    }

    const Part& p1 = parts[0];
    if ((pound || p1.degree > 1) && parts.size() > 2) {
        error = "Covariate shortcuts only allowed with 2 variables";
        return false;
    }

    // Expand in the order SOLAR's covariate command does
    std::vector<Covariate> expanded;
    CovariateTerm t1{p1.name, p1.exponent};
    if (parts.size() == 1) {
        expanded.push_back(make({t1}));
        for (int i = 2; i <= p1.degree; i++) expanded.push_back(make({{p1.name, i}}));
    } else if (pound) {  // var1[^1,2,...]#var2[^n]
        CovariateTerm t2{parts[1].name, parts[1].exponent};
        expanded.push_back(make({t1}));
        expanded.push_back(make({t2}));
        expanded.push_back(make({t1, t2}));
        for (int i = 2; i <= p1.degree; i++) {
            expanded.push_back(make({{p1.name, i}}));
            expanded.push_back(make({{p1.name, i}, t2}));
        }
    } else if (p1.degree > 1) {  // var1^1,2,...*var2[^n]
        CovariateTerm t2{parts[1].name, parts[1].exponent};
        expanded.push_back(make({t1, t2}));
        for (int i = 2; i <= p1.degree; i++) expanded.push_back(make({{p1.name, i}, t2}));
    } else {  // var1*var2*...
        Covariate c;
        for (const Part& p : parts) c.terms.push_back({p.name, p.exponent});
        expanded.push_back(c);
    }

    for (const Covariate& c : expanded) {
        bool seen = std::any_of(covariates.begin(), covariates.end(), [&](const Covariate& o) {
            return iequals(o.fullname(), c.fullname());
        });
        if (!seen) covariates.push_back(c);
    }
    return true;
}

std::vector<std::string> covariate_variables(const std::vector<Covariate>& covariates) {
    std::vector<std::string> vars;
    for (const Covariate& c : covariates) {
        for (const CovariateTerm& t : c.terms) {
            bool seen = std::any_of(vars.begin(), vars.end(),
                                    [&](const std::string& v) { return iequals(v, t.name); });
            if (!seen) vars.push_back(t.name);
        }
    }
    return vars;
}

Eigen::MatrixXd covariate_matrix(const std::vector<Covariate>& covariates,
                                 const Eigen::MatrixXd& values) {
    std::vector<std::string> vars = covariate_variables(covariates);
    const Eigen::Index n = values.rows();

    Eigen::MatrixXd adjusted(n, values.cols());
    for (Eigen::Index col = 0; col < values.cols(); col++) {
        if (iequals(vars[col], "sex")) {
            bool any_two = false;
            for (Eigen::Index row = 0; row < n; row++) any_two = any_two || values(row, col) == 2.0;
            for (Eigen::Index row = 0; row < n; row++) {
                adjusted(row, col) = !any_two ? values(row, col) : (values(row, col) == 2.0 ? 1.0 : 0.0);
            }
        } else {
            adjusted.col(col) = values.col(col).array() - values.col(col).mean();
        }
    }

    Eigen::MatrixXd matrix = Eigen::MatrixXd::Ones(n, covariates.size() + 1);
    for (size_t col = 0; col < covariates.size(); col++) {
        for (const CovariateTerm& t : covariates[col].terms) {
            Eigen::Index index = std::find_if(vars.begin(), vars.end(), [&](const std::string& v) {
                                     return iequals(v, t.name);
                                 }) - vars.begin();
            if (t.exponent == 1) {
                matrix.col(col).array() *= adjusted.col(index).array();
            } else {
                matrix.col(col).array() *= adjusted.col(index).array().pow(t.exponent);
            }
        }
    }
    return matrix;
}
