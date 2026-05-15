# ============================================================
# compute-pivot.R
# R-side computation helpers for safePivot
# Note: safe_pivot_prepare_data() lives in prepare-data.R
# ============================================================

safe_pivot_chr <- function(x) {
  if (is.null(x)) {
    return(character())
  }

  if (is.list(x)) {
    x <- unlist(x, use.names = FALSE)
  }

  x <- trimws(as.character(x))
  x[!is.na(x) & nzchar(x)]
}

safe_pivot_to_numeric <- function(x) {
  suppressWarnings(as.numeric(x))
}

safe_numeric <- function(x) {
  v <- safe_pivot_to_numeric(x)
  v[is.finite(v)]
}

safe_pivot_count_all <- function(x) {
  length(x)
}

safe_pivot_is_missing_value <- function(x, missing_label = NULL) {
  out <- is.na(x)

  x_chr <- trimws(as.character(x))

  out <- out |
    !nzchar(x_chr) |
    x_chr %in% c("NA", "NaN", "null", "undefined", "-")

  if (!is.null(missing_label)) {
    missing_label <- as.character(missing_label)[[1]]
    out <- out | x_chr == missing_label
  }

  out
}

safe_pivot_count_missing <- function(x) {
  sum(safe_pivot_is_missing_value(x))
}

safe_pivot_count_non_missing <- function(x) {
  sum(!safe_pivot_is_missing_value(x))
}

safe_pivot_count_numeric <- function(x) {
  x_num <- safe_pivot_to_numeric(x)
  sum(is.finite(x_num))
}

safe_pivot_count_zero <- function(x) {
  x_num <- safe_pivot_to_numeric(x)
  sum(is.finite(x_num) & x_num == 0)
}

safe_pivot_count_non_zero <- function(x) {
  x_num <- safe_pivot_to_numeric(x)
  sum(is.finite(x_num) & x_num != 0)
}

safe_pivot_sum_numeric <- function(x) {
  v <- safe_numeric(x)

  if (length(v) == 0) {
    return(NA_real_)
  }

  sum(v)
}

safe_pivot_pct <- function(num, den) {
  num <- as.numeric(num)
  den <- as.numeric(den)

  ifelse(
    is.na(num) | is.na(den) | den == 0,
    NA_real_,
    100 * num / den
  )
}

safe_pivot_new_col_name <- function(data, prefix = ".safePivot_count") {
  nm <- prefix
  i <- 1L

  while (nm %in% names(data)) {
    i <- i + 1L
    nm <- paste0(prefix, "_", i)
  }

  nm
}

safe_pivot_check_columns <- function(data, vars, arg = "vars") {
  vars <- safe_pivot_chr(vars)

  missing_vars <- setdiff(vars, names(data))

  if (length(missing_vars) > 0) {
    stop(
      "Unknown column(s) in `", arg, "`: ",
      paste(missing_vars, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


safe_pivot_normalize_aggregator <- function(aggregator) {
  aggregator <- as.character(aggregator)[[1]]

  switch(
    aggregator,
    "Missing %" = "Missing % within Cell",
    "Non-missing %" = "Non-missing % within Cell",
    aggregator
  )
}

safe_pivot_allowed_aggregators <- function() {
  c(
    "Count",
    "Count unique",
    "List unique values",

    "N non-missing",
    "N missing",
    "Non-missing %",
    "Missing %",
    "Non-missing % within Cell",
    "Missing % within Cell",
    "Non-missing % of Row",
    "Non-missing % of Column",
    "Non-missing % of Total",
    "Missing % of Row",
    "Missing % of Column",
    "Missing % of Total",

    "N zero",
    "N non-zero",
    "Zero % within Cell",
    "Non-zero % within Cell",
    "Zero % of Row",
    "Zero % of Column",
    "Zero % of Total",
    "Non-zero % of Row",
    "Non-zero % of Column",
    "Non-zero % of Total",

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
}

safe_pivot_is_fraction_aggregator <- function(aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)

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
  aggregator <- safe_pivot_normalize_aggregator(aggregator)

  if (aggregator %in% c(
    "Sum as Fraction of Total",
    "Sum as Fraction of Rows",
    "Sum as Fraction of Columns"
  )) {
    return("Sum")
  }

  if (aggregator %in% c(
    "Count as Fraction of Total",
    "Count as Fraction of Rows",
    "Count as Fraction of Columns"
  )) {
    return("Count")
  }

  aggregator
}

safe_pivot_is_context_percent_aggregator <- function(aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)

  aggregator %in% c(
    "Missing % of Row",
    "Missing % of Column",
    "Missing % of Total",
    "Non-missing % of Row",
    "Non-missing % of Column",
    "Non-missing % of Total",
    "Zero % of Row",
    "Zero % of Column",
    "Zero % of Total",
    "Non-zero % of Row",
    "Non-zero % of Column",
    "Non-zero % of Total"
  )
}

safe_pivot_requires_value <- function(aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)
  base_aggregator <- safe_pivot_fraction_base(aggregator)

  !identical(base_aggregator, "Count")
}

safe_agg_vector <- function(x, aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)

  if (aggregator == "Count") {
    return(length(x))
  }

  if (aggregator == "Count unique") {
    x2 <- x[!safe_pivot_is_missing_value(x)]
    return(length(unique(x2)))
  }

  if (aggregator == "List unique values") {
    x2 <- as.character(x)
    x2 <- x2[!safe_pivot_is_missing_value(x2)]
    return(paste(sort(unique(x2)), collapse = ", "))
  }

  if (aggregator == "N non-missing") {
    return(safe_pivot_count_non_missing(x))
  }

  if (aggregator == "N missing") {
    return(safe_pivot_count_missing(x))
  }

  if (aggregator == "Non-missing % within Cell") {
    return(
      safe_pivot_pct(
        safe_pivot_count_non_missing(x),
        safe_pivot_count_all(x)
      )
    )
  }

  if (aggregator == "Missing % within Cell") {
    return(
      safe_pivot_pct(
        safe_pivot_count_missing(x),
        safe_pivot_count_all(x)
      )
    )
  }

  if (aggregator == "N zero") {
    return(safe_pivot_count_zero(x))
  }

  if (aggregator == "N non-zero") {
    return(safe_pivot_count_non_zero(x))
  }

  if (aggregator == "Zero % within Cell") {
    return(
      safe_pivot_pct(
        safe_pivot_count_zero(x),
        safe_pivot_count_numeric(x)
      )
    )
  }

  if (aggregator == "Non-zero % within Cell") {
    return(
      safe_pivot_pct(
        safe_pivot_count_non_zero(x),
        safe_pivot_count_numeric(x)
      )
    )
  }

  v <- safe_numeric(x)

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
      if (length(v) < 2) {
        NA_real_
      } else {
        m <- mean(v)
        if (isTRUE(all.equal(m, 0))) NA_real_ else 100 * stats::sd(v) / m
      }
    },
    "Q1" = as.numeric(stats::quantile(v, probs = 0.25, names = FALSE, type = 7)),
    "Q3" = as.numeric(stats::quantile(v, probs = 0.75, names = FALSE, type = 7)),
    "IQR" = stats::IQR(v),
    stop("Unsupported aggregator: ", aggregator, call. = FALSE)
  )
}

safe_pivot_group_apply <- function(data, group_vars, value_var, fun) {
  group_vars <- safe_pivot_chr(group_vars)

  if (length(group_vars) == 0) {
    return(data.frame(.value = fun(data[[value_var]])))
  }

  if (nrow(data) == 0) {
    out <- data[group_vars][0, , drop = FALSE]
    out$.value <- logical()
    return(out)
  }

  split_keys <- data[group_vars]
  split_idx <- split(seq_len(nrow(data)), split_keys, drop = TRUE)

  out <- lapply(split_idx, function(idx) {
    group_row <- data[idx[[1]], group_vars, drop = FALSE]
    group_row$.value <- fun(data[[value_var]][idx])
    group_row
  })

  out <- do.call(rbind, out)
  rownames(out) <- NULL
  out
}

safe_pivot_group_counts <- function(data, group_vars, value_var, prefix) {
  group_vars <- safe_pivot_chr(group_vars)

  make_one <- function(dat) {
    x <- dat[[value_var]]

    x_num <- safe_pivot_to_numeric(x)
    is_num <- is.finite(x_num)

    n_all <- length(x)

    data.frame(
      all_n = n_all,
      missing_n = safe_pivot_count_missing(x),
      non_missing_n = safe_pivot_count_non_missing(x),
      numeric_n = sum(is_num),
      zero_n = sum(is_num & x_num == 0),
      non_zero_n = sum(is_num & x_num != 0),
      sum_numeric = if (sum(is_num) == 0) NA_real_ else sum(x_num[is_num])
    )
  }

  if (length(group_vars) == 0) {
    out <- make_one(data)
  } else if (nrow(data) == 0) {
    out <- data[group_vars][0, , drop = FALSE]
    out$all_n <- integer()
    out$missing_n <- integer()
    out$non_missing_n <- integer()
    out$numeric_n <- integer()
    out$zero_n <- integer()
    out$non_zero_n <- integer()
    out$sum_numeric <- numeric()
  } else {
    split_keys <- data[group_vars]
    split_idx <- split(seq_len(nrow(data)), split_keys, drop = TRUE)

    out <- lapply(split_idx, function(idx) {
      group_row <- data[idx[[1]], group_vars, drop = FALSE]
      summary_row <- make_one(data[idx, , drop = FALSE])
      cbind(group_row, summary_row)
    })

    out <- do.call(rbind, out)
    rownames(out) <- NULL
  }

  names(out)[names(out) == "all_n"] <- paste0(prefix, "_all_n")
  names(out)[names(out) == "missing_n"] <- paste0(prefix, "_missing_n")
  names(out)[names(out) == "non_missing_n"] <- paste0(prefix, "_non_missing_n")
  names(out)[names(out) == "numeric_n"] <- paste0(prefix, "_numeric_n")
  names(out)[names(out) == "zero_n"] <- paste0(prefix, "_zero_n")
  names(out)[names(out) == "non_zero_n"] <- paste0(prefix, "_non_zero_n")
  names(out)[names(out) == "sum_numeric"] <- paste0(prefix, "_sum_numeric")

  out
}

safe_pivot_to_wide <- function(long, rows, cols) {
  rows <- safe_pivot_chr(rows)
  cols <- safe_pivot_chr(cols)

  if (length(cols) == 0) {
    return(long)
  }

  long |>
    tidyr::unite(
      ".safePivot_col_key",
      dplyr::all_of(cols),
      sep = " | ",
      remove = FALSE
    ) |>
    dplyr::select(dplyr::all_of(c(rows, ".safePivot_col_key", ".value"))) |>
    tidyr::pivot_wider(
      names_from = ".safePivot_col_key",
      values_from = ".value"
    )
}

safe_pivot_compute_fraction <- function(data, rows, cols, vals, aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)
  
  rows <- safe_pivot_chr(rows)
  cols <- safe_pivot_chr(cols)
  vals <- safe_pivot_chr(vals)
  
  sum_fraction_aggs <- c(
    "Sum as Fraction of Total",
    "Sum as Fraction of Rows",
    "Sum as Fraction of Columns"
  )
  
  count_fraction_aggs <- c(
    "Count as Fraction of Total",
    "Count as Fraction of Rows",
    "Count as Fraction of Columns"
  )
  
  is_sum_fraction <- aggregator %in% sum_fraction_aggs
  is_count_fraction <- aggregator %in% count_fraction_aggs
  
  if (!is_sum_fraction && !is_count_fraction) {
    stop("Unsupported fraction aggregator: ", aggregator, call. = FALSE)
  }
  
  if (
    is_sum_fraction &&
    (length(vals) != 1 || is.na(vals[[1]]) || !nzchar(vals[[1]]))
  ) {
    stop(
      "Aggregator '", aggregator, "' requires exactly one value column in `vals`.",
      call. = FALSE
    )
  }
  
  count_var <- ".safePivot_count_var"
  
  if (is_count_fraction && !count_var %in% names(data)) {
    data[[count_var]] <- seq_len(nrow(data))
  }
  
  value_var <- if (is_sum_fraction) vals[[1]] else count_var
  group_vars <- c(rows, cols)
  
  cell_summary <- safe_pivot_group_counts(
    data = data,
    group_vars = group_vars,
    value_var = value_var,
    prefix = ".safePivot_cell"
  )
  
  total_summary <- safe_pivot_group_counts(
    data = data,
    group_vars = character(),
    value_var = value_var,
    prefix = ".safePivot_total"
  )
  
  if (is_sum_fraction) {
    cell_num <- cell_summary$.safePivot_cell_sum_numeric
    total_denom <- total_summary$.safePivot_total_sum_numeric[[1]]
  } else {
    cell_num <- cell_summary$.safePivot_cell_all_n
    total_denom <- total_summary$.safePivot_total_all_n[[1]]
  }
  
  cell_summary$.value <- NA_real_
  
  if (aggregator %in% c("Sum as Fraction of Total", "Count as Fraction of Total")) {
    cell_summary$.value <- safe_pivot_pct(cell_num, total_denom)
  }
  
  if (aggregator %in% c("Sum as Fraction of Rows", "Count as Fraction of Rows")) {
    if (length(rows) == 0) {
      row_denom <- total_denom
      cell_summary$.value <- safe_pivot_pct(cell_num, row_denom)
    } else {
      row_summary <- safe_pivot_group_counts(
        data = data,
        group_vars = rows,
        value_var = value_var,
        prefix = ".safePivot_row"
      )
      
      cell_summary <- dplyr::left_join(cell_summary, row_summary, by = rows)
      
      row_denom <- if (is_sum_fraction) {
        cell_summary$.safePivot_row_sum_numeric
      } else {
        cell_summary$.safePivot_row_all_n
      }
      
      cell_summary$.value <- safe_pivot_pct(cell_num, row_denom)
    }
  }
  
  if (aggregator %in% c("Sum as Fraction of Columns", "Count as Fraction of Columns")) {
    if (length(cols) == 0) {
      col_denom <- total_denom
      cell_summary$.value <- safe_pivot_pct(cell_num, col_denom)
    } else {
      col_summary <- safe_pivot_group_counts(
        data = data,
        group_vars = cols,
        value_var = value_var,
        prefix = ".safePivot_col"
      )
      
      cell_summary <- dplyr::left_join(cell_summary, col_summary, by = cols)
      
      col_denom <- if (is_sum_fraction) {
        cell_summary$.safePivot_col_sum_numeric
      } else {
        cell_summary$.safePivot_col_all_n
      }
      
      cell_summary$.value <- safe_pivot_pct(cell_num, col_denom)
    }
  }
  
  long <- cell_summary |>
    dplyr::select(dplyr::all_of(c(group_vars, ".value")))
  
  wide <- safe_pivot_to_wide(long, rows = rows, cols = cols)
  
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

safe_pivot_compute_context_percent <- function(data, rows, cols, vals, aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)

  rows <- safe_pivot_chr(rows)
  cols <- safe_pivot_chr(cols)
  vals <- safe_pivot_chr(vals)

  if (length(vals) != 1 || is.na(vals[[1]]) || !nzchar(vals[[1]])) {
    stop(
      "Aggregator '", aggregator, "' requires exactly one value column in `vals`.",
      call. = FALSE
    )
  }

  value_var <- vals[[1]]

  group_vars <- c(rows, cols)
  row_vars <- rows
  col_vars <- cols

  cell_summary <- safe_pivot_group_counts(
    data = data,
    group_vars = group_vars,
    value_var = value_var,
    prefix = ".safePivot_cell"
  )

  row_summary <- safe_pivot_group_counts(
    data = data,
    group_vars = row_vars,
    value_var = value_var,
    prefix = ".safePivot_row"
  )

  col_summary <- safe_pivot_group_counts(
    data = data,
    group_vars = col_vars,
    value_var = value_var,
    prefix = ".safePivot_col"
  )

  total_summary <- safe_pivot_group_counts(
    data = data,
    group_vars = character(),
    value_var = value_var,
    prefix = ".safePivot_total"
  )

  if (length(row_vars) > 0) {
    cell_summary <- dplyr::left_join(cell_summary, row_summary, by = row_vars)
  } else {
    for (nm in names(row_summary)) {
      cell_summary[[nm]] <- row_summary[[nm]][[1]]
    }
  }

  if (length(col_vars) > 0) {
    cell_summary <- dplyr::left_join(cell_summary, col_summary, by = col_vars)
  } else {
    for (nm in names(col_summary)) {
      cell_summary[[nm]] <- col_summary[[nm]][[1]]
    }
  }

  for (nm in names(total_summary)) {
    cell_summary[[nm]] <- total_summary[[nm]][[1]]
  }

  cell_summary$.value <- switch(
    aggregator,

    "Missing % of Row" = safe_pivot_pct(
      cell_summary$.safePivot_cell_missing_n,
      cell_summary$.safePivot_row_all_n
    ),

    "Missing % of Column" = safe_pivot_pct(
      cell_summary$.safePivot_cell_missing_n,
      cell_summary$.safePivot_col_all_n
    ),

    "Missing % of Total" = safe_pivot_pct(
      cell_summary$.safePivot_cell_missing_n,
      cell_summary$.safePivot_total_all_n
    ),

    "Non-missing % of Row" = safe_pivot_pct(
      cell_summary$.safePivot_cell_non_missing_n,
      cell_summary$.safePivot_row_all_n
    ),

    "Non-missing % of Column" = safe_pivot_pct(
      cell_summary$.safePivot_cell_non_missing_n,
      cell_summary$.safePivot_col_all_n
    ),

    "Non-missing % of Total" = safe_pivot_pct(
      cell_summary$.safePivot_cell_non_missing_n,
      cell_summary$.safePivot_total_all_n
    ),

    "Zero % of Row" = safe_pivot_pct(
      cell_summary$.safePivot_cell_zero_n,
      cell_summary$.safePivot_row_numeric_n
    ),

    "Zero % of Column" = safe_pivot_pct(
      cell_summary$.safePivot_cell_zero_n,
      cell_summary$.safePivot_col_numeric_n
    ),

    "Zero % of Total" = safe_pivot_pct(
      cell_summary$.safePivot_cell_zero_n,
      cell_summary$.safePivot_total_numeric_n
    ),

    "Non-zero % of Row" = safe_pivot_pct(
      cell_summary$.safePivot_cell_non_zero_n,
      cell_summary$.safePivot_row_numeric_n
    ),

    "Non-zero % of Column" = safe_pivot_pct(
      cell_summary$.safePivot_cell_non_zero_n,
      cell_summary$.safePivot_col_numeric_n
    ),

    "Non-zero % of Total" = safe_pivot_pct(
      cell_summary$.safePivot_cell_non_zero_n,
      cell_summary$.safePivot_total_numeric_n
    ),

    stop("Unsupported context percentage aggregator: ", aggregator, call. = FALSE)
  )

  long <- cell_summary |>
    dplyr::select(dplyr::all_of(c(group_vars, ".value")))

  wide <- safe_pivot_to_wide(long, rows = rows, cols = cols)

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
#' @details
#' safePivot distinguishes empty pivot cells, observed missing values, and
#' observed numeric zero values. An empty pivot cell means no records exist for
#' that row-column combination and is returned as `NA` after widening. An
#' observed missing value means a record exists but the selected value is `NA`;
#' this contributes to `N missing`. Zero and non-zero aggregators use finite
#' numeric non-missing values only.
#'
#' Missing and non-missing percentages use observed record counts as
#' denominators. Zero and non-zero percentages use numeric non-missing counts
#' as denominators. Sum fraction aggregators use numeric sums as denominators,
#' while count fraction aggregators use observed record counts as denominators.
#'
#' @return A list with `long`, `wide`, and `config`.
#'
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

  rows <- safe_pivot_chr(rows)
  cols <- safe_pivot_chr(cols)
  vals <- safe_pivot_chr(vals)

  aggregator <- safe_pivot_normalize_aggregator(aggregator)

  if (!aggregator %in% safe_pivot_allowed_aggregators()) {
    stop("Unsupported aggregator: ", aggregator, call. = FALSE)
  }

  safe_pivot_check_columns(data, c(rows, cols), arg = "rows/cols")

  if (length(vals) > 0) {
    safe_pivot_check_columns(data, vals, arg = "vals")
  }

  base_aggregator <- safe_pivot_fraction_base(aggregator)

  if (safe_pivot_requires_value(aggregator) && length(vals) < 1) {
    stop("`vals` is required unless aggregator = 'Count' or a count-fraction aggregator.", call. = FALSE)
  }

  value_var <- if (base_aggregator == "Count") NULL else vals[[1]]

  data <- safe_pivot_prepare_data(
    data = data,
    group_vars = c(rows, cols),
    missing_label = missing_label,
    show_missing_category = show_missing_category
  )

  if (safe_pivot_is_fraction_aggregator(aggregator)) {
    return(
      safe_pivot_compute_fraction(
        data = data,
        rows = rows,
        cols = cols,
        vals = vals,
        aggregator = aggregator
      )
    )
  }

  if (safe_pivot_is_context_percent_aggregator(aggregator)) {
    return(
      safe_pivot_compute_context_percent(
        data = data,
        rows = rows,
        cols = cols,
        vals = vals,
        aggregator = aggregator
      )
    )
  }

  group_vars <- c(rows, cols)

  if (length(group_vars) == 0) {
    count_var <- safe_pivot_new_col_name(data, ".safePivot_count")
    data[[count_var]] <- seq_len(nrow(data))

    base_value <- safe_agg_vector(
      if (base_aggregator == "Count") data[[count_var]] else data[[value_var]],
      base_aggregator
    )

    long <- data.frame(.value = base_value)
  } else {
    if (base_aggregator == "Count") {
      count_var <- safe_pivot_new_col_name(data, ".safePivot_count")
      data[[count_var]] <- seq_len(nrow(data))
      value_for_group <- count_var
    } else {
      value_for_group <- value_var
    }

    long <- safe_pivot_group_apply(
      data = data,
      group_vars = group_vars,
      value_var = value_for_group,
      fun = function(x) {
        if (base_aggregator == "Count") {
          length(x)
        } else {
          safe_agg_vector(x, base_aggregator)
        }
      }
    )
  }

  wide <- safe_pivot_to_wide(long, rows = rows, cols = cols)

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
  safe_pivot_chr(x)
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
  default_rows <- safe_pivot_config_chr(default_rows)
  default_cols <- safe_pivot_config_chr(default_cols)
  default_vals <- safe_pivot_config_chr(default_vals)

  if (is.null(config)) {
    rows <- default_rows
    cols <- default_cols
    vals <- default_vals
    aggregator <- default_aggregator
  } else {
    rows <- safe_pivot_config_chr(config$rows)
    cols <- safe_pivot_config_chr(config$cols)
    vals <- safe_pivot_config_chr(config$vals)
    aggregator <- safe_pivot_config_scalar(
      config$aggregatorName,
      default_aggregator
    )

    # PivotTable.js can send empty lists when the user has not selected a field.
    # For export/report workflows, fall back field-by-field to the defaults
    # supplied by the Shiny server.
    if (length(rows) == 0 && length(default_rows) > 0) {
      rows <- default_rows
    }

    if (length(cols) == 0 && length(default_cols) > 0) {
      cols <- default_cols
    }

    if (length(vals) == 0 && length(default_vals) > 0) {
      vals <- default_vals
    }

    if (is.null(aggregator) || !nzchar(aggregator)) {
      aggregator <- default_aggregator
    }
  }

  safe_pivot_compute(
    data = data,
    rows = rows,
    cols = cols,
    vals = vals,
    aggregator = aggregator,
    missing_label = missing_label,
    show_missing_category = show_missing_category
  )
}
