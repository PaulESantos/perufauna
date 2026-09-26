# Conflicts between perufauna and other packages

Lists all function name conflicts between packages in the perufauna
ecosystem and other loaded packages on the search path.

## Usage

``` r
perufauna_conflicts(only = NULL)
```

## Arguments

- only:

  Optional character vector to restrict conflict checks to specific
  packages.

## Value

An object of class `perufauna_conflicts`.

## Examples

``` r
# \donttest{
perufauna_conflicts()
#> 
# }
```
