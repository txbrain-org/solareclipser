#include <string>
#include <vector>
#include <algorithm>
#include <cctype>

#include <Rcpp.h>
#define COUT Rcpp::Rcout
#include "solar_log.h"

#include "phenotypes.h"
#include "csv_reader.h"

Phenotypes::Phenotypes() {}

Phenotypes::~Phenotypes() {}

bool Phenotypes::load(const std::string& fname) {
    filename = fname;
    CSVReader reader(filename);
    if (!reader.get_header(headers)) {
        CERR << "Error: Could not read header from " << filename << std::endl;
        return false;
    }

    data.clear();
    std::vector<std::string> record;
    while (reader.get_record(record)) {
        data.push_back(record);
    }
    return true;
}

void Phenotypes::describe() const {
    // Silent - no output to stdout
}

bool Phenotypes::has_trait(const std::string& trait_name) const {
    return std::find(headers.begin(), headers.end(), trait_name) != headers.end();
}

int Phenotypes::find_column(const std::string& name) const {
    auto it = std::find(headers.begin(), headers.end(), name);
    if (it != headers.end()) return it - headers.begin();
    for (size_t i = 0; i < headers.size(); i++) {
        const std::string& h = headers[i];
        if (h.size() == name.size() &&
            std::equal(h.begin(), h.end(), name.begin(), [](unsigned char a, unsigned char b) {
                return std::tolower(a) == std::tolower(b);
            })) {
            return i;
        }
    }
    return -1;
}

bool Phenotypes::parse_value(const std::string& s, double& value) {
    if (s.empty() || s == "NA" || s == ".") return false;
    if (s == "F" || s == "f") {
        value = 1.0;
        return true;
    }
    if (s == "M" || s == "m") {
        value = 0.0;
        return true;
    }
    try {
        value = std::stod(s);
        return true;
    } catch (const std::exception&) {
        return false;
    }
}
