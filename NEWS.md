## perufauna 0.1.0

* Raised the default bird distance to 0.15 and CITES/D.S. 004 edit limit to 2. Approximate matches carry `review_flag` and a manual-review observation. The integrated CITES column shows the suggested appendix while marking candidates that need taxonomic validation.
* Added `run_perufauna_app()`, `pf_app()`, and `perufauna_app()` with five interactive views, shared file and text input, background and synchronous fallback queries, result review, and CSV/XLSX downloads.
* Modernized the Shiny application interface with a compact, fold-optimized navbar layout, integrated query toolbar, streamlined inputs, and KPI summary tiles.
* Added standalone deployment entry points via root `app.R` and `system.file("app", package = "perufauna")` / `system.file("shiny", package = "perufauna")`.
* Added automatic detection of comma (`,`) and semicolon (`;`) delimiters for CSV files exported from Spanish/Latin American Excel versions.
* Added full Spanish localization to interactive DT data tables.
* Added configurable request limits via `max_request_size` and option forwarding to `shiny::shinyApp()`.

* Initial release. Matching separates the relative bird distance from
  integer edit distances used by CITES and D.S. 004.
* CITES inclusion alone no longer establishes occurrence in Peru. Lookup
  failures report the affected source instead of silently returning negatives.

* **`pf_match()`**: Harmonized cross-database biodiversity query across four specialized Peruvian backbones:
  * `avesperu`: UNOP Bird Checklist of Peru, reporting qualitative status (`"Residente"`, `"Endémico"`, `"Divagante"`, `"Migratorio"`, etc.).
  * `perumammals`: Pacheco et al. (2021) Peru Mammals Checklist.
  * `citesperu`: MINAM Official CITES Appendices for Peru.
  * `perufaunads004`: D.S. No. 004-2014-MINAGRI & SERFOR Threatened Fauna Red Book.
* **`pf_status()`**: Structured, reproducible `tibble` summarizing taxonomic group, occurrence/residency status, CITES appendix, and D.S. 004 threat status.
* **Metapackage Orchestration**:
  * `perufauna_attach()`: Attach ecosystem packages with clean startup messages.
  * `perufauna_conflicts()`: S3 conflict detection comparing memory pointers.
  * `perufauna_sitrep()`: Situation report for runtime diagnostics.
  * `perufauna_deps()`: Ecosystem dependency installation and version overview.
  * `perufauna_packages()`: Return names of core packages.
  * `perufauna_logo()`: Render ASCII banner.
