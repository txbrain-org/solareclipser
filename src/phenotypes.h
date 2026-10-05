#ifndef PHENOTYPES_H
#define PHENOTYPES_H

#include <vector>
#include <string>

class Phenotypes {
public:
    Phenotypes();
    ~Phenotypes();

    bool load(const std::string& fname);
    void describe() const;

    // Instance methods
    bool has_trait(const std::string& trait_name) const;
    // Index of the column named `name` (exact match, else case-insensitive);
    // -1 if there is none
    int find_column(const std::string& name) const;
    // Parse a phenotype value. Missing ("", "NA", ".") or non-numeric values
    // return false; "F" and "M" read as 1 and 0, as in SOLAR.
    static bool parse_value(const std::string& s, double& value);
    const std::string& get_filename() const { return filename; }
    const std::vector<std::string>& get_headers() const { return headers; }
    const std::vector<std::vector<std::string>>& get_data() const { return data; }

private:
    std::string filename;
    std::vector<std::string> headers;
    std::vector<std::vector<std::string>> data;
};

#endif