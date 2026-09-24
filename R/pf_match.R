#' Cross-Referenced Taxonomic and Conservation Matching for Peruvian Fauna
#'
#' @description
#' Integrates and cross-references scientific names across all four specialized
#' Peruvian biodiversity databases:
#' \itemize{
#'   \item \code{avesperu}: UNOP Bird Checklist of Peru.
#'   \item \code{perumammals}: Pacheco et al. (2021) Peru Mammals Checklist.
#'   \item \code{citesperu}: MINAM Official CITES Appendices for Peru.
#'   \item \code{perufaunads004}: D.S. No. 004-2014-MINAGRI & SERFOR Threatened Fauna Red Book.
#' }
#'
#' @param splist Character vector of scientific names to validate, or a \code{data.frame}
#'   containing a column with species names.
#' @param max_distance Numeric. Maximum string distance allowed for fuzzy matching (default: 0.1).
#' @param ... Additional arguments passed to underlying matching engines.
#'
#' @return A \code{tibble::tibble} with harmonized cross-database columns:
#' \itemize{
#'   \item \code{submitted_name}: The raw input name.
#'   \item \code{accepted_name}: Validated/accepted scientific binomial name.
#'   \item \code{taxonomic_group}: Taxonomic class/group ("Aves", "Mammalia", "Reptilia", "Amphibia", etc.).
#'   \item \code{in_peru}: Logical. Confirmed presence in Peru via UNOP, Pacheco, or D.S. 004.
#'   \item \code{in_unop}: Character. UNOP bird status ("Residente", "Endémico", "Divagante", "Migratorio", "Introducido", "No confirmado", or NA).
#'   \item \code{in_pacheco}: Logical. Listed in Pacheco et al. (2021) Peru Mammals.
#'   \item \code{cites_appendix}: CITES status ("I", "II", "III", or NA).
#'   \item \code{ds004_category}: National threat category ("CR", "EN", "VU", "NT", or NA).
#'   \item \code{is_threatened}: Logical. Listed under national threat (D.S. 004 or Libro Rojo).
#'   \item \code{is_endemic}: Logical. Endemic to Peru (based on UNOP or Pacheco).
#' }
#'
#' @examples
#' \donttest{
#' species <- c("Panthera onca", "Vultur gryphus", "Tremarctos ornatus", "Homo sapiens")
#' pf_match(species)
#' }
#'
#' @export
pf_match <- function(splist, max_distance = 0.1, ...) {
  # Handle data.frame input
  if (is.data.frame(splist)) {
    candidates <- c("scientific_name", "species", "species_name", "nombre_cientifico", "name", "taxon")
    match_col <- candidates[candidates %in% tolower(names(splist))]
    col_name <- if (length(match_col) > 0) names(splist)[tolower(names(splist)) == match_col[1]][1] else names(splist)[1]
    input_names <- as.character(splist[[col_name]])
  } else {
    input_names <- as.character(splist)
  }

  n <- length(input_names)
  if (n == 0L) {
    return(tibble::tibble(
      submitted_name  = character(),
      accepted_name   = character(),
      taxonomic_group = character(),
      in_peru         = logical(),
      in_unop         = character(),
      in_pacheco      = logical(),
      cites_appendix  = character(),
      ds004_category  = character(),
      is_threatened   = logical(),
      is_endemic      = logical()
    ))
  }

  # 1. Query avesperu
  res_aves <- tryCatch({
    avesperu::search_avesperu(input_names, max_distance = max_distance, return_details = TRUE, parallel = FALSE)
  }, error = function(e) NULL)

  # 2. Query perumammals
  res_mammals <- tryCatch({
    perumammals::is_peru_mammal(input_names, return_details = TRUE)
  }, error = function(e) NULL)

  # 3. Query citesperu
  res_cites <- tryCatch({
    citesperu::cites_match(input_names, max_dist = max_distance, output = "standard")
  }, error = function(e) NULL)

  # 4. Query perufaunads004
  res_ds004 <- tryCatch({
    perufaunads004::fauna_matching(input_names, max_dist = max_distance, genus_match = FALSE)
  }, error = function(e) NULL)

  # Reconcile into unified table
  out_list <- vector("list", n)

  for (i in seq_len(n)) {
    raw_name <- input_names[i]

    # Defaults
    accepted_nm <- raw_name
    grp <- NA_character_
    unop_status <- NA_character_
    is_unop <- FALSE
    is_pacheco <- FALSE
    endemic <- FALSE
    cites_app <- NA_character_
    ds004_cat <- NA_character_
    threatened <- FALSE

    # Check Aves
    if (!is.null(res_aves) && i <= nrow(res_aves)) {
      a_row <- res_aves[i, ]
      if (!is.na(a_row$accepted_name) && nzchar(trimws(a_row$accepted_name))) {
        is_unop <- TRUE
        unop_status <- if (!is.na(a_row$status) && nzchar(trimws(a_row$status))) a_row$status else "Registrado"
        grp <- "Aves"
        accepted_nm <- a_row$accepted_name
        if (!is.na(a_row$status) && grepl("end[e\u00e9]mic", tolower(a_row$status))) {
          endemic <- TRUE
        }
      }
    }

    # Check Mammals
    if (!is.null(res_mammals) && i <= nrow(res_mammals)) {
      m_row <- res_mammals[i, ]
      if (isTRUE(m_row$matched)) {
        is_pacheco <- TRUE
        grp <- "Mammalia"
        accepted_nm <- m_row$Matched.Name
        if (isTRUE(m_row$endemic)) {
          endemic <- TRUE
        }
      }
    }

    # Check CITES
    if (!is.null(res_cites) && i <= nrow(res_cites)) {
      c_row <- res_cites[i, ]
      if (identical(c_row$match_assessment, "matched")) {
        cites_app <- c_row$apendice
        if (is.na(grp) && !is.na(c_row$clase) && nzchar(trimws(c_row$clase))) {
          grp <- c_row$clase
        }
        if (is.na(accepted_nm) || accepted_nm == raw_name) {
          if (!is.na(c_row$accepted_name)) accepted_nm <- c_row$accepted_name
        }
      }
    }

    # Check D.S. 004
    if (!is.null(res_ds004) && i <= nrow(res_ds004)) {
      d_row <- res_ds004[i, ]
      if (identical(d_row$match_status, "matched")) {
        ds004_cat <- if (!is.na(d_row$ds004_code) && nzchar(d_row$ds004_code)) d_row$ds004_code else d_row$libro_rojo_code
        threatened <- isTRUE(d_row$in_ds004) || isTRUE(d_row$in_libro_rojo)
        if (is.na(grp) && !is.na(d_row$clase) && nzchar(trimws(d_row$clase))) {
          grp <- d_row$clase
        }
        if (is.na(accepted_nm) || accepted_nm == raw_name) {
          if (!is.na(d_row$matched_name)) accepted_nm <- d_row$matched_name
        }
      }
    }

    in_peru <- is_unop || is_pacheco || threatened || (!is.na(cites_app))

    out_list[[i]] <- list(
      submitted_name  = raw_name,
      accepted_name   = accepted_nm,
      taxonomic_group = grp %||% "Unassigned",
      in_peru         = in_peru,
      in_unop         = unop_status,
      in_pacheco      = is_pacheco,
      cites_appendix  = cites_app,
      ds004_category  = ds004_cat,
      is_threatened   = threatened,
      is_endemic      = endemic
    )
  }

  tibble::as_tibble(do.call(rbind.data.frame, c(out_list, stringsAsFactors = FALSE)))
}
