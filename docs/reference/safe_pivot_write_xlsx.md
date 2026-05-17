# Write a safePivot result to an Excel workbook

Write a safePivot result to an Excel workbook

## Usage

``` r
safe_pivot_write_xlsx(
  x,
  file,
  sheet = "safePivot",
  include_heatmap = TRUE,
  include_conditional_format = TRUE,
  conditional_format_mode = "both",
  heatmap_palette = "blue_white_red",
  high_threshold = 0.85,
  low_threshold = 0.15,
  empty_fill = "#E5E7EB",
  zero_fill = "#FEF3C7",
  high_fill = "#FFF7ED",
  low_fill = "#EFF6FF",
  overwrite = TRUE
)
```

## Arguments

- x:

  A result from
  [`safe_pivot_compute()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute.md)
  /
  [`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md),
  or a data frame.

- file:

  Output `.xlsx` file path.

- sheet:

  Worksheet name.

- include_heatmap:

  Whether to export heatmap-style cell fills.

- include_conditional_format:

  Whether to export conditional formatting styles.

- conditional_format_mode:

  One of `"none"`, `"value"`, `"data_quality"`, or `"both"`.

- heatmap_palette:

  Heatmap palette. One of `"blue"`, `"yellow_orange"`, `"green"`,
  `"green_red"`, or `"blue_white_red"`.

- high_threshold:

  Relative high-value threshold from 0 to 1.

- low_threshold:

  Relative low-value threshold from 0 to 1.

- empty_fill:

  Fill colour for empty / unavailable cells.

- zero_fill:

  Fill colour for displayed zero cells.

- high_fill:

  Fill colour for high-value cells.

- low_fill:

  Fill colour for low-value cells.

- overwrite:

  Whether to overwrite an existing file.

## Value

Invisibly returns `file`.
