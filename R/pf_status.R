#' Quick Status Summary for Peruvian Fauna
#'
#' @description
#' Provides an immediate formatted and atomized summary table of taxonomic group,
#' occurrence/residency status in Peru, CITES appendix, and national threat category
#' (D.S. 004-2014-MINAGRI) for each species.
#'
#' @param splist Character vector of species names, or a \code{data.frame}
#'   containing species names.
#' @param ... Arguments forwarded to \code{\link{pf_match}}.
#'
#' @return A \code{tibble::tibble} with 6 atomized columns:
#' \itemize{
#'   \item \code{submitted_name}: The raw input name.
#'   \item \code{accepted_name}: Validated/accepted scientific binomial name.
#'   \item \code{taxonomic_group}: Taxonomic class/group ("Aves", "Mammalia", etc., or NA).
#'   \item \code{occurrence_status}: Occurrence or residency status in Peru ("Residente", "Endémico", "Divagante", "Migratorio", etc., or NA).
#'   \item \code{cites_appendix}: CITES appendix ("I", "II", "III", or NA).
#'   \item \code{ds004_category}: National threat category under D.S. 004-2014-MINAGRI ("CR", "EN", "VU", "NT", or NA).
#' }
#' @export
#' @examples
#' \donttest{
#' pf_status(c("Panthera onca", "Vultur gryphus", "Tremarctos ornatus"))
#' }
pf_status <- function(splist, ...) {
  df <- pf_match(splist, ...)
  if (nrow(df) == 0) {
    return(tibble::tibble(
      submitted_name    = character(),
      accepted_name     = character(),
      taxonomic_group   = character(),
      occurrence_status = character(),
      cites_appendix    = character(),
      ds004_category    = character()
    ))
  }

  n <- nrow(df)
  occ_status <- character(n)

  for (i in seq_len(n)) {
    row <- df[i, ]
    if (!row$in_peru) {
      occ_status[i] <- NA_character_
    } else if (!is.na(row$in_unop) && nzchar(trimws(row$in_unop))) {
      occ_status[i] <- row$in_unop
    } else if (isTRUE(row$is_endemic)) {
      occ_status[i] <- "End\u00e9mico"
    } else {
      occ_status[i] <- "Residente"
    }
  }

  tax_grp <- df$taxonomic_group
  tax_grp[is.na(tax_grp) | tax_grp == "Unassigned"] <- NA_character_

  tibble::tibble(
    submitted_name    = df$submitted_name,
    accepted_name     = df$accepted_name,
    taxonomic_group   = tax_grp,
    occurrence_status = occ_status,
    cites_appendix    = df$cites_appendix,
    ds004_category    = df$ds004_category
  )
}
