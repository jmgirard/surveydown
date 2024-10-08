#' Update Surveydown Package and Extension
#'
#' This function checks and updates both the surveydown R package and its
#' associated Quarto extension. It ensures that both components are up-to-date
#' and their versions match.
#'
#' @param force Logical; if TRUE, forces an update regardless of current versions.
#' Defaults to FALSE.
#' @param ... Optional arguments to pass on to `sd_update_extension()`
#'
#' @return No return value, called for side effects.
#' @export
#'
#' @examples
#' \dontrun{
#' sd_update_surveydown()
#' sd_update_surveydown(force = TRUE)
#' }
sd_update_surveydown <- function(force = FALSE, ...) {
    # Check R package version
    pkg_version <- utils::packageVersion("surveydown")

    # Check Quarto extension version
    ext_version <- get_extension_version()

    if (is.null(ext_version)) {
        message("Quarto extension not found. Installing both package and extension.")
        force <- TRUE
    } else if (pkg_version != ext_version) {
        message("Version mismatch detected. Updating both package and extension.")
        force <- TRUE
    }

    if (force) {
        message("Updating surveydown R package and all dependencies...")
        remotes::install_github(
            "surveydown-dev/surveydown",
            force = TRUE,
            dependencies = TRUE,
            upgrade = "always"
        )

        message("Updating surveydown Quarto extension...")
        surveydown::sd_update_extension(...)

        message("Update complete.")
    } else {
        message("Both R package and Quarto extension are up-to-date.")
    }
}

#' Check Surveydown Versions
#'
#' This function checks if the local surveydown R package and Quarto extension
#' are up-to-date with the latest online version. It compares local versions
#' with the latest versions available on GitHub and provides information about
#' whether updates are needed.
#'
#' @return No return value, called for side effects (prints version information
#' and update status to the console).
#' @export
#'
#' @examples
#' sd_check_versions()
sd_check_versions <- function() {
    # Get local versions
    local_pkg_version <- utils::packageVersion("surveydown")
    local_ext_version <- get_extension_version()

    # Get latest online versions
    latest_pkg_version <- get_latest_version_from_url("https://raw.githubusercontent.com/surveydown-dev/surveydown/main/DESCRIPTION", "Version: ")
    latest_ext_version <- get_latest_version_from_url("https://raw.githubusercontent.com/surveydown-dev/surveydown-ext/main/_extensions/surveydown-dev/surveydown/_extension.yml", "version: ")

    # Display version information
    message("surveydown R package (local): ", local_pkg_version)
    message("surveydown R package (latest): ",
            if(is.null(latest_pkg_version)) "Unable to fetch" else latest_pkg_version)

    if (is.null(local_ext_version)) {
        message("surveydown Quarto ext (local): Not found")
    } else {
        message("surveydown Quarto ext (local): ", local_ext_version)
    }
    message("surveydown Quarto ext (latest): ",
            if(is.null(latest_ext_version)) "Unable to fetch" else latest_ext_version)

    # Check if updates are needed
    if (is.null(latest_pkg_version) || is.null(latest_ext_version)) {
        message("\nUnable to determine if updates are available.")
        message("Please ensure you have an active internet connection and try again later.")
    } else {
        pkg_needs_update <- local_pkg_version < latest_pkg_version
        ext_needs_update <- is.null(local_ext_version) || local_ext_version < latest_ext_version

        if (pkg_needs_update || ext_needs_update) {
            message("\nUpdates are available. To update both the package and extension to the latest version, run: surveydown::sd_update_surveydown()")
        } else {
            message("\nBoth the R package and Quarto extension are up to date.")
        }
    }
}

get_latest_version_from_url <- function(url, pattern) {
    tryCatch({
        content <- readLines(url)
        version_line <- grep(pattern, content, value = TRUE)
        if (length(version_line) > 0) {
            version <- sub(pattern, "", version_line[1])
            return(package_version(trimws(version)))
        } else {
            message("Version information not found in the file at ", url)
            return(NULL)
        }
    }, error = function(e) {
        message("Error occurred while fetching version from ", url, ": ", e$message)
        return(NULL)
    })
}

get_extension_version <- function(path = getwd()) {
    ext_yaml <- file.path(path, "_extensions", "surveydown-dev", "surveydown", "_extension.yml")
    if (!file.exists(ext_yaml)) {
        return(NULL)
    }
    yaml_content <- yaml::read_yaml(ext_yaml)
    return(yaml_content$version)
}
