# Quick Status Summary for Peruvian Fauna

Provides an immediate formatted and atomized summary table of taxonomic
group, occurrence/residency status in Peru, CITES appendix, and national
threat category (D.S. 004-2014-MINAGRI) for each species.

## Usage

``` r
pf_status(splist, ...)
```

## Arguments

- splist:

  Character vector of species names, or a `data.frame` containing
  species names.

- ...:

  Arguments forwarded to
  [`pf_match`](https://paulesantos.github.io/perufauna/reference/pf_match.md).

## Value

A [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
with summary and review columns:

- `submitted_name`: The raw input name.

- `accepted_name`: Name returned by the matching sources; an approximate
  correction is a candidate until manually reviewed.

- `taxonomic_group`: Taxonomic class/group ("Aves", "Mammalia", etc., or
  NA).

- `occurrence_status`: UNOP status for birds, "Endémico" for endemic
  mammals, "Registrado en Perú" for other taxa listed in a Peruvian
  reference, or NA when occurrence is not established.

- `cites_appendix`: CITES appendix ("I", "II", "III", or NA), including
  approximate candidates marked for manual review.

- `ds004_category`: National threat category under D.S. 004-2014-MINAGRI
  ("CR", "EN", "VU", "NT", or NA).

- `review_flag`: Whether an approximate match needs manual review.

- `review_observation`: "Necesidad de revisión manual" when additional
  review is needed; otherwise NA.

## Examples

``` r
pf_status(c("Panthera onca", "Vultur gryphus", "Tremarctos ornatus"))
#> # A tibble: 3 × 8
#>   submitted_name  accepted_name taxonomic_group occurrence_status cites_appendix
#>   <chr>           <chr>         <chr>           <chr>             <chr>         
#> 1 Panthera onca   Panthera onca Mammalia        Registrado en Pe… I             
#> 2 Vultur gryphus  Vultur gryph… Aves            Residente         I             
#> 3 Tremarctos orn… Tremarctos o… Mammalia        Registrado en Pe… I             
#> # ℹ 3 more variables: ds004_category <chr>, review_observation <chr>,
#> #   review_flag <lgl>
```
