# Write pivot result to CSV

Write pivot result to CSV

## Usage

``` r
safe_pivot_write_csv(pivot_result, file, which = c("wide", "long"))
```

## Arguments

- pivot_result:

  A result object returned by
  [`safe_pivot_compute()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute.md).

- file:

  Output file path.

- which:

  Which result table to write: `"wide"` or `"long"`.

## Value

Invisibly returns `file`.
