#' Quick Status Summary for Peruvian Fauna
#'
#' @description
#' Provides an immediate formatted textual summary of Peru occurrence,
#' taxonomic group, CITES appendix, and national threat status for each species.
#'
#' @param splist Character vector of species names.
#' @param ... Arguments forwarded to \code{\link{pf_match}}.
#'
#' @return A character vector of species status summaries.
#' @export
#' @examples
#' \donttest{
#' pf_status(c("Panthera onca", "Vultur gryphus", "Tremarctos ornatus"))
#' }
pf_status <- function(splist, ...) {
  df <- pf_match(splist, ...)
  if (nrow(df) == 0) return(character())

  vapply(seq_len(nrow(df)), function(i) {
    row <- df[i, ]
    if (!row$in_peru) {
      return(paste0(row$submitted_name, ": No registrado en Per\u00fa"))
    }

    elements <- c()
    if (!is.na(row$taxonomic_group) && row$taxonomic_group != "Unassigned") {
      elements <- c(elements, row$taxonomic_group)
    }

    if (row$is_endemic) {
      elements <- c(elements, "End\u00e9mica")
    }

    if (!is.na(row$cites_appendix)) {
      elements <- c(elements, paste0("CITES ", row$cites_appendix))
    }

    if (!is.na(row$ds004_category)) {
      elements <- c(elements, paste0("D.S. 004: ", row$ds004_category))
    }

    status_str <- if (length(elements) > 0) paste(elements, collapse = " | ") else "Registrado"
    paste0(row$accepted_name, " (", status_str, ")")
  }, FUN.VALUE = character(1))
}
