
#ifndef CSV_READER_H
#define CSV_READER_H

#include <vector>
#include <string>
#include <fstream>

class CSVReader {
public:
    CSVReader(const std::string& filename);
    ~CSVReader();

    bool get_header(std::vector<std::string>& header);
    bool get_record(std::vector<std::string>& record);

private:
    std::ifstream file;
    std::string line;
};

#endif
