app_records <- function(text = "", file = NULL, column = NULL) {
  lines <- if (is.null(text) || !length(text) || is.na(text[1]) || !nzchar(text[1])) character() else
    trimws(strsplit(text[1], "\r\n|\n|\r")[[1]])
  nonempty <- which(nzchar(lines))
  pasted <- data.frame(
    submitted_name = lines[nonempty],
    source_file = rep("Texto pegado", length(nonempty)),
    source_row = nonempty,
    stringsAsFactors = FALSE
  )
  if (is.null(file)) return(pasted)
  if (is.null(column) || !length(column) || !is.character(column) || !column %in% names(file$data)) {
    stop("Selecciona la columna que contiene los nombres cient\u00EDficos.", call. = FALSE)
  }
  uploaded <- data.frame(
    submitted_name = as.character(file$data[[column]]),
    source_file = rep(file$name, nrow(file$data)),
    source_row = seq_len(nrow(file$data)) + file$header_rows,
    stringsAsFactors = FALSE
  )
  uploaded <- uploaded[!is.na(uploaded$submitted_name) &
                         nzchar(trimws(uploaded$submitted_name)), , drop = FALSE]
  rbind(pasted, uploaded)
}

app_read_file <- function(path, filename, header = TRUE) {
  ext <- tolower(tools::file_ext(filename))
  if (!ext %in% c("txt", "csv", "tsv", "xlsx", "xls")) {
    stop("Usa un archivo TXT, CSV, TSV, XLS o XLSX.", call. = FALSE)
  }
  if (ext == "txt") {
    values <- readLines(path, warn = FALSE, encoding = "UTF-8")
    data <- data.frame(nombre_cientifico = values, stringsAsFactors = FALSE)
    header_rows <- 0L
  } else if (ext %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Instala 'readxl' para importar archivos de Excel.", call. = FALSE)
    }
    data <- as.data.frame(readxl::read_excel(path, col_names = header,
                                            .name_repair = "unique"),
                          stringsAsFactors = FALSE)
    header_rows <- as.integer(header)
  } else if (ext == "csv") {
    first_line <- readLines(path, n = 1, warn = FALSE, encoding = "UTF-8")
    sep <- if (length(first_line) && grepl(";", first_line[1]) && !grepl(",", first_line[1])) ";" else ","
    data <- utils::read.csv(path, header = header, sep = sep, check.names = FALSE,
                            stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM",
                            na.strings = c("NA"))
    header_rows <- as.integer(header)
  } else {
    data <- utils::read.delim(path, header = header, check.names = FALSE,
                              stringsAsFactors = FALSE, fileEncoding = "UTF-8-BOM",
                              na.strings = c("NA"))
    header_rows <- as.integer(header)
  }
  if (!ncol(data)) stop("El archivo no contiene columnas.", call. = FALSE)
  list(name = basename(filename), data = data, header_rows = header_rows)
}

app_guess_column <- function(data) {
  candidates <- c("scientific_name", "nombre_cientifico", "species_name",
                  "species", "taxon", "name", "submitted_name")
  normalized <- gsub("[[:space:]]+", "_", tolower(names(data)))
  hit <- match(candidates, normalized, nomatch = 0L)
  hit <- hit[hit > 0L]
  if (length(hit)) names(data)[hit[1]] else if (ncol(data) == 1L) names(data)[1] else ""
}

app_validate_records <- function(records) {
  if (!nrow(records)) stop("Ingresa al menos un nombre cient\u00EDfico.", call. = FALSE)
  if (nrow(records) > 10000L) stop("El m\u00E1ximo es de 10 000 nombres por consulta.", call. = FALSE)
  if (any(nchar(records$submitted_name) > 200L, na.rm = TRUE)) {
    stop("Cada nombre debe tener como m\u00E1ximo 200 caracteres.", call. = FALSE)
  }
  invisible(records)
}

app_query <- function(module, names, settings) {
  switch(module,
    integrada = {
      view <- if (is.character(settings$view) && length(settings$view) == 1L) settings$view else "resumen"
      b_dist <- if (is.numeric(settings$bird_distance) && length(settings$bird_distance) == 1L) {
        settings$bird_distance
      } else 0.15
      e_dist <- if (is.numeric(settings$edit_distance) && length(settings$edit_distance) == 1L) {
        settings$edit_distance
      } else 2L
      if (identical(view, "resumen")) {
        pf_status(names, max_distance = b_dist, max_edit_distance = e_dist)
      } else {
        pf_match(names, max_distance = b_dist, max_edit_distance = e_dist)
      }
    },
    aves = {
      dist <- if (is.numeric(settings$distance) && length(settings$distance) == 1L) {
        settings$distance
      } else 0.15
      result <- avesperu::search_avesperu(
        names, max_distance = dist,
        return_details = TRUE, parallel = FALSE
      )
      audit <- attr(result, "reconciliation")
      result <- as.data.frame(result)
      if (is.data.frame(audit) && nrow(audit) == nrow(result)) {
        extra <- setdiff(base::names(audit), base::names(result))
        result <- cbind(result, audit[extra])
      }
      result
    },
    mamiferos = match_peru_mammals(names),
    cites = {
      taxon <- if (is.character(settings$taxon) && length(settings$taxon) == 1L && nzchar(settings$taxon)) {
        settings$taxon
      } else "fauna"
      edition <- if (is.character(settings$edition) && length(settings$edition) == 1L && nzchar(settings$edition)) {
        settings$edition
      } else "latest"
      dist <- if (is.numeric(settings$distance) && length(settings$distance) == 1L) {
        settings$distance
      } else 2L
      synonyms <- if (is.logical(settings$synonyms) && length(settings$synonyms) == 1L) {
        settings$synonyms
      } else TRUE
      genus <- if (is.logical(settings$genus) && length(settings$genus) == 1L) {
        settings$genus
      } else FALSE
      citesperu::cites_match(
        names, taxon = taxon, edition = edition,
        max_dist = dist, allow_synonyms = synonyms,
        genus_fallback = genus, output = "standard"
      )
    },
    amenaza = {
      grp <- if (is.character(settings$group) && length(settings$group) == 1L && nzchar(settings$group)) {
        settings$group
      } else {
        NULL
      }
      dist <- if (is.numeric(settings$distance) && length(settings$distance) == 1L) {
        settings$distance
      } else {
        2L
      }
      fuzzy <- if (is.logical(settings$fuzzy) && length(settings$fuzzy) == 1L) {
        settings$fuzzy
      } else {
        TRUE
      }
      genus <- if (is.logical(settings$genus) && length(settings$genus) == 1L) {
        settings$genus
      } else {
        TRUE
      }
      perufaunads004::fauna_matching(
        names, max_distance = dist, fuzzy = fuzzy,
        genus_match = genus, group = grp
      )
    },
    stop("M\u00F3dulo de consulta desconocido.", call. = FALSE)
  )
}

app_result_with_source <- function(result, records) {
  if (!is.data.frame(result) || nrow(result) != nrow(records)) {
    stop("La b\u00FAsqueda devolvi\u00F3 un n\u00FAmero inesperado de filas.", call. = FALSE)
  }
  result <- as.data.frame(result, stringsAsFactors = FALSE)
  result <- result[, !names(result) %in% c("review_reason", "cites_candidate_appendix"),
                   drop = FALSE]
  if (!"review_flag" %in% names(result)) {
    if ("match_assessment" %in% names(result)) {
      review <- !is.na(result$match_assessment) &
        result$match_assessment == "requires_taxonomic_validation"
    } else if (all(c("Orig.Name", "Matched.Name", "matched") %in% names(result))) {
      review <- !is.na(result$matched) & result$matched &
        !is.na(result$Matched.Name) &
        tolower(trimws(result$Orig.Name)) != tolower(trimws(result$Matched.Name))
    } else if ("match_type" %in% names(result)) {
      review <- !is.na(result$match_type) &
        result$match_type %in% c("fuzzy", "genus")
    } else if ("dist" %in% names(result)) {
      review <- !is.na(result$dist) & result$dist > 0
    } else {
      review <- rep(FALSE, nrow(result))
    }
    result$review_flag <- review
  }
  if (!"review_observation" %in% names(result)) {
    result$review_observation <- ifelse(result$review_flag %in% TRUE,
                                        "Necesidad de revisi\u00F3n manual", NA_character_)
  }
  result$source_file <- records$source_file
  result$source_row <- records$source_row
  result
}

app_field_label <- function(fields) {
  labels <- c(
    submitted_name = "Nombre ingresado", name_submitted = "Nombre normalizado",
    accepted_name = "Nombre aceptado", matched_name = "Nombre encontrado",
    scientific_name = "Nombre cient\u00EDfico",
    taxonomic_group = "Grupo taxon\u00F3mico", in_peru = "Registrado en Per\u00FA",
    in_unop = "Estado en UNOP", in_pacheco = "Listado en Pacheco",
    cites_appendix = "Ap\u00E9ndice CITES", ds004_category = "Categor\u00EDa nacional",
    is_threatened = "En D.S. 004 o Libro Rojo", is_endemic = "End\u00E9mico",
    occurrence_status = "Estado de presencia", match_type = "Tipo de coincidencia",
    match_status = "Estado de coincidencia", match_assessment = "Evaluaci\u00F3n",
    ds004_code = "Categor\u00EDa D.S. 004", libro_rojo_code = "Categor\u00EDa Libro Rojo",
    in_ds004 = "En D.S. 004", in_libro_rojo = "En Libro Rojo",
    source_file = "Origen", source_row = "Fila de origen",
    review_flag = "Requiere revisi\u00F3n",
    review_observation = "Observaci\u00F3n",
    english_name = "Nombre en ingl\u00E9s", spanish_name = "Nombre en espa\u00F1ol",
    dist = "Distancia de edici\u00F3n", apendice = "Ap\u00E9ndice CITES",
    is_cites = "Listado en CITES", cites_year = "A\u00F1o CITES",
    order = "Orden", family = "Familia", genus = "G\u00E9nero",
    specific_epithet = "Ep\u00EDteto espec\u00EDfico", class = "Clase",
    `Presence.Status` = "Estado de presencia", `Endemism.Status` = "Condici\u00F3n de endemismo"
  )
  unname(vapply(fields, function(field) {
    if (field %in% names(labels)) labels[[field]] else
      tools::toTitleCase(gsub("[_.]", " ", field))
  }, character(1)))
}
