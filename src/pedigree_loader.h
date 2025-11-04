/*
 * pedigree_loader.h - Builder pattern for pedigree loading
 * Provides fluent API for configuring and loading pedigrees
 */

#ifndef PEDIGREE_LOADER_H
#define PEDIGREE_LOADER_H

#include <string>
#include <memory>
#include <vector>

// Forward declaration
class Pedigree;
struct EmpiricalPerson;
struct KinshipEntry;

enum class PedigreeFormat {
    AUTO,       // Auto-detect format
    EMPIRICAL,  // Kinship matrix CSV (IDA, IDB, KIN)
};

class PedigreeLoader {
public:
    class Builder {
    public:
        Builder() = default;

        Builder& from_file(const std::string& filename);
        Builder& with_threshold(double threshold);
        Builder& with_output_dir(const std::string& output_dir);
        Builder& with_format(PedigreeFormat format);

        std::unique_ptr<PedigreeLoader> build();

    private:
        std::string filename_;
        double threshold_ = 0.0;
        std::string output_dir_;
        PedigreeFormat format_ = PedigreeFormat::AUTO;

        bool validate() const;
    };

    // Execute the loading operation
    std::unique_ptr<Pedigree> load();

private:
    // Only constructible via Builder
    PedigreeLoader(const std::string& filename, double threshold,
                   const std::string& output_dir, PedigreeFormat format);

    std::string filename_;
    double threshold_;
    std::string output_dir_;
    PedigreeFormat format_;

    // Helper methods
    bool is_empirical_format(const std::string& filename);
    std::unique_ptr<Pedigree> load_empirical_pedigree();
    void create_output_files(const std::vector<EmpiricalPerson>& people,
                            const std::vector<KinshipEntry>& kinships,
                            int nfamilies);
    std::unique_ptr<Pedigree> load_pedigree_info();
};

#endif // PEDIGREE_LOADER_H
