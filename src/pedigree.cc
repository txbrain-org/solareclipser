/*
 * pedigree.cc - Pedigree data holder implementation
 * Refactored to be primarily a data container
 */

#include <sstream>
#include <iomanip>
#include <fstream>
#include <stdexcept>

#include <Rcpp.h>
#define COUT Rcpp::Rcout
#define CERR Rcpp::Rcerr

#include "pedigree.h"

int Pedigree::_Has_Sex = 0;

// Constructor - private, only accessible by PedigreeLoader
Pedigree::Pedigree(const std::string& filename,
                   const std::vector<PedigreeStats>& pedigree_stats,
                   int nfam, int nind, int nfou,
                   int id_len, int sex_len, int mztwin_len, int hhid_len, int famid_len)
    : filename_(filename),
      pedigree_stats_(pedigree_stats),
      nped_(pedigree_stats.size()),
      nfam_(nfam),
      nind_(nind),
      nfou_(nfou),
      id_len_(id_len),
      sex_len_(sex_len),
      mztwin_len_(mztwin_len),
      hhid_len_(hhid_len),
      famid_len_(famid_len) {
}

const PedigreeStats& Pedigree::stats(int pedigree_index) const {
    if (pedigree_index < 0 || pedigree_index >= nped_) {
        throw std::out_of_range("Pedigree index out of range");
    }
    return pedigree_stats_[pedigree_index];
}

bool Pedigree::has_multiple_loops() const {
    for (const auto& ped : pedigree_stats_) {
        if (ped.nlbrk > 1) return true;
    }
    return false;
}

bool Pedigree::has_inbreeding() const {
    for (const auto& ped : pedigree_stats_) {
        if (ped.inbred == 'y') return true;
    }
    return false;
}

std::string Pedigree::show_totals() const {
    std::ostringstream oss;
    oss << "\npedigree data file: " << filename_ << "\n\n";
    oss << std::setw(5) << nped_ << " pedigrees\n";
    oss << std::setw(5) << nfam_ << " nuclear families\n";
    oss << std::setw(5) << nind_ << " individuals\n";
    oss << std::setw(5) << nfou_ << " founders\n";

    if (has_multiple_loops() && has_inbreeding()) {
        oss << "\nMultiple loops, inbreeding present in 1 or more pedigrees.\n";
    } else if (has_multiple_loops()) {
        oss << "\nMultiple loops present in 1 or more pedigrees.\n";
    } else if (has_inbreeding()) {
        oss << "\nInbreeding present in 1 or more pedigrees.\n";
    }

    return oss.str();
}

std::string Pedigree::show_all() const {
    std::ostringstream oss;
    oss << "\npedigree data file: " << filename_ << "\n\n";
    oss << "ped#\t#nfam\t #ind\t #fou\t#bits\t#lbrk\tinbred?\n";
    oss << "----\t-----\t-----\t-----\t-----\t-----\t-------\n";

    for (int i = 0; i < nped_; i++) {
        const auto& ped = pedigree_stats_[i];

        if (ped.nind > 1) {
            oss << std::setw(4) << (i + 1) << "\t"
                << std::setw(5) << ped.nfam << "\t"
                << std::setw(5) << ped.nind << "\t"
                << std::setw(5) << ped.nfou << "\t"
                << std::setw(5) << (2*ped.nind - 3*ped.nfou) << "\t"
                << std::setw(5) << (ped.nlbrk ? ped.nlbrk : 0) << "\t"
                << "   " << (ped.inbred == 'y' ? 'y' : ' ') << "\n";
        } else {
            oss << std::setw(4) << (i + 1) << "\t"
                << std::setw(5) << ped.nfam << "\t"
                << std::setw(5) << ped.nind << "\t"
                << std::setw(5) << ped.nfou << "\t"
                << "     \t"
                << std::setw(5) << (ped.nlbrk ? ped.nlbrk : 0) << "\t"
                << "   " << (ped.inbred == 'y' ? 'y' : ' ') << "\n";
        }
    }

    oss << "\t-----\t-----\t-----\n";
    oss << "\t" << std::setw(5) << nfam_ << "\t"
        << std::setw(5) << nind_ << "\t"
        << std::setw(5) << nfou_ << "\n";

    return oss.str();
}

std::string Pedigree::show_pedigree(int pedigree_index) const {
    if (pedigree_index < 0 || pedigree_index >= nped_) {
        return "No such pedigree.";
    }

    std::ostringstream oss;
    const auto& ped = pedigree_stats_[pedigree_index];

    oss << "ped#\t#nfam\t #ind\t #fou\t#bits\t#lbrk\tinbred?\n";
    oss << "----\t-----\t-----\t-----\t-----\t-----\t-------\n";

    if (ped.nind > 1) {
        oss << std::setw(4) << (pedigree_index + 1) << "\t"
            << std::setw(5) << ped.nfam << "\t"
            << std::setw(5) << ped.nind << "\t"
            << std::setw(5) << ped.nfou << "\t"
            << std::setw(5) << (2*ped.nind - 3*ped.nfou) << "\t"
            << std::setw(5) << (ped.nlbrk ? ped.nlbrk : 0) << "\t"
            << "   " << (ped.inbred == 'y' ? 'y' : ' ') << "\n";
    } else {
        oss << std::setw(4) << (pedigree_index + 1) << "\t"
            << std::setw(5) << ped.nfam << "\t"
            << std::setw(5) << ped.nind << "\t"
            << std::setw(5) << ped.nfou << "\t"
            << "     \t"
            << std::setw(5) << (ped.nlbrk ? ped.nlbrk : 0) << "\t"
            << "   " << (ped.inbred == 'y' ? 'y' : ' ') << "\n";
    }

    return oss.str();
}

void Pedigree::export_to_csv(const std::string& output_file) const {
    std::ofstream file(output_file);
    if (!file.is_open()) {
        CERR << "Warning: Failed to write CSV to " << output_file << std::endl;
        return;
    }

    // Write CSV header
    file << "source_file,total_individuals,total_pedigrees,total_nuclear_families,founders\n";

    // Write pedigree metadata
    file << filename_ << "," << nind_ << "," << nped_ << "," << nfam_ << "," << nfou_ << "\n";

    file.close();
}
