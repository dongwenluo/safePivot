safe_numeric <- function(x) {
  if (is.numeric(x)) {
    v <- as.numeric(x)
  } else {
    v <- suppressWarnings(as.numeric(x))
  }
  
  v[is.finite(v)]
}

safe_pivot_is_fraction_aggregator <- function(aggregator) {
  aggregator %in% c(
    "Sum as Fraction of Total",
    "Sum as Fraction of Rows",
    "Sum as Fraction of Columns",
    "Count as Fraction of Total",
    "Count as Fraction of Rows",
    "Count as Fraction of Columns"
  )
}

safe_pivot_fraction_base <- function(aggregator) {
  switch(
    aggregator,
    "Sum as Fraction of Total" = "Sum",
    "Sum as Fraction of Rows" = "Sum",
    "Sum as Fraction of Columns" = "Sum",
    "Count as Fraction of Total" = "Count",
    "Count as Fraction of Rows" = "Count",
    "Count as Fraction of Columns" = "Count",
    aggregator
  )
}

safe_agg_vector <- function(x, aggregator) {
  if (aggregator == "Count") {
    return(length(x))
  }
  
  if (aggregator == "Count unique") {
    x2 <- x[!is.na(x) & nzchar(as.character(x))]
    return(length(unique(x2)))
  }
  
  if (aggregator == "List unique values") {
    x2 <- as.character(x)
    x2 <- x2[!is.na(x2) & nzchar(x2)]
    return(paste(sort(unique(x2)), collapse = ", "))
  }
  
  v_all <- suppressWarnings(as.numeric(x))
  n_all <- length(x)
  n_used <- sum(is.finite(v_all))
  n_miss <- n_all - n_used
  
  if (aggregator == "N non-missing") return(n_used)
  if (aggregator == "N missing") return(n_miss)
  
  if (aggregator == "Non-missing %") {
    return(if (n_all == 0) NA_real_ else 100 * n_used / n_all)
  }
  
  if (aggregator == "Missing %") {
    return(if (n_all == 0) NA_real_ else 100 * n_miss / n_all)
  }
  
  v <- v_all[is.finite(v_all)]
  
  if (length(v) == 0) {
    return(NA_real_)
  }
  
  switch(
    aggregator,
    "Sum" = sum(v),
    "Mean" = mean(v),
    "Median" = stats::median(v),
    "Min" = min(v),
    "Max" = max(v),
    "Range" = max(v) - min(v),
    "Variance" = if (length(v) >= 2) stats::var(v) else NA_real_,
    "SD" = if (length(v) >= 2) stats::sd(v) else NA_real_,
    "SE" = if (length(v) >= 2) stats::sd(v) / sqrt(length(v)) else NA_real_,
    "CV %" = {
      m <- mean(v)
      if (isTRUE(all.equal(m, 0))) NA_real_ else 100 * stats::sd(v) / m
    },
    "Q1" = as.numeric(stats::quantile(v, probs = 0.25, names = FALSE, type = 7)),
    "Q3" = as.numeric(stats::quantile(v, probs = 0.75, names = FALSE, type = 7)),
    "IQR" = stats::IQR(v),
    stop("Unsupported aggregator: ", aggregator, call. = FALSE)
  )
}

#' Compute pivot result in R
#'
#' @param data A data frame.
#' @param rows Character vector of row variables.
#' @param cols Character vector of column variables.
#' @param vals Character vector of value variables.
#' @param aggregator Aggregator name.
#' @param missing_label Label for missing categorical values.
#' @param show_missing_category Whether missing categorical values are shown as a level.
#'
#' @return A list with `long`, `wide`, and `config`.
#'
#' @importFrom rlang .data
#' @export
safe_pivot_compute <- function(
    data,
    rows = NULL,
    cols = NULL,
    vals = NULL,
    aggregator = "Median",
    missing_label = "(Missing)",
    show_missing_category = TRUE
) {
  stopifnot(is.data.frame(data))
  
  rows <- rows %||% character()
  cols <- cols %||% character()
  vals <- vals %||% character()
  
  rows <- as.character(rows)
  cols <- as.character(cols)
  vals <- as.character(vals)
  
  base_aggregator <- safe_pivot_fraction_base(aggregator)
  
  if (base_aggregator != "Count" && length(vals) < 1) {
    stop("`vals` is required unless aggregator = 'Count'.", call. = FALSE)
  }
  
  value_var <- vals[1]
  
  data <- safe_pivot_prepare_data(
    data = data,
    missing_label = missing_label,
    show_missing_category = show_missing_category
  )
  
  group_vars <- c(rows, cols)
  
  if (length(group_vars) == 0) {
    base_value <- safe_agg_vector(
      if (base_aggregator == "Count") seq_len(nrow(data)) else data[[value_var]],
      base_aggregator
    )
    
    long <- data.frame(.value = base_value)
  } else {
    long <- data |>
      dplyr::group_by(dplyr::across(dplyr::all_of(group_vars))) |>
      dplyr::summarise(
        .value = safe_agg_vector(
          if (base_aggregator == "Count") dplyr::cur_group_rows() else .data[[value_var]],
          base_aggregator
        ),
        .groups = "drop"
      )
  }
  
  if (safe_pivot_is_fraction_aggregator(aggregator)) {
    total_denom <- safe_agg_vector(
      if (base_aggregator == "Count") seq_len(nrow(data)) else data[[value_var]],
      base_aggregator
    )
    
    if (aggregator %in% c("Sum as Fraction of Total", "Count as Fraction of Total")) {
      long$.value <- if (is.na(total_denom) || total_denom == 0) {
        NA_real_
      } else {
        100 * as.numeric(long$.value) / total_denom
      }
    }
    
    if (aggregator %in% c("Sum as Fraction of Rows", "Count as Fraction of Rows")) {
      if (length(rows) == 0) {
        row_denoms <- data.frame(.row_denom = total_denom)
        long$.row_denom <- total_denom
      } else {
        row_denoms <- data |>
          dplyr::group_by(dplyr::across(dplyr::all_of(rows))) |>
          dplyr::summarise(
            .row_denom = safe_agg_vector(
              if (base_aggregator == "Count") dplyr::cur_group_rows() else .data[[value_var]],
              base_aggregator
            ),
            .groups = "drop"
          )
        
        long <- dplyr::left_join(long, row_denoms, by = rows)
      }
      
      long$.value <- ifelse(
        is.na(long$.row_denom) | long$.row_denom == 0,
        NA_real_,
        100 * as.numeric(long$.value) / long$.row_denom
      )
      
      long$.row_denom <- NULL
    }
    
    if (aggregator %in% c("Sum as Fraction of Columns", "Count as Fraction of Columns")) {
      if (length(cols) == 0) {
        long$.col_denom <- total_denom
      } else {
        col_denoms <- data |>
          dplyr::group_by(dplyr::across(dplyr::all_of(cols))) |>
          dplyr::summarise(
            .col_denom = safe_agg_vector(
              if (base_aggregator == "Count") dplyr::cur_group_rows() else .data[[value_var]],
              base_aggregator
            ),
            .groups = "drop"
          )
        
        long <- dplyr::left_join(long, col_denoms, by = cols)
      }
      
      long$.value <- ifelse(
        is.na(long$.col_denom) | long$.col_denom == 0,
        NA_real_,
        100 * as.numeric(long$.value) / long$.col_denom
      )
      
      long$.col_denom <- NULL
    }
  }
  
  if (length(cols) == 0) {
    wide <- long
  } else {
    wide <- long |>
      tidyr::unite(".safePivot_col_key", dplyr::all_of(cols), sep = " | ", remove = FALSE) |>
      dplyr::select(dplyr::all_of(c(rows, ".safePivot_col_key", ".value"))) |>
      tidyr::pivot_wider(
        names_from = ".safePivot_col_key",
        values_from = ".value"
      )
  }
  
  list(
    long = long,
    wide = wide,
    config = list(
      rows = rows,
      cols = cols,
      vals = vals,
      aggregator = aggregator
    )
  )
}

safe_pivot_config_chr <- function(x) {
  if (is.null(x)) {
    return(character())
  }
  
  if (is.list(x)) {
    x <- unlist(x, use.names = FALSE)
  }
  
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  x
}


safe_pivot_config_scalar <- function(x, default) {
  if (is.null(x)) {
    return(default)
  }
  
  if (is.list(x)) {
    x <- unlist(x, use.names = FALSE)
  }
  
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  
  if (length(x) == 0) {
    default
  } else {
    x[[1]]
  }
}

#' Compute pivot result from a Shiny safePivot config
#'
#' @param data A data frame.
#' @param config A pivot configuration object, usually `input$<outputId>_config`.
#' @param default_rows Default row variables used when `config` is `NULL`.
#' @param default_cols Default column variables used when `config` is `NULL`.
#' @param default_vals Default value variable used when `config` is `NULL`.
#' @param default_aggregator Default aggregator used when `config` is `NULL`.
#' @param missing_label Label for missing categorical values.
#' @param show_missing_category Whether missing categorical values are shown as a level.
#'
#' @return A list with `long`, `wide`, and `config`.
#'
#' @examples
#' res <- safe_pivot_compute_from_config(
#'   iris,
#'   config = NULL,
#'   default_rows = "Species",
#'   default_vals = "Sepal.Length",
#'   default_aggregator = "Median"
#' )
#'
#' @export
safe_pivot_compute_from_config <- function(
    data,
    config,
    default_rows = NULL,
    default_cols = NULL,
    default_vals = NULL,
    default_aggregator = "Median",
    missing_label = "(Missing)",
    show_missing_category = TRUE
) {
  if (is.null(config)) {
    return(
      safe_pivot_compute(
        data = data,
        rows = safe_pivot_config_chr(default_rows),
        cols = safe_pivot_config_chr(default_cols),
        vals = safe_pivot_config_chr(default_vals),
        aggregator = default_aggregator,
        missing_label = missing_label,
        show_missing_category = show_missing_category
      )
    )
  }
  
  safe_pivot_compute(
    data = data,
    rows = safe_pivot_config_chr(config$rows),
    cols = safe_pivot_config_chr(config$cols),
    vals = safe_pivot_config_chr(config$vals),
    aggregator = safe_pivot_config_scalar(
      config$aggregatorName,
      default_aggregator
    ),
    missing_label = missing_label,
    show_missing_category = show_missing_category
  )
}
