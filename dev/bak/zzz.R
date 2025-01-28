# zzz.R
# This file contains special functions such as .onLoad(), .onAttach(), .onUnload(), and .onDetach()
# https://r-pkgs.org/Code.html#when-you-do-need-side-effects
#.onLoad <- function(libname, pkgname) {
#  solareclipser_root <- system.file(package = "solareclipser")
#  solar_install_root <- file.path(solareclipser_root, "lib/solar900")
#  solar_install_exec <- file.path(solar_install_root, "install_solar")
#  solar_exec <- file.path(solar_install_root, "solar")
#
#  r_solar_linux <-file.path(solar_install_root, ".r_solar_linux")
#  r_solar_macos <- file.path(solar_install_root, ".r_solar_macos")
#
#  os <- .Platform$OS.type
#  sys_info <- Sys.info()
#  platform <- sys_info["sysname"]
#  release <- sys_info["release"]
#  version <- sys_info["version"]
#  nodename <- sys_info["nodename"]
#  machine <- sys_info["machine"]
#
#  # root - static/
#  solar_linux_file <- "solar-eclipse-9.0.0-static-Linux.zip"
#  # root - solar900/
#  solar_macos_file <- "solar-eclipse-9.0.0-mac-Monterey.zip"
#  dest_dir <- file.path(solareclipser_root, "lib")
#
#  solar_linux_url <-
#    paste0("https://www.nitrc.org/frs/download.php/12468/", solar_linux_file)
#  solar_macos_url <-
#    paste0("https://www.nitrc.org/frs/download.php/12460/", solar_macos_file)
#
#  warn_msg_solar_not_found <-
#    simpleWarning(paste("solar not found, installing ..."))
#  warn_msg_solar_meta_not_found <-
#    simpleWarning(paste("solar meta info not found, installing ..."))
#  err_msg_unsupported_os <-
#    simpleError(paste("Unsupported OS -", os))
#  err_msg_file_download_failed <-
#    simpleError(paste("File download failed -", solar_linux_url))
#  err_msg_dir_create_failed <-
#    simpleError(paste("Directory creation failed -", dest_dir))
#
#  if (!file.exists(solar_exec)) {
#    if (os == "unix") { # Linux or macOS
#
#      if (platform == "Linux") {
#
#        dest_file <- file.path(dest_dir, solar_linux_file)
#        err_msg_unzip_failed <-
#          simpleError(paste("Unzip failed -", dest_file))
#        err_msg_rm_failed <-
#          simpleError(paste("File removal failed -", dest_file))
#
#        if (!file.exists(file.path(solareclipser_root, "lib"))) {
#          tryCatch({
#            dir.create(file.path(solareclipser_root, "lib"))
#          }, error = function(e) {
#            stop(err_msg_dir_create_failed)
#          })
#        }
#        tryCatch({
#          download.file(solar_linux_url, dest_file)
#        }, error = function(e) {
#          stop(err_msg_file_download_failed)
#        })
#        tryCatch({
#          unzip(dest_file, exdir = dest_dir)
#        }, error = function(e) {
#          stop(err_msg_unzip_failed)
#        })
#        tryCatch({
#          file.remove(dest_file)
#        }, error = function(e) {
#          stop(err_msg_rm_failed)
#        })
#        tryCatch({
#          system(paste("chmod u+x", solar_install_exec))
#        }, error = function(e) {
#          stop(simpleError("chmod failed"))
#        })
#        # if directory named static -> Rename the directory to solar900
#        if (file.exists(file.path(dest_dir, "static"))) {
#          tryCatch({
#            file.rename(file.path(dest_dir, "static"), solar_install_root)
#          }, error = function(e) {
#            stop(simpleError("rename failed"))
#          })
#        }
#        tryCatch({
#          system(paste(solar_install_exec, solar_install_root, solar_install_root)) # nolint: line_length_linter.
#        }, error = function(e) {
#          stop(simpleError("solar installation failed"))
#        })
#      } else { # macOS - Darwin
#
#        dest_file <- file.path(dest_dir, solar_linux_file)
#        err_msg_unzip_failed <-
#          simpleError(paste("Unzip failed -", dest_file))
#        err_msg_rm_failed <-
#          simpleError(paste("File removal failed -", dest_file))
#
#        if (!file.exists(file.path(solareclipser_root, "lib"))) {
#          tryCatch({
#            dir.create(file.path(solareclipser_root, "lib"))
#          }, error = function(e) {
#            stop(err_msg_dir_create_failed)
#          })
#        }
#        tryCatch({
#          download.file(solar_linux_url, dest_file)
#        }, error = function(e) {
#          stop(err_msg_file_download_failed)
#        })
#        tryCatch({
#          unzip(dest_file, exdir = dest_dir)
#        }, error = function(e) {
#          stop(err_msg_unzip_failed)
#        })
#        tryCatch({
#          file.remove(dest_file)
#        }, error = function(e) {
#          stop(err_msg_rm_failed)
#        })
#        tryCatch({
#          system(paste("chmod u+x", solar_install_exec))
#        }, error = function(e) {
#          stop(simpleError("chmod failed"))
#        })
#        # if directory named static -> Rename the directory to solar900
#        if (file.exists(file.path(dest_dir, "static"))) {
#          tryCatch({
#            file.rename(file.path(dest_dir, "static"), solar_install_root)
#          }, error = function(e) {
#            stop(simpleError("rename failed"))
#          })
#        }
#        tryCatch({
#          system(paste(solar_install_exec, solar_install_root, solar_install_root)) # nolint: line_length_linter.
#        }, error = function(e) {
#          stop(simpleError("solar installation failed"))
#        })
#      }
#    } else { # Windows
#
#      stop(err_msg_unsupported_os)
#    }
#  }
#}
