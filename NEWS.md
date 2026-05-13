# safePivot 0.1.0

## New features

- Added `safePivot()`, an htmlwidget wrapper around PivotTable.js for drag-and-drop pivot tables in R.
- Added Shiny support through `safePivotOutput()` and `renderSafePivot()`.
- Added robust R-side pivot computation with `safe_pivot_compute()`.
- Added Shiny config-based export support with `safe_pivot_compute_from_config()`.
- Added CSV, Excel, RDS, and RData export helpers.
- Added support for missing-value display and missingness aggregators.
- Added support for R factor-level ordering.
- Added row and column totals on/off options.
- Added readable heatmap palettes and conditional formatting.
- Added grey display for missing cells.
- Added package examples and README quick-start.
- Added pkgdown website.

## Aggregators

- `Count`
- `Count unique`
- `List unique values`
- `N non-missing`
- `N missing`
- `Non-missing %`
- `Missing %`
- `Sum`
- `Mean`
- `Median`
- `Min`
- `Max`
- `Range`
- `Q1`
- `Q3`
- `IQR`
- `Variance`
- `SD`
- `SE`
- `CV %`
- `Sum as Fraction of Total`
- `Sum as Fraction of Rows`
- `Sum as Fraction of Columns`
- `Count as Fraction of Total`
- `Count as Fraction of Rows`
- `Count as Fraction of Columns`

## Related work

- Acknowledges `rpivotTable` as related prior work for bringing PivotTable.js-style drag-and-drop pivot tables to R.
- Acknowledges PivotTable.js by Nicolas Kruchten as the JavaScript pivot-table library underlying the browser-side UI.