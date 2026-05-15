# ============================================================
# prepare-data.R
# Data preparation helpers for safePivot
# ============================================================

`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

safe_pivot_factor_levels <- function(data) {
  stopifnot(is.data.frame(data))

  levs <- lapply(data, function(x) {
    if (is.factor(x)) levels(x) else NULL
  })

  levs[!vapply(levs, is.null, logical(1))]
}

safe_pivot_prepare_data <- function(
    data,
    missing_label = "(Missing)",
    show_missing_category = TRUE,
    group_vars = NULL
) {
  stopifnot(is.data.frame(data))

  if (!isTRUE(show_missing_category)) {
    return(data)
  }

  missing_label <- as.character(missing_label)[[1]]

  # Backward-compatible behaviour:
  # - When group_vars is NULL, prepare all factor/character/date grouping-like
  #   columns for the htmlwidget display.
  # - When group_vars is supplied by safe_pivot_compute(), prepare only row/col
  #   grouping variables. This avoids converting measured value NA into the
  #   missing-label string before aggregation.
  if (is.null(group_vars)) {
    target_vars <- names(data)[vapply(
      data,
      function(x) {
        is.factor(x) || is.character(x) || inherits(x, c("Date", "POSIXct", "POSIXlt", "POSIXt"))
      },
      logical(1)
    )]
  } else {
    group_vars <- trimws(as.character(unlist(group_vars, use.names = FALSE)))
    group_vars <- group_vars[!is.na(group_vars) & nzchar(group_vars)]
    target_vars <- intersect(group_vars, names(data))
  }

  if (length(target_vars) == 0) {
    return(data)
  }

  for (nm in target_vars) {
    x <- data[[nm]]

    if (is.factor(x)) {
      if (!missing_label %in% levels(x)) {
        levels(x) <- c(levels(x), missing_label)
      }
      x[is.na(x) | !nzchar(trimws(as.character(x)))] <- missing_label
      data[[nm]] <- x
      next
    }

    if (is.character(x) || inherits(x, c("Date", "POSIXct", "POSIXlt", "POSIXt"))) {
      x_chr <- as.character(x)
      x_chr[is.na(x_chr) | !nzchar(trimws(x_chr))] <- missing_label
      data[[nm]] <- x_chr
      next
    }

    # Numeric/logical/list/object columns are intentionally left unchanged.
    # In particular, numeric NA must remain NA so missing-value aggregators work.
  }

  data
}
