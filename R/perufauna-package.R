#' perufauna: Easily Load and Harmonize Peruvian Fauna and Biodiversity Packages
#'
#' @description
#' The \code{perufauna} metapackage streamlines the installation, loading, and
#' integration of specialized R packages focused on Peruvian fauna and biodiversity:
#' \itemize{
#'   \item \code{avesperu}: Taxonomic backbone and search tools for the birds of Peru (UNOP checklist).
#'   \item \code{perumammals}: Taxonomic backbone and validation for mammals of Peru (Pacheco et al. 2021).
#'   \item \code{citesperu}: Status and verification of species in CITES Peru appendices (MINAM).
#'   \item \code{perufaunads004}: Threatened fauna categorization according to D.S. N° 004-2014-MINAGRI and SERFOR Red Book.
#' }
#'
#' In addition to orchestrated attachment, \code{perufauna} provides integrated cross-referencing
#' functions such as \code{\link{pf_match}} and \code{\link{pf_status}} to analyze species across
#' all taxonomic and regulatory sources in a single call.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang %||%
## usethis namespace: end
NULL
