app_records <- function(text = "", file = NULL, column = NULL) {
  lines <- if (is.null(text) || is.na(text) || !nzchar(text)) character() else
    trimws(strsplit(text, "\r\n|\n|\r")[[1]])
  nonempty <- which(nzchar(lines))
  pasted <- data.frame(
    submitted_name = lines[nonempty],
    source_file = rep("Texto pegado", length(nonempty)),
    source_row = nonempty,
    stringsAsFactors = FALSE
  )
  if (is.null(file)) return(pasted)
  if (is.null(column) || !column %in% names(file$data)) {
    stop("Selecciona la columna que contiene los nombres científicos.", call. = FALSE)
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
  } else {
    reader <- if (ext == "csv") utils::read.csv else utils::read.delim
    data <- reader(path, header = header, check.names = FALSE, stringsAsFactors = FALSE,
                   fileEncoding = "UTF-8-BOM", na.strings = c("NA"))
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
  if (!nrow(records)) stop("Ingresa al menos un nombre científico.", call. = FALSE)
  if (nrow(records) > 10000L) stop("El máximo es de 10 000 nombres por consulta.", call. = FALSE)
  if (any(nchar(records$submitted_name) > 200L, na.rm = TRUE)) {
    stop("Cada nombre debe tener como máximo 200 caracteres.", call. = FALSE)
  }
  invisible(records)
}

app_query <- function(module, names, settings) {
  switch(module,
    integrada = if (identical(settings$view, "resumen")) {
      pf_status(names, max_distance = settings$bird_distance,
                max_edit_distance = settings$edit_distance)
    } else {
      pf_match(names, max_distance = settings$bird_distance,
               max_edit_distance = settings$edit_distance)
    },
    aves = {
      result <- avesperu::search_avesperu(
        names, max_distance = settings$distance,
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
    cites = citesperu::cites_match(
      names, taxon = settings$taxon, edition = settings$edition,
      max_dist = settings$distance, allow_synonyms = settings$synonyms,
      genus_fallback = settings$genus, output = "standard"
    ),
    amenaza = perufaunads004::fauna_matching(
      names, max_distance = settings$distance, fuzzy = settings$fuzzy,
      genus_match = settings$genus, group = if (nzchar(settings$group)) settings$group else NULL
    ),
    stop("Módulo de consulta desconocido.", call. = FALSE)
  )
}

app_result_with_source <- function(result, records) {
  if (!is.data.frame(result) || nrow(result) != nrow(records)) {
    stop("La búsqueda devolvió un número inesperado de filas.", call. = FALSE)
  }
  result <- as.data.frame(result, stringsAsFactors = FALSE)
  result$source_file <- records$source_file
  result$source_row <- records$source_row
  result
}

app_field_label <- function(fields) {
  labels <- c(
    submitted_name = "Nombre ingresado", name_submitted = "Nombre normalizado",
    accepted_name = "Nombre aceptado", matched_name = "Nombre encontrado",
    taxonomic_group = "Grupo taxonómico", in_peru = "Registrado en Perú",
    in_unop = "Estado en UNOP", in_pacheco = "Listado en Pacheco",
    cites_appendix = "Apéndice CITES", ds004_category = "Categoría nacional",
    is_threatened = "En D.S. 004 o Libro Rojo", is_endemic = "Endémico",
    occurrence_status = "Estado de presencia", match_type = "Tipo de coincidencia",
    match_status = "Estado de coincidencia", match_assessment = "Evaluación",
    ds004_code = "Categoría D.S. 004", libro_rojo_code = "Categoría Libro Rojo",
    in_ds004 = "En D.S. 004", in_libro_rojo = "En Libro Rojo",
    source_file = "Origen", source_row = "Fila de origen",
    review_flag = "Requiere revisión", review_reason = "Motivo de revisión"
  )
  unname(vapply(fields, function(field) {
    if (field %in% names(labels)) labels[[field]] else
      tools::toTitleCase(gsub("[_.]", " ", field))
  }, character(1)))
}
