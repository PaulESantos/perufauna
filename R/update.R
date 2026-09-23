#' Situation Report on perufauna and Core Biodiversity Packages
#'
#' Prints a diagnostic overview of the current R session, the version of
#' \code{perufauna}, and the installation status and version of each core
#' member package (\code{avesperu}, \code{perumammals}, \code{citesperu}, \code{perufaunads004}).
#'
#' @export
#' @examples
#' \donttest{
#' perufauna_sitrep()
#' }
perufauna_sitrep <- function() {
  cli::cat_rule("R Environment")
  cli::cat_bullet("R: ", getRversion())
  cli::cat_bullet("perufauna: ", as.character(utils::packageVersion("perufauna")))

  cli::cat_rule("Core Biodiversity Packages")

  pkgs <- perufauna_packages()
  for (pkg in pkgs) {
    pad <- format(pkg, width = 16)
    if (rlang::is_installed(pkg)) {
      ver <- as.character(utils::packageVersion(pkg))
      cli::cat_bullet(cli::col_blue(pad), " (v", highlight_version(ver), ")")
    } else {
      cli::cat_bullet(cli::col_yellow(cli::style_bold(pad)), " ", cli::col_red("[no instalado]"))
    }
  }

  invisible()
}

#' List all perufauna dependencies and versions
#'
#' @return A \code{tibble::tibble} with package names, installed status, and local versions.
#' @export
#' @examples
#' perufauna_deps()
perufauna_deps <- function() {
  pkgs <- perufauna_packages()

  installed <- vapply(pkgs, rlang::is_installed, FUN.VALUE = logical(1))
  versions <- vapply(pkgs, function(p) {
    if (rlang::is_installed(p)) as.character(utils::packageVersion(p)) else NA_character_
  }, FUN.VALUE = character(1))

  tibble::tibble(
    package = pkgs,
    installed = installed,
    local_version = versions
  )
}
