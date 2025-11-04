/*
 * pedigree.h - Pedigree data holder class
 * Refactored to use modern C++ and serve as immutable data container
 */

#ifndef PEDIGREE_H
#define PEDIGREE_H

#include <string>
#include <vector>

// Structure to hold individual pedigree statistics
struct PedigreeStats {
    int nfam;       // Number of families
    int nind;       // Number of individuals
    int nfou;       // Number of founders
    int nlbrk;      // Number of loops/breaks
    char inbred;    // Inbreeding present ('y' or 'n')
};

class Pedigree {
public:
    // Accessors (immutable after construction)
    const std::string& filename() const { return filename_; }
    int num_pedigrees() const { return nped_; }
    int num_families() const { return nfam_; }
    int num_individuals() const { return nind_; }
    int num_founders() const { return nfou_; }

    int id_len() const { return id_len_; }
    int sex_len() const { return sex_len_; }

    // Statistics access
    const PedigreeStats& stats(int pedigree_index) const;
    bool has_multiple_loops() const;
    bool has_inbreeding() const;

    // Display/export
    std::string show_totals() const;
    std::string show_all() const;
    std::string show_pedigree(int pedigree_index) const;
    void export_to_csv(const std::string& output_file) const;

    // Static method (for compatibility)
    static void SexVar(int val) { _Has_Sex = val; }
    static int HasSex() { return _Has_Sex; }

private:
    // Only constructible by PedigreeLoader
    friend class PedigreeLoader;

    Pedigree(const std::string& filename,
             const std::vector<PedigreeStats>& pedigree_stats,
             int nfam, int nind, int nfou,
             int id_len, int sex_len, int mztwin_len, int hhid_len, int famid_len);

    std::string filename_;
    std::vector<PedigreeStats> pedigree_stats_;
    int nped_;      // Number of pedigrees
    int nfam_;      // Total families
    int nind_;      // Total individuals
    int nfou_;      // Total founders
    int id_len_;
    int sex_len_;
    int mztwin_len_;
    int hhid_len_;
    int famid_len_;

    static int _Has_Sex;
};

// Empirical pedigree structures for loading
struct EmpiricalPerson {
    std::string original_id;
    int sequential_id;
    int family_id;
};

struct KinshipEntry {
    int id1;
    int id2;
    double kinship;
};

#endif // PEDIGREE_H
