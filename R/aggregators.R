# ============================================================
# aggregators.R
# The single list of safePivot aggregators.
#
# Both the R computations and the browser widget read this table, so a
# new aggregator only needs a row here (plus its maths in R and JS).
#
# Columns:
#   name         Name shown in the UI and accepted by `aggregator =`.
#   family       How the value is built:
#                  count        number of records
#                  count_unique number of distinct non-missing values
#                  list         distinct non-missing values, comma separated
#                  n            count of `measure` values
#                  percent      `measure` count as a % of a denominator
#                  fraction     cell `measure` (sum or count) as a % of `scope`
#                  stat         a numeric summary (Mean, SD, ...)
#   measure      missing / non_missing / zero / non_zero for n and percent;
#                sum / count for fraction; NA otherwise.
#   scope        Denominator for percent and fraction: cell, row, col, total.
#   needs_value  Whether a value variable must be chosen.
#   format       Display: integer, number, percent (0-100), text.
# ============================================================

safe_pivot_cache <- new.env(parent = emptyenv())

# Built once per session; it is looked up once per pivot cell.
safe_pivot_aggregator_registry <- function() {
  if (is.null(safe_pivot_cache$registry)) {
    safe_pivot_cache$registry <- safe_pivot_build_aggregator_registry()
  }

  safe_pivot_cache$registry
}

safe_pivot_build_aggregator_registry <- function() {
  agg <- function(name, family, measure = NA_character_, scope = NA_character_,
                  needs_value = TRUE, format = "number") {
    data.frame(
      name = name,
      family = family,
      measure = measure,
      scope = scope,
      needs_value = needs_value,
      format = format,
      stringsAsFactors = FALSE
    )
  }

  pct <- function(label, measure) {
    rbind(
      agg(paste(label, "% within Cell"), "percent", measure, "cell", format = "percent"),
      agg(paste(label, "% of Row"), "percent", measure, "row", format = "percent"),
      agg(paste(label, "% of Column"), "percent", measure, "col", format = "percent"),
      agg(paste(label, "% of Total"), "percent", measure, "total", format = "percent")
    )
  }

  fraction <- function(label, measure, needs_value) {
    rbind(
      agg(paste(label, "as Fraction of Total"), "fraction", measure, "total", needs_value, "percent"),
      agg(paste(label, "as Fraction of Rows"), "fraction", measure, "row", needs_value, "percent"),
      agg(paste(label, "as Fraction of Columns"), "fraction", measure, "col", needs_value, "percent")
    )
  }

  rbind(
    agg("Count", "count", needs_value = FALSE, format = "integer"),
    agg("Count unique", "count_unique", format = "integer"),
    agg("List unique values", "list", format = "text"),

    agg("N non-missing", "n", "non_missing", format = "integer"),
    agg("N missing", "n", "missing", format = "integer"),
    pct("Non-missing", "non_missing"),
    pct("Missing", "missing"),

    agg("N zero", "n", "zero", format = "integer"),
    agg("N non-zero", "n", "non_zero", format = "integer"),
    pct("Zero", "zero"),
    pct("Non-zero", "non_zero"),

    agg("Mean", "stat"),
    agg("Median", "stat"),
    agg("Sum", "stat"),
    fraction("Sum", "sum", needs_value = TRUE),
    fraction("Count", "count", needs_value = FALSE),
    agg("Min", "stat"),
    agg("Max", "stat"),
    agg("Range", "stat"),
    agg("Variance", "stat"),
    agg("SD", "stat"),
    agg("SE", "stat"),
    agg("CV %", "stat", format = "percent"),
    agg("Q1", "stat"),
    agg("Q3", "stat"),
    agg("IQR", "stat")
  )
}

# Older names still accepted from R code.
safe_pivot_aggregator_aliases <- function() {
  c(
    "Missing %" = "Missing % within Cell",
    "Non-missing %" = "Non-missing % within Cell"
  )
}

safe_pivot_normalize_aggregator <- function(aggregator) {
  aggregator <- as.character(aggregator)[[1]]
  aliases <- safe_pivot_aggregator_aliases()

  if (aggregator %in% names(aliases)) {
    return(unname(aliases[[aggregator]]))
  }

  aggregator
}

# Names accepted by `aggregator =`: every registry name plus the aliases.
safe_pivot_allowed_aggregators <- function() {
  c(safe_pivot_aggregator_registry()$name, names(safe_pivot_aggregator_aliases()))
}

# One registry row as a list, or NULL for an unknown name.
safe_pivot_aggregator_spec <- function(aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)
  reg <- safe_pivot_aggregator_registry()
  i <- match(aggregator, reg$name)

  if (is.na(i)) {
    return(NULL)
  }

  as.list(reg[i, , drop = FALSE])
}

safe_pivot_aggregator_family <- function(aggregator) {
  spec <- safe_pivot_aggregator_spec(aggregator)
  if (is.null(spec)) NA_character_ else spec$family
}

safe_pivot_is_fraction_aggregator <- function(aggregator) {
  identical(safe_pivot_aggregator_family(aggregator), "fraction")
}

safe_pivot_is_context_percent_aggregator <- function(aggregator) {
  spec <- safe_pivot_aggregator_spec(aggregator)
  !is.null(spec) && spec$family == "percent" && spec$scope != "cell"
}

# Fraction aggregators are built from Sum or Count; others are their own base.
safe_pivot_fraction_base <- function(aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)
  spec <- safe_pivot_aggregator_spec(aggregator)

  if (!is.null(spec) && spec$family == "fraction") {
    return(if (spec$measure == "sum") "Sum" else "Count")
  }

  aggregator
}

safe_pivot_requires_value <- function(aggregator) {
  spec <- safe_pivot_aggregator_spec(aggregator)
  is.null(spec) || isTRUE(spec$needs_value)
}

# Registry rows sent to the browser widget.
safe_pivot_aggregator_info_for_js <- function() {
  reg <- safe_pivot_aggregator_registry()
  lapply(seq_len(nrow(reg)), function(i) {
    row <- as.list(reg[i, , drop = FALSE])
    row[is.na(row)] <- list(NULL)
    row
  })
}


# ------------------------------------------------------------
# Per-cell computation
# ------------------------------------------------------------

# Count of missing / non_missing / zero / non_zero values.
safe_pivot_count_measure <- function(x, measure) {
  switch(
    measure,
    missing = safe_pivot_count_missing(x),
    non_missing = safe_pivot_count_non_missing(x),
    zero = safe_pivot_count_zero(x),
    non_zero = safe_pivot_count_non_zero(x),
    stop("Unknown measure: ", measure, call. = FALSE)
  )
}

# Denominator for a measure: all records for (non-)missing, numeric
# values for (non-)zero.
safe_pivot_measure_denominator <- function(x, measure) {
  if (measure %in% c("missing", "non_missing")) {
    safe_pivot_count_all(x)
  } else {
    safe_pivot_count_numeric(x)
  }
}

safe_agg_vector <- function(x, aggregator) {
  aggregator <- safe_pivot_normalize_aggregator(aggregator)
  spec <- safe_pivot_aggregator_spec(aggregator)

  if (is.null(spec) || spec$family == "fraction" ||
      (spec$family == "percent" && spec$scope != "cell")) {
    stop("Unsupported aggregator: ", aggregator, call. = FALSE)
  }

  if (spec$family == "count") {
    return(length(x))
  }

  if (spec$family == "count_unique") {
    x2 <- x[!safe_pivot_is_missing_value(x)]
    return(length(unique(x2)))
  }

  if (spec$family == "list") {
    x2 <- as.character(x)
    x2 <- x2[!safe_pivot_is_missing_value(x2)]
    return(paste(sort(unique(x2)), collapse = ", "))
  }

  if (spec$family == "n") {
    return(safe_pivot_count_measure(x, spec$measure))
  }

  if (spec$family == "percent") {
    return(
      safe_pivot_pct(
        safe_pivot_count_measure(x, spec$measure),
        safe_pivot_measure_denominator(x, spec$measure)
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
