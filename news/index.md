# Changelog

## safePivot 0.1.1

### Major stability update

- Stabilised the SafePivot R package after a full package-level review
  across R computation, data preparation, htmlwidget rendering, CSS
  layout, tests, export helpers, and documentation.

- Fixed count-fraction aggregators when row or column fields are empty.
  For example, `Count as Fraction of Total` now works when `rows` is
  supplied and `cols` is empty.

- Improved
  [`safe_pivot_compute()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute.md)
  handling of empty cells, observed missing values, zero values, and
  non-zero values. Empty row-column combinations remain `NA`, while
  observed missing values and observed zero values are treated as
  distinct data-quality states.

- Updated `safe_pivot_prepare_data()` so missing-category replacement is
  applied safely to grouping variables while preserving numeric missing
  values for statistical summaries.

### Aggregators and data-quality summaries

- Added and stabilised numeric aggregators including `Count`, `Sum`,
  `Mean`, `Median`, `Min`, `Max`, `Range`, `Q1`, `Q3`, `IQR`,
  `Variance`, `SD`, `SE`, and `CV %`.

- Added and stabilised data-quality aggregators including `N missing`,
  `N non-missing`, `Missing % within Cell`, `Non-missing % within Cell`,
  `N zero`, `N non-zero`, `Zero % within Cell`, and
  `Non-zero % within Cell`.

- Added row, column, and total context percentages for missing,
  non-missing, zero, and non-zero summaries.

- Added and stabilised fraction aggregators including
  `Sum as Fraction of Total`, `Sum as Fraction of Rows`,
  `Sum as Fraction of Columns`, `Count as Fraction of Total`,
  `Count as Fraction of Rows`, and `Count as Fraction of Columns`.

### Renderers and layout

- Added lightweight Plotly renderer support for `Bar Chart`,
  `Stacked Bar Chart`, `Horizontal Bar Chart`,
  `Horizontal Stacked Bar Chart`, `Line Chart`, `Area Chart`,
  `Scatter Chart`, and `Multiple Pie Chart`.

- Kept Treemap out of the core package to keep SafePivot lightweight and
  compatible with the smaller Plotly bundle.

- Improved Plotly chart layout, including plot height, capped plot
  width, centred rendering, visible mode bar, clearer axis labels, tick
  labels, title text, and legend text.

- Improved RStudio Viewer sizing via htmlwidgets sizing policy so
  SafePivot uses more of the available vertical viewer space.

- Added compact table/heatmap mode and full-width chart mode.

### Heatmaps and formatting

- Restored heatmap palette behaviour for `Heatmap`, `Row Heatmap`, and
  `Col Heatmap`.

- Browser-side conditional formatting modes are available for table
  output: `"none"`, `"value"`, `"data_quality"`, and `"both"`.

- Conditional formatting is intentionally disabled for heatmap and
  Plotly chart renderers so SafePivot cell-colour classes do not
  overwrite heatmap palettes or chart rendering.

- Added optional styled Excel export via `openxlsx`, including
  heatmap-style colouring, zero cells, empty cells, and high/low value
  highlighting.

### Shiny and export

- Added Shiny configuration capture so the current drag-and-drop pivot
  state can be used for reproducible export and downstream analysis.

- Added export helpers for CSV, Excel, RDS, and RData outputs.

- Improved
  [`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md)
  so Shiny-style config lists can fall back to sensible defaults when
  fields are empty or missing.

### User interface

- Added data-type badges for draggable variable names in the
  PivotTable.js UI, including numeric, integer, character, factor,
  ordered factor, Date, date-time, logical, list, and object types.

- Increased readability of dropdowns, variable pills, table cells, table
  headers, Plotly labels, and legends.

### Tests and maintenance

- Added regression tests for numeric aggregators, missing-value
  summaries, zero-value summaries, fraction aggregators, Shiny config
  parsing, exports, renderer validation, heatmap palette passing, and
  the original count-fraction bug.

- Cleaned package dependencies by keeping core runtime packages in
  `Imports` and moving optional development, Shiny, pkgdown, vignette,
  and Excel-related packages to `Suggests`.

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

- Added optional styled Excel export via `openxlsx`, including
  heatmap-style colouring, zero cells, empty cells, and high/low value
  highlighting.

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
