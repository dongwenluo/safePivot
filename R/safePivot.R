# Internal dependency helper
safePivot_dependencies <- function() {
  list(
    htmltools::htmlDependency(
      name = "jquery",
      version = "3.7.1",
      src = c(file = "htmlwidgets/lib/jquery"),
      package = "safePivot",
      script = "jquery-3.7.1.min.js",
      all_files = FALSE
    ),
    
    htmltools::htmlDependency(
      name = "jquery-ui",
      version = "1.13.2",
      src = c(file = "htmlwidgets/lib/jquery-ui"),
      package = "safePivot",
      script = "jquery-ui.min.js",
      stylesheet = "jquery-ui.min.css",
      all_files = FALSE
    ),
    
    htmltools::htmlDependency(
      name = "pivottable",
      version = "2.23.0",
      src = c(file = "htmlwidgets/lib/pivottable"),
      package = "safePivot",
      script = "pivot.min.js",
      stylesheet = "pivot.min.css",
      all_files = FALSE
    ),
    
    htmltools::htmlDependency(
      name = "plotly-basic",
      version = "1.58.5",
      src = c(file = "htmlwidgets/lib/plotly"),
      package = "safePivot",
      script = "plotly-basic-latest.min.js",
      all_files = FALSE
    ),
    
    htmltools::htmlDependency(
      name = "pivottable-plotly-renderers",
      version = "2.23.0",
      src = c(file = "htmlwidgets/lib/pivottable"),
      package = "safePivot",
      script = "plotly_renderers.js",
      all_files = FALSE
    ),
    
    htmltools::htmlDependency(
      name = "safePivot-css",
      version = "0.1.0",
      src = c(file = "htmlwidgets/lib/safePivot"),
      package = "safePivot",
      stylesheet = "safePivot.css",
      all_files = FALSE
    )
  )
}

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
#' @param renderer Initial renderer. One of `"Table"`, `"Heatmap"`,
#'   `"Row Heatmap"`, `"Col Heatmap"`, `"Bar Chart"`,
#'   `"Stacked Bar Chart"`, `"Horizontal Bar Chart"`,
#'   `"Horizontal Stacked Bar Chart"`, `"Line Chart"`, `"Area Chart"`,
#'   `"Scatter Chart"`, or `"Multiple Pie Chart"`.
#' @param missing_label Label used for missing categorical values.
#' @param show_missing_category Whether missing categorical values should be shown as a category.
#' @param respect_factor_order Whether R factor levels should control display order.
#' @param numeric_digits Number of digits used for displayed numeric values.
#' @param show_row_totals Whether to show row totals in table renderers.
#' @param show_col_totals Whether to show column totals in table renderers.
#' @param heatmap_palette Heatmap palette. One of `"blue"`, `"yellow_orange"`,
#'   `"green"`, `"blue_white_red"`, or `"green_red"`.
#' @param show_type_badges Whether to show small data-type badges beside
#'   draggable variable names in the pivot UI.
#' @param conditional_format Whether to apply browser-side conditional
#'   formatting to pivot table cells.
#' @param conditional_format_mode Conditional formatting mode. One of
#'   `"none"`, `"value"`, `"data_quality"`, or `"both"`.
#'   `"none"` applies no extra formatting. `"value"` highlights high and
#'   low numeric values. `"data_quality"` highlights empty cells and zero
#'   values. `"both"` combines value and data-quality formatting.
#' @param high_threshold Relative threshold for high-value cell formatting.
#'   Values are scaled from 0 to 1 within the displayed pivot table.
#' @param low_threshold Relative threshold for low-value cell formatting.
#'   Values are scaled from 0 to 1 within the displayed pivot table.
#' @param ui_font_size,pill_font_size,table_font_size,badge_font_size Font sizes
#'   used by the browser UI, draggable variable pills, pivot table, and type badges.
#' @param plot_default_height,plot_min_height,plot_max_width Default Plotly chart
#'   sizing controls used by chart renderers.
#' @param plot_font_size,plot_title_size,axis_title_size,axis_tick_size,legend_font_size
#'   Font sizes used by Plotly chart renderers.
#' @param plotly_layout Optional named list of Plotly layout values merged into
#'   the default chart layout.
#' @param plotly_config Optional named list of Plotly config values merged into
#'   the default chart config.
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
    show_type_badges = TRUE,
    conditional_format = TRUE,
    conditional_format_mode = "both",
    high_threshold = 0.85,
    low_threshold = 0.15,
    ui_font_size = 16,
    pill_font_size = 17,
    table_font_size = 18,
    badge_font_size = 12,
    plot_default_height = 620,
    plot_min_height = 520,
    plot_max_width = 1150,
    plot_font_size = 16,
    plot_title_size = 20,
    axis_title_size = 16,
    axis_tick_size = 14,
    legend_font_size = 14,
    plotly_layout = NULL,
    plotly_config = NULL,
    max_rows = 50000,
    width = "100%",
    height = NULL
) {
  stopifnot(is.data.frame(data))
  
  if (nrow(data) > max_rows) {
    stop(
      "Too many rows for browser-side pivot table. ",
      "Please filter or summarise first.",
      call. = FALSE
    )
  }
  
  rows <- safe_pivot_chr(rows)
  cols <- safe_pivot_chr(cols)
  vals <- safe_pivot_chr(vals)
  
  aggregator <- safe_pivot_config_scalar(aggregator, "Median")
  renderer <- safe_pivot_config_scalar(renderer, "Table")
  aggregator <- safe_pivot_normalize_aggregator(aggregator)
  
  allowed_renderers <- c(
    "Table",
    "Heatmap",
    "Row Heatmap",
    "Col Heatmap",
    "Bar Chart",
    "Stacked Bar Chart",
    "Horizontal Bar Chart",
    "Horizontal Stacked Bar Chart",
    "Line Chart",
    "Area Chart",
    "Scatter Chart",
    "Multiple Pie Chart"
  )

  if (!renderer %in% allowed_renderers) {
    stop(
      "Unsupported renderer: ", renderer,
      ". Supported renderers are: ",
      paste(allowed_renderers, collapse = ", "),
      call. = FALSE
    )
  }
  
  allowed_aggregators <- safe_pivot_allowed_aggregators()
  if (!aggregator %in% allowed_aggregators) {
    stop("Unsupported aggregator: ", aggregator, call. = FALSE)
  }
  
  all_vars <- names(data)
  
  check_vars <- function(x, arg) {
    bad <- setdiff(x, all_vars)
    
    if (length(bad) > 0) {
      stop(
        arg,
        " contains unknown variable(s): ",
        paste(bad, collapse = ", "),
        call. = FALSE
      )
    }
    
    invisible(TRUE)
  }
  
  check_vars(rows, "rows")
  check_vars(cols, "cols")
  check_vars(vals, "vals")
  
  factor_levels <- safe_pivot_factor_levels(data)
  variable_types <- safe_pivot_variable_types(data)
  
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

  validate_positive_number <- function(x, nm) {
    if (!is.numeric(x) || length(x) != 1 || is.na(x) || x <= 0) {
      stop("`", nm, "` must be a single positive number.", call. = FALSE)
    }
    invisible(TRUE)
  }

  validate_positive_number(ui_font_size, "ui_font_size")
  validate_positive_number(pill_font_size, "pill_font_size")
  validate_positive_number(table_font_size, "table_font_size")
  validate_positive_number(badge_font_size, "badge_font_size")
  validate_positive_number(plot_default_height, "plot_default_height")
  validate_positive_number(plot_min_height, "plot_min_height")
  validate_positive_number(plot_max_width, "plot_max_width")
  validate_positive_number(plot_font_size, "plot_font_size")
  validate_positive_number(plot_title_size, "plot_title_size")
  validate_positive_number(axis_title_size, "axis_title_size")
  validate_positive_number(axis_tick_size, "axis_tick_size")
  validate_positive_number(legend_font_size, "legend_font_size")

  if (!is.null(plotly_layout) && !is.list(plotly_layout)) {
    stop("`plotly_layout` must be NULL or a named list.", call. = FALSE)
  }

  if (!is.null(plotly_config) && !is.list(plotly_config)) {
    stop("`plotly_config` must be NULL or a named list.", call. = FALSE)
  }
  
  allowed_conditional_format_modes <- c(
    "none",
    "value",
    "data_quality",
    "both"
  )
  
  conditional_format_mode <- safe_pivot_config_scalar(
    conditional_format_mode,
    "both"
  )
  
  if (!conditional_format_mode %in% allowed_conditional_format_modes) {
    stop(
      "Unsupported conditional_format_mode: ", conditional_format_mode,
      ". Supported values are: ",
      paste(allowed_conditional_format_modes, collapse = ", "),
      call. = FALSE
    )
  }
  
  x <- list(
    data = data,
    rows = rows,
    cols = cols,
    vals = vals,
    aggregator = aggregator,
    renderer = renderer,
    missing_label = missing_label,
    factor_levels = factor_levels,
    respect_factor_order = respect_factor_order,
    variable_types = variable_types,
    numeric_digits = numeric_digits,
    show_row_totals = isTRUE(show_row_totals),
    show_col_totals = isTRUE(show_col_totals),
    heatmap_palette = heatmap_palette,
    show_type_badges = isTRUE(show_type_badges),
    conditional_format = isTRUE(conditional_format),
    conditional_format_mode = conditional_format_mode,
    high_threshold = high_threshold,
    low_threshold = low_threshold,
    ui_font_size = ui_font_size,
    pill_font_size = pill_font_size,
    table_font_size = table_font_size,
    badge_font_size = badge_font_size,
    plot_default_height = plot_default_height,
    plot_min_height = plot_min_height,
    plot_max_width = plot_max_width,
    plot_font_size = plot_font_size,
    plot_title_size = plot_title_size,
    axis_title_size = axis_title_size,
    axis_tick_size = axis_tick_size,
    legend_font_size = legend_font_size,
    plotly_layout = plotly_layout %||% list(),
    plotly_config = plotly_config %||% list(),
    allowed_renderers = allowed_renderers,
    allowed_aggregators = allowed_aggregators
  )
  
  htmlwidgets::createWidget(
    name = "safePivot",
    x = x,
    width = width,
    height = height,
    package = "safePivot",
    dependencies = safePivot_dependencies(),
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = 1000,
      defaultHeight = 760,
      
      viewer.fill = TRUE,
      viewer.padding = 0,
      viewer.paneHeight = 760,
      
      browser.fill = TRUE,
      browser.padding = 0,
      browser.defaultHeight = 760,
      
      knitr.defaultWidth = 1000,
      knitr.defaultHeight = 760
    )
  )
}
