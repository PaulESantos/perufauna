# Changelog

## perufauna 0.1.0

- First CRAN release. Matching now separates the relative bird distance
  from integer edit distances used by CITES and D.S. 004.

- CITES inclusion alone no longer establishes occurrence in Peru. Lookup
  failures report the affected source instead of silently returning
  negatives.

- **[`pf_match()`](https://paulesantos.github.io/perufauna/reference/pf_match.md)**:
  Harmonized cross-database biodiversity query across four specialized
  Peruvian backbones:

  - `avesperu`: UNOP Bird Checklist of Peru, reporting qualitative
    status (`"Residente"`, `"Endémico"`, `"Divagante"`, `"Migratorio"`,
    etc.).
  - `perumammals`: Pacheco et al. (2021) Peru Mammals Checklist.
  - `citesperu`: MINAM Official CITES Appendices for Peru.
  - `perufaunads004`: D.S. No. 004-2014-MINAGRI & SERFOR Threatened
    Fauna Red Book.

- **[`pf_status()`](https://paulesantos.github.io/perufauna/reference/pf_status.md)**:
  Structured, reproducible `tibble` summarizing taxonomic group,
  occurrence/residency status, CITES appendix, and D.S. 004 threat
  status.

- **Metapackage Orchestration**:

  - [`perufauna_attach()`](https://paulesantos.github.io/perufauna/reference/perufauna_attach.md):
    Attach ecosystem packages with clean startup messages.
  - [`perufauna_conflicts()`](https://paulesantos.github.io/perufauna/reference/perufauna_conflicts.md):
    S3 conflict detection comparing memory pointers.
  - [`perufauna_sitrep()`](https://paulesantos.github.io/perufauna/reference/perufauna_sitrep.md):
    Situation report for runtime diagnostics.
  - [`perufauna_deps()`](https://paulesantos.github.io/perufauna/reference/perufauna_deps.md):
    Ecosystem dependency installation and version overview.
  - [`perufauna_packages()`](https://paulesantos.github.io/perufauna/reference/perufauna_packages.md):
    Return names of core packages.
  - [`perufauna_logo()`](https://paulesantos.github.io/perufauna/reference/perufauna_logo.md):
    Render ASCII banner.
