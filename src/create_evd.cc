#include <fstream>
#include <vector>
#include <string>
#include <sstream>
#include <algorithm>
#include <cstring>
#include <zlib.h>
#include <map>

#include <Rcpp.h>
#define COUT Rcpp::Rcout
#define CERR Rcpp::Rcerr

#include "Eigen/Dense"
#include "create_evd.h"
#include "pedigree.h"
#include "phenotypes.h"

// FORTRAN eigenvalue decomposition routine
extern "C" void symeig_(int* n, double* a, double* d, double* e, double* z, int* info);

int CreateEVD::create_evd_data(
    Pedigree* pedigree,
    Phenotypes* phenotypes,
    const std::string& trait_name,
    const char* output_basename
) {
    if (!output_basename) {
        CERR << "Error: Please enter a base output filename with --o" << std::endl;
        return 1;
    }

    if (!pedigree) {
        CERR << "Error: No pedigree loaded" << std::endl;
        return 1;
    }

    if (!phenotypes) {
        CERR << "Error: No phenotype file is currently loaded" << std::endl;
        return 1;
    }

    if (trait_name.empty()) {
        CERR << "Error: No trait has been selected" << std::endl;
        return 1;
    }

    // Get phenotype data
    const auto& headers = phenotypes->get_headers();
    const auto& data = phenotypes->get_data();
    
    if (headers.empty() || data.empty()) {
        CERR << "Error: No phenotype data loaded" << std::endl;
        return 1;
    }
    
    // Find trait column
    int trait_col = -1;
    int id_col = -1;

    for (size_t i = 0; i < headers.size(); i++) {
        if (headers[i] == "id" || headers[i] == "ID") {
            id_col = i;
        }
        if (headers[i] == trait_name) {
            trait_col = i;
        }
    }

    if (id_col == -1) {
        CERR << "Error: No 'id' column found in phenotype data" << std::endl;
        return 1;
    }

    if (trait_col == -1) {
        CERR << "Error: Trait '" << trait_name << "' not found in phenotype data" << std::endl;
        return 1;
    }
    
    // First collect phenotype IDs with valid trait values
    std::vector<std::string> phenotype_ids;
    std::vector<double> trait_values;
    
    for (const auto& row : data) {
        if (row.size() > std::max(id_col, trait_col)) {
            const std::string& trait_val = row[trait_col];
            
            // Check if trait value is not missing (not empty, not "NA", not ".")
            if (!trait_val.empty() && trait_val != "NA" && trait_val != ".") {
                try {
                    double val = std::stod(trait_val);
                    phenotype_ids.push_back(row[id_col]);
                    trait_values.push_back(val);
                } catch (const std::exception&) {
                    // Skip invalid numeric values
                }
            }
        }
    }
    
    // Now filter phenotype IDs against pedigree IDs from pedindex.out
    // This matches the original SOLAR behavior
    std::vector<std::string> pedigree_ids;
    // pedindex.out is created by PedigreeLoader in the output directory
    // Extract output directory from output_basename
    std::string output_dir;
    std::string basename_str(output_basename);
    size_t last_slash = basename_str.find_last_of("/\\");
    if (last_slash != std::string::npos) {
        output_dir = basename_str.substr(0, last_slash);
    }
    std::string pedindex_path = output_dir.empty() ? "pedindex.out" : output_dir + "/pedindex.out";
    std::ifstream pedindex_file(pedindex_path);
    if (!pedindex_file) {
        CERR << "Error: No pedigree loaded (" << pedindex_path << " not found)" << std::endl;
        CERR << "Load pedigree first before creating EVD data" << std::endl;
        return 1;
    }
    
    std::string line;
    while (std::getline(pedindex_file, line)) {
        // pedindex.out format: sequential_id father mother mztwin family_id generation original_id
        // We want the original_id (last column)
        std::istringstream iss(line);
        std::string token;
        std::vector<std::string> tokens;
        while (iss >> token) {
            tokens.push_back(token);
        }
        if (tokens.size() >= 7) {  // Should have 7 columns
            pedigree_ids.push_back(tokens[6]);  // original_id is last column
        }
    }
    pedindex_file.close();
    
    if (pedigree_ids.empty()) {
        CERR << "Error: No valid pedigree IDs found" << std::endl;
        return 1;
    }
    
    // Filter phenotype IDs against pedigree
    
    // Filter to IDs that exist in both pedigree and have valid phenotypes
    // Iterate through pedigree_ids to preserve original pedigree order (matches SOLAR)
    std::vector<std::string> valid_ids;
    std::vector<double> filtered_trait_values;
    
    for (size_t i = 0; i < pedigree_ids.size(); i++) {
        const std::string& ped_id = pedigree_ids[i];
        // Check if this pedigree ID has phenotype data
        auto pheno_it = std::find(phenotype_ids.begin(), phenotype_ids.end(), ped_id);
        if (pheno_it != phenotype_ids.end()) {
            valid_ids.push_back(ped_id);
            size_t pheno_index = std::distance(phenotype_ids.begin(), pheno_it);
            filtered_trait_values.push_back(trait_values[pheno_index]);
        }
    }
    
    if (valid_ids.empty()) {
        CERR << "Error: No IDs found with both valid pedigree data and trait values" << std::endl;
        CERR << "Make sure the same IDs exist in both pedigree and phenotype files" << std::endl;
        return 1;
    }
    
    // Found matching IDs
    
    // Create output files (simplified version)
    std::string ids_filename = std::string(output_basename) + ".ids";
    std::string notes_filename = std::string(output_basename) + ".notes";
    
    // Write IDs file
    std::ofstream ids_file(ids_filename);
    if (!ids_file) {
        CERR << "Error: Cannot create output file " << ids_filename << std::endl;
        return 1;
    }
    
    for (size_t i = 0; i < valid_ids.size(); i++) {
        if (i > 0) ids_file << " ";
        ids_file << valid_ids[i];
    }
    ids_file.close();
    
    // Write notes file
    std::ofstream notes_file(notes_filename);
    if (!notes_file) {
        CERR << "Error: Cannot create notes file " << notes_filename << std::endl;
        return 1;
    }
    
    notes_file << "Number of IDs: " << valid_ids.size() << std::endl;
    notes_file << "Phenotype filename used for ID selection: " << phenotypes->get_filename() << std::endl;
    notes_file << "Trait used for ID selection: " << trait_name << std::endl;
    notes_file.close();
    
    // Read and decompose phi2 matrix
    if (compute_eigen_decomposition(valid_ids, output_basename) != 0) {
        CERR << "Error: Failed to compute eigenvalue decomposition" << std::endl;
        return 1;
    }
    
    // EVD files created
    
    return 0;
}

int CreateEVD::compute_eigen_decomposition(const std::vector<std::string>& valid_ids, const char* output_basename) {
    size_t n = valid_ids.size();

    // Read pedindex.out to get ID mapping
    // pedindex.out is created by PedigreeLoader in the output directory
    // Extract output directory from output_basename
    std::string output_dir;
    std::string basename_str(output_basename);
    size_t last_slash = basename_str.find_last_of("/\\");
    if (last_slash != std::string::npos) {
        output_dir = basename_str.substr(0, last_slash);
    }
    std::string pedindex_path = output_dir.empty() ? "pedindex.out" : output_dir + "/pedindex.out";
    std::ifstream pedindex_file(pedindex_path);
    if (!pedindex_file) {
        CERR << "Error: Cannot read " << pedindex_path << " for ID mapping" << std::endl;
        return 1;
    }
    
    std::vector<std::string> all_pedigree_ids;
    std::string line;
    while (std::getline(pedindex_file, line)) {
        std::istringstream iss(line);
        std::string token;
        std::vector<std::string> tokens;
        while (iss >> token) {
            tokens.push_back(token);
        }
        if (tokens.size() >= 7) {
            all_pedigree_ids.push_back(tokens[6]);  // original_id is last column
        }
    }
    pedindex_file.close();
    
    // Create mapping from valid_ids to indices in the full phi2 matrix
    std::vector<int> phi2_indices;
    for (const auto& valid_id : valid_ids) {
        auto it = std::find(all_pedigree_ids.begin(), all_pedigree_ids.end(), valid_id);
        if (it != all_pedigree_ids.end()) {
            phi2_indices.push_back(std::distance(all_pedigree_ids.begin(), it) + 1);  // 1-based indexing for phi2
        } else {
            CERR << "Error: ID " << valid_id << " not found in pedigree index" << std::endl;
            return 1;
        }
    }
    
    // Create phi2 matrix exactly like the original SOLAR implementation
    double* phi2_array = new double[n * n];

    // Read phi2 data into a map for easier access, matching original SOLAR approach
    std::map<std::pair<int,int>, double> phi2_data;
    std::string phi2_path = output_dir.empty() ? "phi2.gz" : output_dir + "/phi2.gz";
    gzFile phi2_file = gzopen(phi2_path.c_str(), "rt");
    if (!phi2_file) {
        CERR << "Error: Cannot open " << phi2_path << " file" << std::endl;
        return 1;
    }
    
    char buffer[1024];
    while (gzgets(phi2_file, buffer, sizeof(buffer))) {
        int row, col;
        double value;
        if (sscanf(buffer, "%d %d %lf", &row, &col, &value) == 3) {
            phi2_data[std::make_pair(row, col)] = value;
            if (row != col) {
                phi2_data[std::make_pair(col, row)] = value;  // Ensure symmetry
            }
        }
    }
    gzclose(phi2_file);
    
    // Build phi2 matrix exactly like original SOLAR (lines 205-210)
    // Original: phi2[col*ids.size() + col] = solar_phi2->get(ibdids[col], ibdids[col]);
    // Original: phi2[col*ids.size() + row] = phi2[row*ids.size() + col] = solar_phi2->get(ibdids[row], ibdids[col]);
    for(int col = 0; col < n; col++){
        // Diagonal element
        int ibdid_col = phi2_indices[col];
        auto it = phi2_data.find(std::make_pair(ibdid_col, ibdid_col));
        phi2_array[col * n + col] = (it != phi2_data.end()) ? it->second : 0.0;
        
        // Off-diagonal elements (matching original loop structure)
        for(int row = col + 1; row < n; row++){
            int ibdid_row = phi2_indices[row];
            auto it = phi2_data.find(std::make_pair(ibdid_row, ibdid_col));
            double value = (it != phi2_data.end()) ? it->second : 0.0;
            phi2_array[col * n + row] = value;
            phi2_array[row * n + col] = value;
        }
    }
    
    // Allocate arrays exactly like original SOLAR
    double* eigenvalues = new double[n];
    double* eigenvectors = new double[n * n];
    double* e_work = new double[n];
    memset(e_work, 0, sizeof(double)*n);  // Zero initialize like original
    int n_int = static_cast<int>(n);
    int* info = new int;
    *info = 0;
    
    // Call FORTRAN symeig routine exactly like original
    symeig_(&n_int, phi2_array, eigenvalues, e_work, eigenvectors, info);
    
    if (*info != 0) {
        CERR << "Error: FORTRAN eigenvalue decomposition failed with code " << *info << std::endl;
        delete[] phi2_array;
        delete[] eigenvalues;
        delete[] eigenvectors;
        delete[] e_work;
        delete info;
        return 1;
    }
    
    // Clean up work arrays
    delete[] phi2_array;
    delete[] e_work;
    delete info;
    
    // Write eigenvalues file using computed values
    std::string eigenvals_filename = std::string(output_basename) + ".eigenvalues";
    std::ofstream eigenvals_file(eigenvals_filename);
    if (!eigenvals_file) {
        CERR << "Error: Cannot create eigenvalues file" << std::endl;
        return 1;
    }
    
    for (int i = 0; i < n; i++) {  // TQL2 produces ascending order
        if (i > 0) eigenvals_file << " ";
        eigenvals_file << eigenvalues[i];
    }
    eigenvals_file.close();
    
    // Write eigenvectors file using computed values
    std::string eigenvecs_filename = std::string(output_basename) + ".eigenvectors";
    std::ofstream eigenvecs_file(eigenvecs_filename);
    if (!eigenvecs_file) {
        CERR << "Error: Cannot create eigenvectors file" << std::endl;
        return 1;
    }
    
    // Write eigenvectors in column-major order (same order as eigenvalues)
    // FORTRAN stores in column-major, so we read column by column
    for (int col = 0; col < n; col++) {
        for (int row = 0; row < n; row++) {
            eigenvecs_file << eigenvectors[col * n + row] << " ";
        }
    }
    eigenvecs_file.close();
    
    // Clean up remaining arrays
    delete[] eigenvalues;
    delete[] eigenvectors;

    return 0;
}
