# Compute pivot result in R

Compute pivot result in R

## Usage

``` r
safe_pivot_compute(
  data,
  rows = NULL,
  cols = NULL,
  vals = NULL,
  aggregator = "Median",
  missing_label = "(Missing)",
  show_missing_category = TRUE
)
```

## Arguments

- data:

  A data frame.

- rows:

  Character vector of row variables.

- cols:

  Character vector of column variables.

- vals:

  Character vector of value variables.

- aggregator:

  Aggregator name.

- missing_label:

  Label for missing categorical values.

- show_missing_category:

  Whether missing categorical values are shown as a level.

## Value

A list with `long`, `wide`, and `config`.

## Details

safePivot distinguishes empty pivot cells, observed missing values, and
observed numeric zero values. An empty pivot cell means no records exist
for that row-column combination and is returned as `NA` after widening.
An observed missing value means a record exists but the selected value
is `NA`; this contributes to `N missing`. Zero and non-zero aggregators
use finite numeric non-missing values only.

Missing and non-missing percentages use observed record counts as
denominators. Zero and non-zero percentages use numeric non-missing
counts as denominators. Sum fraction aggregators use numeric sums as
denominators, while count fraction aggregators use observed record
counts as denominators.
