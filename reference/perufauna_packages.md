# List all core packages in perufauna

Lists the constituent member packages of the perufauna ecosystem.

## Usage

``` r
perufauna_packages(include_self = FALSE)
```

## Arguments

- include_self:

  Include perufauna in the list? Default is `FALSE`.

## Value

Character vector of package names.

## Examples

``` r
perufauna_packages()
#> [1] "avesperu"       "perumammals"    "citesperu"      "perufaunads004"
```
