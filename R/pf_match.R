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
#' @param max_distance Non-negative numeric distance used by `avesperu`.
#'   Values below 1 are relative to the name length (default: 0.1).
#' @param max_edit_distance Non-negative whole number of edits allowed by
#'   `citesperu` and `perufaunads004` (default: 1). The mammal matcher uses
#'   its own matching rules.
#' @param name_col Name of the scientific-name column when `splist` is a
#'   data frame. If omitted, a common column name is detected automatically.
#'
#' @return A \code{tibble::tibble} with harmonized cross-database columns:
#' \itemize{
#'   \item \code{submitted_name}: The raw input name.
#'   \item \code{accepted_name}: Validated/accepted scientific binomial name.
#'   \item \code{taxonomic_group}: Taxonomic class/group ("Aves", "Mammalia", "Reptilia", "Amphibia", etc.).
#'   \item \code{in_peru}: Logical. Listed in a Peruvian bird, mammal, or
#'     national fauna reference. CITES inclusion alone does not establish occurrence.
#'   \item \code{in_unop}: Character. UNOP bird status ("Residente", "Endémico", "Divagante", "Migratorio", "Introducido", "No confirmado", or NA).
#'   \item \code{in_pacheco}: Logical. Listed in Pacheco et al. (2021) Peru Mammals.
#'   \item \code{cites_appendix}: CITES status ("I", "II", "III", or NA).
#'   \item \code{ds004_category}: Category from D.S. 004, or from the SERFOR
#'     Red Book when the species is absent from D.S. 004.
#'   \item \code{is_threatened}: Logical. Listed in D.S. 004 or the SERFOR Red Book;
#'     Red Book inclusion alone does not establish legal protection.
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
pf_match <- function(splist, max_distance = 0.1, max_edit_distance = 1L,
                     name_col = NULL) {
  if (!is.numeric(max_distance) || length(max_distance) != 1L ||
      !is.finite(max_distance) || max_distance < 0 ||
      (max_distance >= 1 && max_distance != floor(max_distance))) {
    stop("`max_distance` must be one finite non-negative number, and an integer when >= 1.",
         call. = FALSE)
  }
  if (!is.numeric(max_edit_distance) || length(max_edit_distance) != 1L ||
      !is.finite(max_edit_distance) || max_edit_distance < 0 ||
      max_edit_distance != floor(max_edit_distance)) {
    stop("`max_edit_distance` must be one non-negative whole number.", call. = FALSE)
  }

  # Handle data.frame input
  if (is.data.frame(splist)) {
    candidates <- c("scientific_name", "species", "species_name", "nombre_cientifico", "name", "taxon")
    if (!is.null(name_col)) {
      if (!is.character(name_col) || length(name_col) != 1L ||
          is.na(name_col) || !name_col %in% names(splist)) {
        stop("`name_col` must name a column in `splist`.", call. = FALSE)
      }
      col_name <- name_col
    } else {
      match_col <- candidates[candidates %in% tolower(names(splist))]
      if (length(match_col)) {
        col_name <- names(splist)[match(tolower(match_col[1]), tolower(names(splist)))]
      } else if (ncol(splist) == 1L) {
        col_name <- names(splist)[1]
      } else {
        stop("Specify `name_col` for a data frame without a recognized scientific-name column.",
             call. = FALSE)
      }
    }
    input_names <- as.character(splist[[col_name]])
  } else {
    if (!is.null(name_col)) {
      stop("`name_col` can only be used with a data frame.", call. = FALSE)
    }
    if (!is.character(splist) && !is.factor(splist)) {
      stop("`splist` must be a character vector, factor, or data frame.", call. = FALSE)
    }
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
  query_source <- function(source, expr) {
    tryCatch(expr, error = function(e) {
      stop(sprintf("%s lookup failed: %s", source, conditionMessage(e)), call. = FALSE)
    })
  }
  res_aves <- query_source("avesperu", {
    avesperu::search_avesperu(input_names, max_distance = max_distance, return_details = TRUE, parallel = FALSE)
  })

  # 2. Query perumammals
  res_mammals <- query_source("perumammals", {
    match_peru_mammals(input_names)
  })

  # 3. Query citesperu
  res_cites <- query_source("citesperu", {
    citesperu::cites_match(input_names, max_dist = max_edit_distance, output = "standard")
  })

  # 4. Query perufaunads004
  res_ds004 <- query_source("perufaunads004", {
    perufaunads004::fauna_matching(input_names, max_distance = max_edit_distance,
                                   genus_match = FALSE)
  })

  for (result in list(res_aves, res_mammals, res_cites, res_ds004)) {
    if (!is.data.frame(result) || nrow(result) != n) {
      stop("A matching engine returned a result with an unexpected number of rows.",
           call. = FALSE)
    }
  }

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

    in_peru <- (is_unop && !identical(unop_status, "No confirmado")) ||
      is_pacheco || threatened

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
