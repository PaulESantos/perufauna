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
with 6 atomized columns:

- `submitted_name`: The raw input name.

- `accepted_name`: Validated/accepted scientific binomial name.

- `taxonomic_group`: Taxonomic class/group ("Aves", "Mammalia", etc., or
  NA).

- `occurrence_status`: Occurrence or residency status in Peru
  ("Residente", "Endémico", "Divagante", "Migratorio", etc., or NA).

- `cites_appendix`: CITES appendix ("I", "II", "III", or NA).

- `ds004_category`: National threat category under D.S. 004-2014-MINAGRI
  ("CR", "EN", "VU", "NT", or NA).

## Examples

``` r
# \donttest{
pf_status(c("Panthera onca", "Vultur gryphus", "Tremarctos ornatus"))
#> # A tibble: 3 × 6
#>   submitted_name  accepted_name taxonomic_group occurrence_status cites_appendix
#>   <chr>           <chr>         <chr>           <chr>             <chr>         
#> 1 Panthera onca   Panthera onca Mammalia        Residente         I             
#> 2 Vultur gryphus  Vultur gryph… Aves            Residente         I             
#> 3 Tremarctos orn… Tremarctos o… Mammalia        Residente         I             
#> # ℹ 1 more variable: ds004_category <chr>
# }
```
