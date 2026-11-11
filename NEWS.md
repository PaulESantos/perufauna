## perufauna (development version)

* Added `run_perufauna_app()` with five interactive views, shared file and text
  input, background queries, result review, and CSV/XLSX downloads.

## perufauna 0.1.0

* First CRAN release. Matching now separates the relative bird distance from
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
