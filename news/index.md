# Changelog

## safePivot 0.1.0.9000

### Aggregators

- Added explicit missing and non-missing aggregators, including
  within-cell, row, column, and total percentages.

- Added zero and non-zero aggregators, including within-cell, row,
  column, and total percentages.

- Clarified aggregation semantics: empty pivot cells are treated as no
  data and remain `NA`; observed `NA` values are counted as missing;
  numeric zero values are counted separately from missing values.

- Reworked `Sum as Fraction of Total`, `Sum as Fraction of Rows`,
  `Sum as Fraction of Columns`, `Count as Fraction of Total`,
  `Count as Fraction of Rows`, and `Count as Fraction of Columns` so
  that denominators are calculated from explicit cell, row, column, and
  total summaries.

### Formatting and export

- Added browser-side conditional formatting modes: `"none"`, `"value"`,
  `"data_quality"`, and `"both"`.

- Added styled Excel export for heatmap-style colouring, zero cells,
  empty cells, and high/low value highlighting.

- Added data-type badges for draggable variable names in the
  PivotTable.js UI, including numeric, integer, character, factor,
  ordered factor, Date, date-time, logical, list, and object types.

### Documentation

- Expanded README and Shiny vignette documentation for aggregation
  rules, config-based export, styled Excel export, conditional
  formatting, and data-type badges.

### Tests

- Added tests for sum fractions, count fractions, missing-value
  percentages, zero-value percentages, empty-cell behaviour, and XLSX
  export options.

## safePivot 0.1.0

### New features

- Added
  [`safePivot()`](https://dongwenluo.github.io/safePivot/reference/safePivot.md),
  an htmlwidget wrapper around PivotTable.js for drag-and-drop pivot
  tables in R.

- Added Shiny support through
  [`safePivotOutput()`](https://dongwenluo.github.io/safePivot/reference/safePivotOutput.md)
  and
  [`renderSafePivot()`](https://dongwenluo.github.io/safePivot/reference/renderSafePivot.md).

- Added R-side pivot computation with
  [`safe_pivot_compute()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute.md).

- Added Shiny config-based export support with
  [`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md).

- Added CSV, Excel, RDS, and RData export helpers.

- Added support for missing-value display and missingness aggregators.

- Added support for R factor-level ordering.

- Added row and column totals on/off options.

- Added heatmap palettes and browser-side conditional formatting.

- Added package examples, README quick-start, and pkgdown website.

### Initial aggregators

- Added count, unique-value, missingness, numeric-summary, distribution,
  and fraction aggregators, including `Count`, `Count unique`,
  `List unique values`, `N non-missing`, `N missing`, `Sum`, `Mean`,
  `Median`, `Min`, `Max`, `Range`, `Q1`, `Q3`, `IQR`, `Variance`, `SD`,
  `SE`, `CV %`, `Sum as Fraction of Total`, `Sum as Fraction of Rows`,
  `Sum as Fraction of Columns`, `Count as Fraction of Total`,
  `Count as Fraction of Rows`, and `Count as Fraction of Columns`.

### Related work

- Acknowledges `rpivotTable` as related prior work for bringing
  PivotTable.js-style drag-and-drop pivot tables to R.

- Acknowledges PivotTable.js by Nicolas Kruchten as the JavaScript
  pivot-table library underlying the browser-side UI.
