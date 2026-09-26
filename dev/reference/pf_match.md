# Cross-Referenced Taxonomic and Conservation Matching for Peruvian Fauna

Integrates and cross-references scientific names across all four
specialized Peruvian biodiversity databases:

- `avesperu`: UNOP Bird Checklist of Peru.

- `perumammals`: Pacheco et al. (2021) Peru Mammals Checklist.

- `citesperu`: MINAM Official CITES Appendices for Peru.

- `perufaunads004`: D.S. No. 004-2014-MINAGRI & SERFOR Threatened Fauna
  Red Book.

## Usage

``` r
pf_match(splist, max_distance = 0.1, ...)
```

## Arguments

- splist:

  Character vector of scientific names to validate, or a `data.frame`
  containing a column with species names.

- max_distance:

  Numeric. Maximum string distance allowed for fuzzy matching (default:
  0.1).

- ...:

  Additional arguments passed to underlying matching engines.

## Value

A [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
with harmonized cross-database columns:

- `submitted_name`: The raw input name.

- `accepted_name`: Validated/accepted scientific binomial name.

- `taxonomic_group`: Taxonomic class/group ("Aves", "Mammalia",
  "Reptilia", "Amphibia", etc.).

- `in_peru`: Logical. Confirmed presence in Peru via UNOP, Pacheco, or
  D.S. 004.

- `in_unop`: Character. UNOP bird status ("Residente", "Endémico",
  "Divagante", "Migratorio", "Introducido", "No confirmado", or NA).

- `in_pacheco`: Logical. Listed in Pacheco et al. (2021) Peru Mammals.

- `cites_appendix`: CITES status ("I", "II", "III", or NA).

- `ds004_category`: National threat category ("CR", "EN", "VU", "NT", or
  NA).

- `is_threatened`: Logical. Listed under national threat (D.S. 004 or
  Libro Rojo).

- `is_endemic`: Logical. Endemic to Peru (based on UNOP or Pacheco).

## Examples

``` r
# \donttest{
species <- c("Panthera onca", "Vultur gryphus", "Tremarctos ornatus", "Homo sapiens")
pf_match(species)
#> # A tibble: 4 × 10
#>   submitted_name     accepted_name    taxonomic_group in_peru in_unop in_pacheco
#>   <chr>              <chr>            <chr>           <lgl>   <chr>   <lgl>     
#> 1 Panthera onca      Panthera onca    Mammalia        TRUE    NA      TRUE      
#> 2 Vultur gryphus     Vultur gryphus   Aves            TRUE    Reside… FALSE     
#> 3 Tremarctos ornatus Tremarctos orna… Mammalia        TRUE    NA      TRUE      
#> 4 Homo sapiens       Homo sapiens     NA              FALSE   NA      FALSE     
#> # ℹ 4 more variables: cites_appendix <chr>, ds004_category <chr>,
#> #   is_threatened <lgl>, is_endemic <lgl>
# }
```
