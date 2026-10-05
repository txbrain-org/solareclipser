/*
 * pedigree_loader.cc - Builder pattern implementation for pedigree loading
 */

#include <fstream>
#include <sstream>
#include <cstring>
#include <cctype>
#include <algorithm>
#include <iomanip>
#include <numeric>
#include <cstdio>
#include <string_view>
#include <unordered_map>
#include <zlib.h>

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

// Strip " \n\r\t" from both ends, as CSVReader does
static std::string_view trim_field(const char* begin, const char* end) {
    auto is_space = [](char c) { return c == ' ' || c == '\n' || c == '\r' || c == '\t'; };
    while (begin < end && is_space(*begin)) begin++;
    while (end > begin && is_space(end[-1])) end--;
    return std::string_view(begin, end - begin);
}

// Split one line on ',' with the same field semantics as CSVReader::get_record
// (std::getline on ','): an empty line has no fields, and a trailing ',' does
// not produce a trailing empty field.
static void split_fields(const char* begin, const char* end, std::vector<std::string_view>& fields) {
    fields.clear();
    const char* p = begin;
    while (p < end) {
        const char* comma = static_cast<const char*>(std::memchr(p, ',', end - p));
        const char* field_end = comma ? comma : end;
        fields.push_back(trim_field(p, field_end));
        if (!comma) break;
        p = comma + 1;
    }
}

// Read the file after its header line in blocks, calling on_line(begin, end)
// for each line (without the '\n'). Lines are split like std::getline.
template <typename F>
static bool for_each_data_line(const std::string& filename, F on_line) {
    std::ifstream in(filename, std::ios::binary);
    if (!in) return false;

    const size_t block_size = 1 << 24;
    std::vector<char> buf;
    size_t carry = 0;          // bytes of an incomplete line kept from the last block
    bool header_skipped = false;
    for (;;) {
        buf.resize(carry + block_size);
        in.read(buf.data() + carry, block_size);
        size_t got = static_cast<size_t>(in.gcount());
        size_t len = carry + got;
        bool eof = (got == 0);

        const char* p = buf.data();
        const char* end = buf.data() + len;
        for (;;) {
            const char* nl = static_cast<const char*>(std::memchr(p, '\n', end - p));
            if (!nl) break;
            if (header_skipped) on_line(p, nl);
            header_skipped = true;
            p = nl + 1;
        }
        if (eof) {
            if (p < end && header_skipped) on_line(p, end);  // last line without '\n'
            return true;
        }
        carry = end - p;
        std::memmove(buf.data(), p, carry);
    }
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

    // ID -> index into people. Sequential IDs are assigned in order of first
    // appearance (IDA before IDB), as SOLAR's epedigree does.
    std::unordered_map<std::string, int> id_index;
    auto find_or_add = [&](std::string_view id) {
        std::string key(id);
        auto it = id_index.find(key);
        if (it != id_index.end()) return it->second;
        int index = static_cast<int>(people.size());
        EmpiricalPerson person;
        person.original_id = key;
        person.sequential_id = index + 1;
        person.family_id = 0; // Will be set later
        people.push_back(person);
        id_index.emplace(std::move(key), index);
        return index;
    };

    const size_t min_fields = static_cast<size_t>(std::max({ida_col, idb_col, kin_col})) + 1;
    int line_num = 1;
    std::vector<std::string_view> fields;
    std::string last_ida;      // rows are usually grouped by IDA, so cache its index
    int last_ida_index = -1;
    std::string kin_str;
    bool read_ok = for_each_data_line(filename_, [&](const char* begin, const char* end) {
        line_num++;
        split_fields(begin, end, fields);

        if (fields.size() < min_fields) {
            CERR << "Warning: Invalid line " << line_num << ": insufficient fields" << std::endl;
            return;
        }

        std::string_view ida = fields[ida_col];
        std::string_view idb = fields[idb_col];
        kin_str.assign(fields[kin_col]);
        double kinship = std::stod(kin_str);

        int ida_index;
        if (last_ida_index >= 0 && ida == last_ida) {
            ida_index = last_ida_index;
        } else {
            ida_index = find_or_add(ida);
            last_ida.assign(ida);
            last_ida_index = ida_index;
        }
        int idb_index = find_or_add(idb);

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
    });
    if (!read_ok) {
        CERR << "Error: Cannot read " << filename_ << std::endl;
        return nullptr;
    }

    // Assign families: connected components of the kept kinship pairs,
    // found with union-find (sequential_id == index + 1)
    std::vector<int> parent(people.size());
    std::iota(parent.begin(), parent.end(), 0);
    auto find_root = [&](int x) {
        while (parent[x] != x) {
            parent[x] = parent[parent[x]];  // path halving
            x = parent[x];
        }
        return x;
    };
    for (const auto& k : kinships) {
        int a = find_root(k.id1 - 1);
        int b = find_root(k.id2 - 1);
        if (a != b) parent[std::max(a, b)] = std::min(a, b);
    }

    // Number families in order of their lowest-index member, as SOLAR does
    std::vector<int> family_of_root(people.size(), 0);
    int nfamilies = 0;
    for (size_t i = 0; i < people.size(); i++) {
        int root = find_root(i);
        if (family_of_root[root] == 0) family_of_root[root] = ++nfamilies;
        people[i].family_id = family_of_root[root];
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
        // One line per family (nfam nind nfou nlbrk inbred), as SOLAR's epedigree
        // writes; load_pedigree_info() reads nped of them. SOLAR's famsize is
        // always 1 for empirical pedigrees, so nind is 1 here too.
        for (int f = 0; f < nfamilies; f++) {
            info_fp << "1 1 1 0 n\n";
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

    // Create phi2.gz (kinship matrix), written directly through zlib.
    // Level 1 trades a slightly larger file for much faster compression.
    std::string phi2_path = make_output_path("phi2.gz", output_dir_);
    gzFile phi2_fp = gzopen(phi2_path.c_str(), "wb1");
    if (phi2_fp) {
        std::vector<char> out(1 << 20);
        size_t used = 0;
        bool ok = true;
        char line[512];  // "%.7f" of the largest double is ~320 chars
        for (const auto& k : kinships) {
            int n = std::snprintf(line, sizeof(line), "%7d %7d %.7f\n", k.id1, k.id2, k.kinship);
            if (out.size() - used < static_cast<size_t>(n)) {
                ok = ok && gzwrite(phi2_fp, out.data(), used) == static_cast<int>(used);
                used = 0;
            }
            std::memcpy(out.data() + used, line, n);
            used += n;
        }
        ok = ok && gzwrite(phi2_fp, out.data(), used) == static_cast<int>(used);
        ok = (gzclose(phi2_fp) == Z_OK) && ok;
        if (!ok) {
            CERR << "Error: Failed writing " << phi2_path << std::endl;
        }
    } else {
        CERR << "Error: Cannot create " << phi2_path << std::endl;
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
