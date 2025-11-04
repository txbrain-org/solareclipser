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
    const std::string& get_filename() const { return filename; }
    const std::vector<std::string>& get_headers() const { return headers; }
    const std::vector<std::vector<std::string>>& get_data() const { return data; }

private:
    std::string filename;
    std::vector<std::string> headers;
    std::vector<std::vector<std::string>> data;
};

#endif