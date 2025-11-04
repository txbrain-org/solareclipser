#include <sstream>

#include "csv_reader.h"

CSVReader::CSVReader(const std::string& filename) {
    file.open(filename);
}

CSVReader::~CSVReader() {
    if (file.is_open()) {
        file.close();
    }
}

bool CSVReader::get_header(std::vector<std::string>& header) {
    if (!file.is_open() || !std::getline(file, line)) {
        return false;
    }

    std::stringstream ss(line);
    std::string field;
    while (std::getline(ss, field, ',')) {
        // Remove leading/trailing whitespace
        field.erase(field.find_last_not_of(" \n\r\t")+1);
        field.erase(0, field.find_first_not_of(" \n\r\t"));
        header.push_back(field);
    }
    return true;
}

bool CSVReader::get_record(std::vector<std::string>& record) {
    if (!file.is_open() || !std::getline(file, line)) {
        return false;
    }

    std::stringstream ss(line);
    std::string field;
    record.clear();
    while (std::getline(ss, field, ',')) {
        // Remove leading/trailing whitespace
        field.erase(field.find_last_not_of(" \n\r\t")+1);
        field.erase(0, field.find_first_not_of(" \n\r\t"));
        record.push_back(field);
    }
    return true;
}

