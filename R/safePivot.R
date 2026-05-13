
# Internal dependency helper
safePivot_dependencies <- function() {
  list(
    jquerylib::jquery_core(3),
    
    htmltools::htmlDependency(
      name = "jquery-ui",
      version = "1.14.2",
      src = c(file = system.file(
        "htmlwidgets/lib/jquery-ui",
        package = "safePivot"
      )),
      script = "jquery-ui.min.js",
      stylesheet = "jquery-ui.min.css"
    ),
    
    htmltools::htmlDependency(
      name = "pivottable",
      version = "2.23.0",
      src = c(file = system.file(
        "htmlwidgets/lib/pivottable",
        package = "safePivot"
      )),
      script = "pivot.min.js",
      stylesheet = "pivot.min.css"
    ),
    
    htmltools::htmlDependency(
      name = "safePivot-style",
      version = "0.0.0.9000",
      src = c(file = system.file(
        "htmlwidgets/lib/safePivot",
        package = "safePivot"
      )),
      stylesheet = "safePivot.css"
    )
  )
}

htmltools::htmlDependency(
  name = "safePivot-style",
  version = "0.0.0.9000",
  src = c(file = system.file(
    "htmlwidgets/lib/safePivot",
    package = "safePivot"
  )),
  stylesheet = "safePivot.css"
)

#' Safe drag-and-drop pivot table htmlwidget
#'
#' Create an interactive drag-and-drop pivot table using PivotTable.js,
#' with safer numeric aggregators, missing-value handling, factor-level
#' ordering, heatmap renderers, conditional formatting, and Shiny support.
#'
#' @param data A data frame.
#' @param rows Character vector of initial row variables.
#' @param cols Character vector of initial column variables.
#' @param vals Character vector of initial value variable. In v0.1, use one value variable.
#' @param aggregator Initial aggregator name.
#' @param renderer Initial renderer name. Supported values are `"Table"`,
#'   `"Heatmap"`, `"Row Heatmap"`, and `"Col Heatmap"`.
#' @param missing_label Label used for missing categorical values.
#' @param show_missing_category Whether missing categorical values should be shown as a category.
#' @param respect_factor_order Whether R factor levels should control display order.
#' @param numeric_digits Number of digits used for displayed numeric values.
#' @param show_row_totals Whether to show row totals in table renderers.
#' @param show_col_totals Whether to show column totals in table renderers.
#' @param heatmap_palette Heatmap palette. One of `"blue"`, `"yellow_orange"`,
#'   `"green"`, `"blue_white_red"`, or `"green_red"`.
#' @param conditional_format Whether to apply additional conditional formatting
#'   classes to numeric pivot cells.
#' @param high_threshold Relative threshold for high-value cell formatting.
#'   Values are scaled from 0 to 1 within the displayed pivot table.
#' @param low_threshold Relative threshold for low-value cell formatting.
#'   Values are scaled from 0 to 1 within the displayed pivot table.
#' @param max_rows Maximum number of rows allowed for browser-side pivoting.
#' @param width Widget width.
#' @param height Widget height.
#'
#' @return An htmlwidget object.
#'
#' @examples
#' if (interactive()) {
#'   safePivot(
#'     iris,
#'     rows = "Species",
#'     vals = "Sepal.Length",
#'     aggregator = "Median",
#'     renderer = "Heatmap"
#'   )
#' }
#'
#' @export

safePivot <- function(
    data,
    rows = NULL,
    cols = NULL,
    vals = NULL,
    aggregator = "Median",
    renderer = "Table",
    missing_label = "(Missing)",
    show_missing_category = TRUE,
    respect_factor_order = TRUE,
    numeric_digits = 3,
    show_row_totals = TRUE,
    show_col_totals = TRUE,
    heatmap_palette = "blue",
    conditional_format = TRUE,
    high_threshold = 0.85,
    low_threshold = 0.15,
    max_rows = 50000,
    width = "100%",
    height = 600
) {
  
  stopifnot(is.data.frame(data))
  
  if (nrow(data) > max_rows) {
    stop(
      "Too many rows for browser-side pivot table. ",
      "Please filter or summarise first.",
      call. = FALSE
    )
  }
  
  allowed_renderers <- c(
    "Table",
    "Heatmap",
    "Row Heatmap",
    "Col Heatmap"
  )
  
  allowed_aggregators <- c(
    "Count",
    "Count unique",
    "List unique values",
    "N non-missing",
    "N missing",
    "Non-missing %",
    "Missing %",
    "Mean",
    "Median",
    "Sum",
    "Sum as Fraction of Total",
    "Sum as Fraction of Rows",
    "Sum as Fraction of Columns",
    "Count as Fraction of Total",
    "Count as Fraction of Rows",
    "Count as Fraction of Columns",
    "Min",
    "Max",
    "Range",
    "Variance",
    "SD",
    "SE",
    "CV %",
    "Q1",
    "Q3",
    "IQR"
  )
  
  if (!renderer %in% allowed_renderers) {
    stop("Unsupported renderer: ", renderer, call. = FALSE)
  }
  
  if (!aggregator %in% allowed_aggregators) {
    stop("Unsupported aggregator: ", aggregator, call. = FALSE)
  }
  
  all_vars <- names(data)
  
  check_vars <- function(x, arg) {
    if (is.null(x)) return(invisible(TRUE))
    bad <- setdiff(x, all_vars)
    if (length(bad) > 0) {
      stop(arg, " contains unknown variable(s): ", paste(bad, collapse = ", "), call. = FALSE)
    }
  }
  
  check_vars(rows, "rows")
  check_vars(cols, "cols")
  check_vars(vals, "vals")
  
  factor_levels <- safe_pivot_factor_levels(data)
  
  data <- safe_pivot_prepare_data(
    data = data,
    missing_label = missing_label,
    show_missing_category = show_missing_category
  )
 
  allowed_palettes <- c(
    "blue",
    "yellow_orange",
    "green",
    "blue_white_red",
    "green_red"
  )
  
  if (!heatmap_palette %in% allowed_palettes) {
    stop(
      "Unsupported heatmap_palette: ", heatmap_palette,
      ". Supported values are: ",
      paste(allowed_palettes, collapse = ", "),
      call. = FALSE
    )
  }
  
  if (!is.numeric(high_threshold) || length(high_threshold) != 1 ||
      is.na(high_threshold) || high_threshold < 0 || high_threshold > 1) {
    stop("`high_threshold` must be a single number between 0 and 1.", call. = FALSE)
  }
  
  if (!is.numeric(low_threshold) || length(low_threshold) != 1 ||
      is.na(low_threshold) || low_threshold < 0 || low_threshold > 1) {
    stop("`low_threshold` must be a single number between 0 and 1.", call. = FALSE)
  }
  
  if (low_threshold >= high_threshold) {
    stop("`low_threshold` must be smaller than `high_threshold`.", call. = FALSE)
  }
  
  x <- list(
    data = data,
    rows = rows %||% character(),
    cols = cols %||% character(),
    vals = vals %||% character(),
    aggregator = aggregator,
    renderer = renderer,
    missing_label = missing_label,
    factor_levels = factor_levels,
    respect_factor_order = respect_factor_order,
    numeric_digits = numeric_digits,
    show_row_totals = isTRUE(show_row_totals),
    show_col_totals = isTRUE(show_col_totals),
    heatmap_palette = heatmap_palette,
    conditional_format = isTRUE(conditional_format),
    high_threshold = high_threshold,
    low_threshold = low_threshold,
    allowed_renderers = allowed_renderers,
    allowed_aggregators = allowed_aggregators
  )

  htmlwidgets::createWidget(
    name = "safePivot",
    x = x,
    width = width,
    height = height,
    package = "safePivot",
    dependencies = safePivot_dependencies()
  )
  
}
