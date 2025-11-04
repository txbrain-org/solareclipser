#include <string>
#include <vector>
#include <algorithm>

#include <Rcpp.h>
#define COUT Rcpp::Rcout
#define CERR Rcpp::Rcerr

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
