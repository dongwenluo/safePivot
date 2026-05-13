# Write pivot result to RData

Write pivot result to RData

## Usage

``` r
safe_pivot_write_rdata(pivot_result, file, object_name = "pivot_result")
```

## Arguments

- pivot_result:

  A result object returned by
  [`safe_pivot_compute()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute.md).

- file:

  Output `.RData` file path.

- object_name:

  Name of the object saved inside the `.RData` file.

## Value

Invisibly returns `file`.
