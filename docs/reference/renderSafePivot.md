# Shiny render function for safePivot

Shiny render function for safePivot

## Usage

``` r
renderSafePivot(expr, env = parent.frame(), quoted = FALSE)
```

## Arguments

- expr:

  An expression that returns a safePivot widget.

- env:

  Environment in which to evaluate `expr`.

- quoted:

  Whether `expr` is already quoted.

## Value

A Shiny render function.
