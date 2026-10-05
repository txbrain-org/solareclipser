#include <algorithm>
#include <cctype>
#include <charconv>
#include <cmath>
#include <cstdio>
#include <fstream>
#include <iomanip>
#include <limits>
#include <sstream>

#include <Rcpp.h>
#define CERR Rcpp::Rcerr

#include "fphi_output.h"

namespace {

struct Parameter {
    const char* name;
    double value;
    double se;
};

std::vector<Parameter> parameters(const FphiResult& r) {
    return {
        {"mean", r.mean, r.mean_se},
        {"e2", r.e2, r.e2_se},
        {"h2r", r.h2r, r.h2r_se},
        {"sd", r.sd, r.sd_se},
    };
}

bool significant(const FphiResult& r) { return r.p_value < 0.05; }

// Shortest representation that parses back to the same double
std::string format_finite(double x) {
#if defined(__cpp_lib_to_chars) && __cpp_lib_to_chars >= 201611L
    char buf[64];
    auto res = std::to_chars(buf, buf + sizeof(buf), x);
    return std::string(buf, res.ptr);
#else
    std::ostringstream ss;
    ss << std::setprecision(std::numeric_limits<double>::max_digits10) << x;
    return ss.str();
#endif
}

// nan/inf spelled the way R's read.csv / read.delim understand them
std::string format_r(double x) {
    if (std::isnan(x)) return "NaN";
    if (std::isinf(x)) return x > 0 ? "Inf" : "-Inf";
    return format_finite(x);
}

std::string format_json(double x) {
    return std::isfinite(x) ? format_finite(x) : "null";
}

std::string format_yaml(double x) {
    if (std::isnan(x)) return ".nan";
    if (std::isinf(x)) return x > 0 ? ".inf" : "-.inf";
    return format_finite(x);
}

// Double-quoted JSON string; also a valid YAML double-quoted scalar
std::string quote_json(const std::string& s) {
    std::string out = "\"";
    for (unsigned char c : s) {
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default:
                if (c < 0x20) {
                    char buf[8];
                    std::snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out += buf;
                } else {
                    out += static_cast<char>(c);
                }
        }
    }
    return out + "\"";
}

std::string quote_delimited(const std::string& s, char sep) {
    if (s.find_first_of(std::string(1, sep) + "\"\n\r") == std::string::npos) return s;
    std::string out = "\"";
    for (char c : s) {
        if (c == '"') out += '"';
        out += c;
    }
    return out + "\"";
}

void write_results_table(std::ostream& out, const FphiResult& r, char sep) {
    out << "Trait" << sep << "h2r" << sep << "SE" << sep << "loglik" << sep
        << "sporadic_loglik" << sep << "p_value" << sep << "n_subjects" << "\n";
    out << quote_delimited(r.trait, sep) << sep << format_r(r.h2r) << sep
        << format_r(r.h2r_se) << sep << format_r(r.loglik) << sep
        << format_r(r.sporadic_loglik) << sep << format_r(r.p_value) << sep
        << r.n_subjects << "\n";
}

void write_parameters_table(std::ostream& out, const FphiResult& r, char sep) {
    out << "Parameter" << sep << "Value" << sep << "SE" << "\n";
    for (const auto& p : parameters(r)) {
        out << p.name << sep << format_r(p.value) << sep << format_r(p.se) << "\n";
    }
}

void write_delimited(std::ostream& out, const FphiResult& r, char sep) {
    write_results_table(out, r, sep);
    out << "\n";
    write_parameters_table(out, r, sep);
}

void write_json(std::ostream& out, const FphiResult& r) {
    out << "{\n"
        << "  \"trait\": " << quote_json(r.trait) << ",\n"
        << "  \"pedigree\": " << quote_json(r.pedigree_file) << ",\n"
        << "  \"phenotypes\": " << quote_json(r.phenotype_file) << ",\n"
        << "  \"n_subjects\": " << r.n_subjects << ",\n"
        << "  \"h2r\": " << format_json(r.h2r) << ",\n"
        << "  \"h2r_se\": " << format_json(r.h2r_se) << ",\n"
        << "  \"loglik\": " << format_json(r.loglik) << ",\n"
        << "  \"sporadic_loglik\": " << format_json(r.sporadic_loglik) << ",\n"
        << "  \"p_value\": " << format_json(r.p_value) << ",\n"
        << "  \"significant\": " << (significant(r) ? "true" : "false") << ",\n"
        << "  \"parameters\": [\n";
    auto params = parameters(r);
    for (size_t i = 0; i < params.size(); i++) {
        out << "    {\"name\": " << quote_json(params[i].name)
            << ", \"value\": " << format_json(params[i].value)
            << ", \"se\": " << format_json(params[i].se) << "}"
            << (i + 1 < params.size() ? "," : "") << "\n";
    }
    out << "  ]\n}\n";
}

void write_yaml(std::ostream& out, const FphiResult& r) {
    out << "trait: " << quote_json(r.trait) << "\n"
        << "pedigree: " << quote_json(r.pedigree_file) << "\n"
        << "phenotypes: " << quote_json(r.phenotype_file) << "\n"
        << "n_subjects: " << r.n_subjects << "\n"
        << "h2r: " << format_yaml(r.h2r) << "\n"
        << "h2r_se: " << format_yaml(r.h2r_se) << "\n"
        << "loglik: " << format_yaml(r.loglik) << "\n"
        << "sporadic_loglik: " << format_yaml(r.sporadic_loglik) << "\n"
        << "p_value: " << format_yaml(r.p_value) << "\n"
        << "significant: " << (significant(r) ? "true" : "false") << "\n"
        << "parameters:\n";
    for (const auto& p : parameters(r)) {
        out << "  - name: " << quote_json(p.name) << "\n"
            << "    value: " << format_yaml(p.value) << "\n"
            << "    se: " << format_yaml(p.se) << "\n";
    }
}

// Port of format_fphi_output() and the parameter table in runfphiCmd(),
// zz_solar_meson/src/solarmain/src/fphi.cc. Keep the layout byte-identical.
void write_solar(std::ostream& out, const FphiResult& r) {
    std::ostringstream ss;  // own stream, so the caller's formatting state is untouched
    ss.precision(12);

    ss << "***********************************************************************************\n";
    ss << "*        Fast Permutation Heritability Inference (FPHI) Summary of Results        *\n";
    ss << "***********************************************************************************\n";
    ss << "  Pedigree:    " << r.pedigree_file << "\n";
    ss << "  Phenotypes:  " << r.phenotype_file << "\n";
    std::string pvalue_message = r.p_value >= 0.05 ? "(Insignificant)" : "(Significant)";
    ss << "  Trait:   " << r.trait << " H2r = " << r.h2r << " SE = " << r.h2r_se
       << "  Individuals:  " << r.n_subjects << "\n";
    ss << "  polygenic loglik:   " << r.loglik << "  sporadic loglik:   " << r.sporadic_loglik
       << "  p = " << r.p_value << " " << pvalue_message << "\n";

    ss << "Fully Converged Parameters\n\n";
    ss << std::setw(10) << "Name" << std::setw(20) << "Value" << std::setw(20) << "Std Error" << "\n";
    ss << "\n\n";
    ss << std::setw(10) << "Parameter" << std::setw(20) << "Fit Value" << std::setw(20) << "Standard Error" << "\n";
    for (const auto& p : parameters(r)) {
        ss << std::setw(10) << p.name << std::setw(20) << p.value << std::setw(20) << p.se << "\n";
    }
    ss << "\n";

    out << ss.str();
}

bool write_file(const std::string& path, const std::string& content) {
    std::ofstream f(path);
    if (!f) {
        CERR << "Error: Cannot create output file " << path << std::endl;
        return false;
    }
    f << content;
    return static_cast<bool>(f);
}

}  // namespace

bool parse_output_format(const std::string& name, OutputFormat& format) {
    std::string n = name;
    std::transform(n.begin(), n.end(), n.begin(),
                   [](unsigned char c) { return std::tolower(c); });
    if (n == "csv")   { format = OutputFormat::Csv;   return true; }
    if (n == "tsv")   { format = OutputFormat::Tsv;   return true; }
    if (n == "json")  { format = OutputFormat::Json;  return true; }
    if (n == "yaml")  { format = OutputFormat::Yaml;  return true; }
    if (n == "solar") { format = OutputFormat::Solar; return true; }
    return false;
}

void write_fphi_result(std::ostream& out, const FphiResult& result, OutputFormat format) {
    switch (format) {
        case OutputFormat::Csv:   write_delimited(out, result, ','); break;
        case OutputFormat::Tsv:   write_delimited(out, result, '\t'); break;
        case OutputFormat::Json:  write_json(out, result); break;
        case OutputFormat::Yaml:  write_yaml(out, result); break;
        case OutputFormat::Solar: write_solar(out, result); break;
    }
}

std::vector<std::string> fphi_result_files(const std::string& basename, OutputFormat format) {
    switch (format) {
        case OutputFormat::Csv:
            return {basename + "_fphi_results.out", basename + "_parameters.out"};
        case OutputFormat::Tsv:
            return {basename + "_fphi_results.tsv", basename + "_parameters.tsv"};
        case OutputFormat::Json:  return {basename + "_fphi.json"};
        case OutputFormat::Yaml:  return {basename + "_fphi.yaml"};
        case OutputFormat::Solar: return {basename + "_fphi.solar.out"};
    }
    return {};
}

bool write_fphi_result_files(const std::string& basename, const FphiResult& result, OutputFormat format) {
    auto files = fphi_result_files(basename, format);
    if (format == OutputFormat::Csv || format == OutputFormat::Tsv) {
        char sep = format == OutputFormat::Csv ? ',' : '\t';
        std::ostringstream results, params;
        write_results_table(results, result, sep);
        write_parameters_table(params, result, sep);
        return write_file(files[0], results.str()) && write_file(files[1], params.str());
    }
    std::ostringstream ss;
    write_fphi_result(ss, result, format);
    return write_file(files[0], ss.str());
}
