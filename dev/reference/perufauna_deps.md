# List all perufauna dependencies and versions

List all perufauna dependencies and versions

## Usage

``` r
perufauna_deps()
```

## Value

A [`tibble::tibble`](https://tibble.tidyverse.org/reference/tibble.html)
with package names, installed status, and local versions.

## Examples

``` r
perufauna_deps()
#> # A tibble: 4 × 3
#>   package        installed local_version
#>   <chr>          <lgl>     <chr>        
#> 1 avesperu       TRUE      0.1.1        
#> 2 perumammals    TRUE      0.0.0.2      
#> 3 citesperu      TRUE      0.1.0        
#> 4 perufaunads004 TRUE      0.1.0        
```
