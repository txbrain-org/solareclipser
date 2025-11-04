/*
 * pedigree_loader.cc - Builder pattern implementation for pedigree loading
 */

#include <fstream>
#include <sstream>
#include <cstring>
#include <cctype>
#include <algorithm>
#include <queue>
#include <iomanip>

#include <Rcpp.h>
#define COUT Rcpp::Rcout
#define CERR Rcpp::Rcerr

#include "pedigree_loader.h"
#include "pedigree.h"
#include "csv_reader.h"

// Helper function to construct output file path
static std::string make_output_path(const std::string& filename, const std::string& output_dir) {
    if (output_dir.empty()) {
        return filename;
    }

    std::string dir = output_dir;
    // Ensure directory ends with /
    if (dir.back() != '/') {
        dir += '/';
    }
    return dir + filename;
}

// === Builder Implementation ===

PedigreeLoader::Builder& PedigreeLoader::Builder::from_file(const std::string& filename) {
    filename_ = filename;
    return *this;
}

PedigreeLoader::Builder& PedigreeLoader::Builder::with_threshold(double threshold) {
    threshold_ = threshold;
    return *this;
}

PedigreeLoader::Builder& PedigreeLoader::Builder::with_output_dir(const std::string& output_dir) {
    output_dir_ = output_dir;
    return *this;
}

PedigreeLoader::Builder& PedigreeLoader::Builder::with_format(PedigreeFormat format) {
    format_ = format;
    return *this;
}

bool PedigreeLoader::Builder::validate() const {
    if (filename_.empty()) {
        CERR << "Error: Pedigree filename not specified" << std::endl;
        return false;
    }

    // Check file exists
    std::ifstream file(filename_);
    if (!file.good()) {
        CERR << "Error: Cannot open pedigree file: " << filename_ << std::endl;
        return false;
    }
    file.close();

    return true;
}

std::unique_ptr<PedigreeLoader> PedigreeLoader::Builder::build() {
    if (!validate()) {
        return nullptr;
    }

    return std::unique_ptr<PedigreeLoader>(
        new PedigreeLoader(filename_, threshold_, output_dir_, format_)
    );
}

// === PedigreeLoader Implementation ===

PedigreeLoader::PedigreeLoader(const std::string& filename, double threshold,
                               const std::string& output_dir, PedigreeFormat format)
    : filename_(filename),
      threshold_(threshold),
      output_dir_(output_dir),
      format_(format) {
}

bool PedigreeLoader::is_empirical_format(const std::string& filename) {
    CSVReader reader(filename);
    std::vector<std::string> header;

    if (!reader.get_header(header)) {
        return false;
    }

    // Check for comma-separated header with IDA, IDB, KIN fields
    bool has_ida = false, has_idb = false, has_kin = false;

    for (const auto& field : header) {
        // Convert to lowercase for comparison
        std::string lower = field;
        std::transform(lower.begin(), lower.end(), lower.begin(), ::tolower);

        if (lower.find("id") == 0) {
            if (!has_ida) {
                has_ida = true;
            } else if (!has_idb) {
                has_idb = true;
            }
        } else if (lower == "kin") {
            has_kin = true;
        }
    }

    return has_ida && has_idb && has_kin;
}

std::unique_ptr<Pedigree> PedigreeLoader::load() {
    // Determine format
    PedigreeFormat actual_format = format_;
    if (actual_format == PedigreeFormat::AUTO) {
        if (is_empirical_format(filename_)) {
            actual_format = PedigreeFormat::EMPIRICAL;
        } else {
            CERR << "Error: Only empirical pedigree format (IDA,IDB,KIN CSV) is supported" << std::endl;
            return nullptr;
        }
    }

    if (actual_format == PedigreeFormat::EMPIRICAL) {
        return load_empirical_pedigree();
    }

    CERR << "Error: Unsupported pedigree format" << std::endl;
    return nullptr;
}

std::unique_ptr<Pedigree> PedigreeLoader::load_empirical_pedigree() {
    CSVReader reader(filename_);
    std::vector<std::string> header;

    if (!reader.get_header(header)) {
        CERR << "Error: Cannot read header line from " << filename_ << std::endl;
        return nullptr;
    }

    // Parse header to find column indices
    int ida_col = -1, idb_col = -1, kin_col = -1;

    for (size_t col_index = 0; col_index < header.size(); col_index++) {
        std::string lower = header[col_index];
        std::transform(lower.begin(), lower.end(), lower.begin(), ::tolower);

        if (lower.find("id") == 0) {
            if (ida_col == -1) {
                ida_col = col_index;
            } else if (idb_col == -1) {
                idb_col = col_index;
            }
        } else if (lower == "kin") {
            kin_col = col_index;
        }
    }

    if (ida_col == -1 || idb_col == -1 || kin_col == -1) {
        CERR << "Error: Missing required columns IDA, IDB, or KIN" << std::endl;
        return nullptr;
    }

    // Data structures for parsing
    std::vector<EmpiricalPerson> people;
    std::vector<KinshipEntry> kinships;

    int line_num = 1;
    std::vector<std::string> fields;
    while (reader.get_record(fields)) {
        line_num++;

        if (fields.size() <= static_cast<size_t>(std::max({ida_col, idb_col, kin_col}))) {
            CERR << "Warning: Invalid line " << line_num << ": insufficient fields" << std::endl;
            continue;
        }

        std::string ida = fields[ida_col];
        std::string idb = fields[idb_col];
        double kinship = std::stod(fields[kin_col]);

        // Find or add IDA
        int ida_index = -1, idb_index = -1;
        for (size_t i = 0; i < people.size(); i++) {
            if (people[i].original_id == ida) {
                ida_index = i;
                break;
            }
        }
        if (ida_index == -1) {
            EmpiricalPerson person;
            person.original_id = ida;
            person.sequential_id = people.size() + 1;
            person.family_id = 0; // Will be set later
            ida_index = people.size();
            people.push_back(person);
        }

        // Find or add IDB
        for (size_t i = 0; i < people.size(); i++) {
            if (people[i].original_id == idb) {
                idb_index = i;
                break;
            }
        }
        if (idb_index == -1) {
            EmpiricalPerson person;
            person.original_id = idb;
            person.sequential_id = people.size() + 1;
            person.family_id = 0; // Will be set later
            idb_index = people.size();
            people.push_back(person);
        }

        // Check if kinship meets threshold and store
        bool passes_threshold = false;
        if (threshold_ == 0.0) {
            passes_threshold = (kinship > 0.0);
        } else {
            passes_threshold = (kinship >= threshold_);
        }

        if (passes_threshold || ida_index == idb_index) {
            KinshipEntry entry;
            entry.id1 = people[ida_index].sequential_id;
            entry.id2 = people[idb_index].sequential_id;
            entry.kinship = kinship;
            kinships.push_back(entry);
        }
    }

    // Assign families using BFS (connected components)
    std::vector<bool> visited(people.size(), false);
    int nfamilies = 0;

    for (size_t i = 0; i < people.size(); i++) {
        if (!visited[i]) {
            nfamilies++;

            // BFS to find all connected people
            std::queue<int> q;
            q.push(i);
            visited[i] = true;
            people[i].family_id = nfamilies;

            while (!q.empty()) {
                int current = q.front();
                q.pop();

                // Find all kinship entries involving this person
                for (const auto& k : kinships) {
                    int other = -1;
                    if (k.id1 == people[current].sequential_id) {
                        other = k.id2;
                    } else if (k.id2 == people[current].sequential_id) {
                        other = k.id1;
                    }

                    if (other != -1) {
                        // Find the person with this sequential_id
                        for (size_t p = 0; p < people.size(); p++) {
                            if (people[p].sequential_id == other && !visited[p]) {
                                visited[p] = true;
                                people[p].family_id = nfamilies;
                                q.push(p);
                            }
                        }
                    }
                }
            }
        }
    }

    // Create output files
    create_output_files(people, kinships, nfamilies);

    // Load statistics from generated pedigree.info file
    auto pedigree = load_pedigree_info();

    return pedigree;
}

void PedigreeLoader::create_output_files(const std::vector<EmpiricalPerson>& people,
                                         const std::vector<KinshipEntry>& kinships,
                                         int nfamilies) {
    // Find max ID length
    int max_id_len = 30; // minimum default
    for (const auto& person : people) {
        int len = person.original_id.length();
        if (len > max_id_len) max_id_len = len;
    }

    // Create pedigree.info file
    std::string pedigree_info_path = make_output_path("pedigree.info", output_dir_);
    std::ofstream info_fp(pedigree_info_path);
    if (info_fp.is_open()) {
        info_fp << filename_ << " empirical\n";
        info_fp << max_id_len << " 1 0 0 0\n"; // id_len, sex_len, mztwin_len, hhid_len, famid_len
        info_fp << nfamilies << " " << nfamilies << " " << people.size() << " " << nfamilies << "\n"; // nped, nfam, nind, nfou
        info_fp << "1 1 1 0 n\n"; // family 1 info
        if (nfamilies > 1) {
            info_fp << "1 1 1 0 n\n"; // family 2 info (if exists)
        }
        info_fp.close();
    }

    // Create pedindex.out file
    std::string pedindex_out_path = make_output_path("pedindex.out", output_dir_);
    std::ofstream pedindex_fp(pedindex_out_path);
    if (pedindex_fp.is_open()) {
        for (size_t i = 0; i < people.size(); i++) {
            const auto& person = people[i];
            const char* spacing = (person.family_id == 1) ? "                     " : "                         ";
            pedindex_fp << std::setw(5) << (i+1)     // sequential ID (1-based)
                       << " " << std::setw(5) << 0   // father sequential ID (0 = no father)
                       << " " << std::setw(5) << 0   // mother sequential ID (0 = no mother)
                       << " " << std::setw(3) << 0   // sex (0 = unknown)
                       << " " << std::setw(5) << person.family_id  // family ID
                       << " " << std::setw(5) << 1   // generation (always 1 for empirical)
                       << spacing << person.original_id << "\n";
        }
        pedindex_fp.close();
    }

    // Create phi2 (kinship matrix)
    std::string phi2_path = make_output_path("phi2", output_dir_);
    std::ofstream phi2_fp(phi2_path);
    if (phi2_fp.is_open()) {
        int matrix_digits = 7;

        for (const auto& k : kinships) {
            phi2_fp << std::setw(matrix_digits) << k.id1 << " "
                   << std::setw(matrix_digits) << k.id2 << " "
                   << std::fixed << std::setprecision(7) << k.kinship << "\n";
        }
        phi2_fp.close();

        // Create phi2.gz using system gzip
        std::string gzip_cmd = "gzip -f " + phi2_path;
        system(gzip_cmd.c_str());
    }

    // Create pedindex.cde file
    std::string pedindex_cde_path = make_output_path("pedindex.cde", output_dir_);
    std::ofstream pedcde_fp(pedindex_cde_path);
    if (pedcde_fp.is_open()) {
        pedcde_fp << "pedindex.out                                          \n";
        pedcde_fp << " 5 IBDID                 IBDID                       I\n";
        pedcde_fp << " 1 BLANK                 BLANK                       C\n";
        pedcde_fp << " 5 FATHER'S IBDID        FIBDID                      I\n";
        pedcde_fp << " 1 BLANK                 BLANK                       C\n";
        pedcde_fp << " 5 MOTHER'S IBDID        MIBDID                      I\n";
        pedcde_fp << " 1 BLANK                 BLANK                       C\n";
        pedcde_fp << " 3 MZTWIN                MZTWIN                      I\n";
        pedcde_fp << " 1 BLANK                 BLANK                       C\n";
        pedcde_fp << " 5 PEDIGREE NUMBER       PEDNO                       I\n";
        pedcde_fp << " 1 BLANK                 BLANK                       C\n";
        pedcde_fp << " 5 GENERATION NUMBER     GEN                         I\n";
        pedcde_fp << " 1 BLANK                 BLANK                       C\n";
        pedcde_fp << std::setw(2) << max_id_len << " ID                    ID                          C\n";
        pedcde_fp.close();
    }

    // Create solar-pedigree.csv file (pedigree summary statistics)
    std::string solar_ped_csv_path = make_output_path("solar-pedigree.csv", output_dir_);
    std::ofstream solar_csv_fp(solar_ped_csv_path);
    if (solar_csv_fp.is_open()) {
        // Write header
        solar_csv_fp << "source_file,total_individuals,total_pedigrees,total_nuclear_families,founders\n";
        // Write data - for empirical pedigrees, all individuals are founders
        solar_csv_fp << filename_ << "," << people.size() << "," << nfamilies << ","
                     << nfamilies << "," << people.size() << "\n";
        solar_csv_fp.close();
    }
}

std::unique_ptr<Pedigree> PedigreeLoader::load_pedigree_info() {
    std::string pedigree_info_path = make_output_path("pedigree.info", output_dir_);
    std::ifstream fp(pedigree_info_path);
    if (!fp.good()) {
        CERR << "Error: Cannot open pedigree.info" << std::endl;
        return nullptr;
    }

    std::string line;
    std::string fname;

    // Line 1: filename
    if (!std::getline(fp, line)) {
        CERR << "Error: Read error on pedigree.info, line 1" << std::endl;
        return nullptr;
    }
    std::istringstream(line) >> fname;

    // Line 2: field lengths
    int id_len, sex_len, mztwin_len, hhid_len, famid_len;
    if (!std::getline(fp, line) ||
        !(std::istringstream(line) >> id_len >> sex_len >> mztwin_len >> hhid_len >> famid_len)) {
        CERR << "Error: Read error on pedigree.info, line 2" << std::endl;
        return nullptr;
    }

    // Line 3: totals
    int nped, nfam, nind, nfou;
    if (!std::getline(fp, line) ||
        !(std::istringstream(line) >> nped >> nfam >> nind >> nfou)) {
        CERR << "Error: Read error on pedigree.info, line 3" << std::endl;
        return nullptr;
    }

    // Read pedigree stats
    std::vector<PedigreeStats> pedigree_stats;
    for (int i = 0; i < nped; i++) {
        PedigreeStats stats;
        if (!std::getline(fp, line) ||
            !(std::istringstream(line) >> stats.nfam >> stats.nind >> stats.nfou >> stats.nlbrk >> stats.inbred)) {
            CERR << "Error: Read error on pedigree.info, line " << (i + 4) << std::endl;
            return nullptr;
        }
        pedigree_stats.push_back(stats);
    }

    fp.close();

    // Create Pedigree object
    return std::unique_ptr<Pedigree>(
        new Pedigree(filename_, pedigree_stats, nfam, nind, nfou,
                     id_len, sex_len, mztwin_len, hhid_len, famid_len)
    );
}
