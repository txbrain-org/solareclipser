/*
 * solar_log.h - Collect error and warning messages
 *
 * Package code writes its diagnostics to CERR, which collects them here
 * instead of printing them. The R interface (rcpp_interface.cpp) clears the
 * log before each call and afterwards raises "Warning: " lines as R warnings
 * and, if the call failed, the rest as an R error.
 */

#ifndef SOLAR_LOG_H
#define SOLAR_LOG_H

#include <sstream>

inline std::ostringstream& solar_log() {
    static std::ostringstream log;
    return log;
}

#define CERR solar_log()

#endif // SOLAR_LOG_H
