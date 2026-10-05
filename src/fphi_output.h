/*
 * fphi_output.h - Format FPHI results
 *
 * Parsable formats (csv, tsv, json, yaml) write numbers at round-trip
 * precision. The solar format reproduces the summary block printed by the
 * original SOLAR-Eclipse `fphi` command, for diffing against its output.
 */

#ifndef FPHI_OUTPUT_H
#define FPHI_OUTPUT_H

#include <ostream>
#include <string>
#include <vector>

#include "fphi.h"

enum class OutputFormat { Csv, Tsv, Json, Yaml, Solar };

// Parse "csv", "tsv", "json", "yaml" or "solar" (case-insensitive)
bool parse_output_format(const std::string& name, OutputFormat& format);

// Write `result` to `out` in `format`
void write_fphi_result(std::ostream& out, const FphiResult& result, OutputFormat format);

// Files written by write_fphi_result_files for `format`
std::vector<std::string> fphi_result_files(const std::string& basename, OutputFormat format);

// Write `result` to the file(s) named by fphi_result_files. Returns false on error.
bool write_fphi_result_files(const std::string& basename, const FphiResult& result, OutputFormat format);

#endif // FPHI_OUTPUT_H
