# Using safePivot in Shiny

## Using safePivot in Shiny

`safePivot` provides a drag-and-drop pivot-table widget for Shiny
applications.

The main Shiny workflow is:

1.  display the widget with
    [`safePivotOutput()`](https://dongwenluo.github.io/safePivot/reference/safePivotOutput.md);
2.  render it with
    [`renderSafePivot()`](https://dongwenluo.github.io/safePivot/reference/renderSafePivot.md);
3.  capture the current pivot configuration through
    `input$<outputId>_config`;
4.  recompute the current pivot result in R with
    [`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md);
5.  export the result with CSV, Excel, RDS, or RData helpers.

This design avoids scraping the HTML table from the browser. Instead,
the browser sends the pivot configuration back to Shiny, and R
recomputes the exported table from the original data.

## Minimal Shiny app

``` r

library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot Shiny example"),

  safePivotOutput("pivot", height = "650px")
)

server <- function(input, output, session) {
  output$pivot <- renderSafePivot({
    safePivot(
      iris,
      rows = "Species",
      vals = "Sepal.Length",
      aggregator = "Median",
      renderer = "Table"
    )
  })
}

shinyApp(ui, server)
```

## Heatmap example

`safePivot` supports heatmap renderers and readable colour palettes.

``` r

library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot heatmap example"),

  safePivotOutput("pivot", height = "650px")
)

server <- function(input, output, session) {
  output$pivot <- renderSafePivot({
    safePivot(
      mtcars,
      rows = "cyl",
      cols = "gear",
      vals = "mpg",
      aggregator = "Mean",
      renderer = "Heatmap",
      heatmap_palette = "blue",
      conditional_format = TRUE,
      show_row_totals = TRUE,
      show_col_totals = TRUE
    )
  })
}

shinyApp(ui, server)
```

Available heatmap palettes include:

- `"blue"`
- `"yellow_orange"`
- `"green"`
- `"blue_white_red"`
- `"green_red"`

The default `"blue"` palette is designed to keep black text readable.

## Export current pivot table

The key helper for Shiny export is
[`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md).

The widget sends the current drag-and-drop state to Shiny as:

``` r

input$pivot_config
```

where `pivot` is the output ID used in:

``` r

safePivotOutput("pivot")
```

The following app exports the current pivot result to CSV, Excel, RDS,
and RData.

``` r

library(shiny)
library(safePivot)

ui <- fluidPage(
  titlePanel("safePivot export example"),

  safePivotOutput("pivot", height = "650px"),

  hr(),

  fluidRow(
    column(3, downloadButton("download_csv", "Download CSV")),
    column(3, downloadButton("download_xlsx", "Download Excel")),
    column(3, downloadButton("download_rds", "Download RDS")),
    column(3, downloadButton("download_rdata", "Download RData"))
  ),

  hr(),

  h4("Current pivot configuration"),
  verbatimTextOutput("pivot_config")
)

server <- function(input, output, session) {
  dat <- reactive({
    iris
  })

  output$pivot <- renderSafePivot({
    safePivot(
      dat(),
      rows = "Species",
      vals = "Sepal.Length",
      aggregator = "Median",
      renderer = "Table"
    )
  })

  output$pivot_config <- renderPrint({
    input$pivot_config
  })

  current_pivot <- reactive({
    safe_pivot_compute_from_config(
      data = dat(),
      config = input$pivot_config,
      default_rows = "Species",
      default_cols = NULL,
      default_vals = "Sepal.Length",
      default_aggregator = "Median"
    )
  })

  output$download_csv <- downloadHandler(
    filename = function() {
      "safePivot_result.csv"
    },
    content = function(file) {
      safe_pivot_write_csv(
        current_pivot(),
        file,
        which = "wide"
      )
    }
  )

  output$download_xlsx <- downloadHandler(
    filename = function() {
      "safePivot_result.xlsx"
    },
    content = function(file) {
      safe_pivot_write_xlsx(
        current_pivot(),
        file
      )
    }
  )

  output$download_rds <- downloadHandler(
    filename = function() {
      "safePivot_result.rds"
    },
    content = function(file) {
      safe_pivot_write_rds(
        current_pivot(),
        file
      )
    }
  )

  output$download_rdata <- downloadHandler(
    filename = function() {
      "safePivot_result.RData"
    },
    content = function(file) {
      safe_pivot_write_rdata(
        current_pivot(),
        file,
        object_name = "safePivot_result"
      )
    }
  )
}

shinyApp(ui, server)
```

## Why use config-based export?

A browser pivot table is interactive. Users can move variables between
rows, columns, and values, and they can change the aggregator.

Instead of trying to parse the displayed HTML table, `safePivot`
captures the current configuration and recomputes the result in R.

This gives three advantages:

- exported results are generated from the original data;
- export logic is testable in R;
- Shiny apps do not need custom HTML-scraping code.

## Row and column totals

You can control totals from R:

``` r

safePivot(
  mtcars,
  rows = "cyl",
  cols = "gear",
  vals = "mpg",
  aggregator = "Mean",
  renderer = "Heatmap",
  show_row_totals = TRUE,
  show_col_totals = FALSE
)
```

## Missing values

Missing categorical values can be displayed as a labelled category.

``` r

iris_missing <- iris
iris_missing$Group <- iris_missing$Species
iris_missing$Group[c(1, 5, 10)] <- NA
iris_missing$Sepal.Length[c(2, 6, 11)] <- NA

safePivot(
  iris_missing,
  rows = "Group",
  vals = "Sepal.Length",
  aggregator = "N missing",
  renderer = "Table",
  missing_label = "(Missing)",
  show_missing_category = TRUE
)
```

Missing cells in the pivot display are styled as neutral grey.

## Factor order

If a variable is an R factor, `safePivot` can respect the factor-level
order.

``` r

iris2 <- iris
iris2$Species <- factor(
  iris2$Species,
  levels = c("virginica", "versicolor", "setosa")
)

safePivot(
  iris2,
  rows = "Species",
  vals = "Sepal.Length",
  aggregator = "Median",
  renderer = "Table",
  respect_factor_order = TRUE
)
```

## Common aggregators

Useful aggregators include:

``` r

c(
  "Count",
  "Count unique",
  "List unique values",
  "N non-missing",
  "N missing",
  "Non-missing %",
  "Missing %",
  "Sum",
  "Mean",
  "Median",
  "Min",
  "Max",
  "Range",
  "Q1",
  "Q3",
  "IQR",
  "Variance",
  "SD",
  "SE",
  "CV %",
  "Sum as Fraction of Total",
  "Sum as Fraction of Rows",
  "Sum as Fraction of Columns",
  "Count as Fraction of Total",
  "Count as Fraction of Rows",
  "Count as Fraction of Columns"
)
```

## Notes for larger data

`safePivot` sends data to the browser for interactive pivoting. For
large data, filter or aggregate first before sending data to
[`safePivot()`](https://dongwenluo.github.io/safePivot/reference/safePivot.md).

A practical workflow is:

1.  filter data in Shiny;
2.  send the reduced data to
    [`safePivot()`](https://dongwenluo.github.io/safePivot/reference/safePivot.md);
3.  use
    [`safe_pivot_compute_from_config()`](https://dongwenluo.github.io/safePivot/reference/safe_pivot_compute_from_config.md)
    for export;
4.  export only the current pivot result.
