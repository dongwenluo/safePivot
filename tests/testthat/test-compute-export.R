# Tests for safePivot computation and export helpers
#
# This file is intentionally focused on:
# - matching browser-side safePivot aggregation semantics
# - distinguishing empty cells, observed missing values, and numeric zero values
# - checking all aggregator families, including row/column/total percentages
# - checking count-fraction aggregators when rows/cols/vals are empty
# - checking export helpers

# -------------------------------------------------------------------------
# Test helpers
# -------------------------------------------------------------------------

expect_safe_pivot_result <- function(res) {
  expect_true(is.list(res))
  expect_true(all(c("long", "wide", "config") %in% names(res)))
  expect_s3_class(res$long, "data.frame")
  expect_s3_class(res$wide, "data.frame")
  expect_true(is.list(res$config))
}

get_cell <- function(wide, row_value, col_name, row_col = "grp") {
  expect_true(row_col %in% names(wide))
  expect_true(col_name %in% names(wide))

  out <- wide[[col_name]][wide[[row_col]] == row_value]
  expect_length(out, 1)

  out
}

expect_cell_equal <- function(wide, row_value, col_name, expected, row_col = "grp", tolerance = 1e-8) {
  actual <- get_cell(wide, row_value, col_name, row_col = row_col)
  expect_equal(actual, expected, tolerance = tolerance)
}

expect_cell_na <- function(wide, row_value, col_name, row_col = "grp") {
  actual <- get_cell(wide, row_value, col_name, row_col = row_col)
  expect_true(is.na(actual))
}

expect_value_equal <- function(wide, expected, tolerance = 1e-8) {
  expect_true(".value" %in% names(wide))
  expect_equal(wide$.value, expected, tolerance = tolerance)
}

quality_dat <- function() {
  data.frame(
    row = c("A", "A", "A", "B", "B", "C"),
    col = c("X", "X", "Y", "X", "Y", "X"),
    y = c(0, 1, NA, 0, 5, NA)
  )
}

fraction_dat <- function() {
  data.frame(
    grp = c("A", "A", "B", "B"),
    col = c("X", "Y", "X", "Y"),
    y = c(1, 3, 2, 4)
  )
}


# -------------------------------------------------------------------------
# Basic numeric aggregators
# -------------------------------------------------------------------------

test_that("safe_pivot_compute handles all basic numeric aggregators", {
  dat <- data.frame(
    grp = rep("A", 4),
    y = c(1, 3, 10, 14)
  )

  expected <- list(
    "Count" = 4,
    "Sum" = sum(dat$y),
    "Mean" = mean(dat$y),
    "Median" = stats::median(dat$y),
    "Min" = min(dat$y),
    "Max" = max(dat$y),
    "Range" = max(dat$y) - min(dat$y),
    "Variance" = stats::var(dat$y),
    "SD" = stats::sd(dat$y),
    "SE" = stats::sd(dat$y) / sqrt(length(dat$y)),
    "CV %" = 100 * stats::sd(dat$y) / mean(dat$y),
    "Q1" = as.numeric(stats::quantile(dat$y, probs = 0.25, names = FALSE, type = 7)),
    "Q3" = as.numeric(stats::quantile(dat$y, probs = 0.75, names = FALSE, type = 7)),
    "IQR" = stats::IQR(dat$y)
  )

  for (agg in names(expected)) {
    res <- safe_pivot_compute(
      dat,
      rows = "grp",
      vals = "y",
      aggregator = agg
    )

    expect_safe_pivot_result(res)
    expect_equal(
      res$wide$.value[res$wide$grp == "A"],
      expected[[agg]],
      tolerance = 1e-8,
      info = paste("Aggregator:", agg)
    )
  }
})


test_that("safe_pivot_compute returns NA for numeric aggregators when no finite numeric values exist", {
  dat <- data.frame(
    grp = c("A", "A", "B"),
    y = c(NA, NA, "not numeric")
  )

  for (agg in c("Sum", "Mean", "Median", "Min", "Max", "Range", "Variance", "SD", "SE", "CV %", "Q1", "Q3", "IQR")) {
    res <- safe_pivot_compute(
      dat,
      rows = "grp",
      vals = "y",
      aggregator = agg
    )

    expect_safe_pivot_result(res)
    expect_true(
      all(is.na(res$wide$.value)),
      info = paste("Aggregator:", agg)
    )
  }
})


# -------------------------------------------------------------------------
# Missing values, blanks, and aliases
# -------------------------------------------------------------------------

test_that("safe_pivot_compute handles observed missing values and missing aliases", {
  dat <- data.frame(
    grp = c("A", "A", "B", NA),
    y = c(1, NA, 3, NA)
  )

  res_missing <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "N missing",
    missing_label = "(Missing)",
    show_missing_category = TRUE
  )

  expect_safe_pivot_result(res_missing)
  expect_equal(res_missing$wide$.value[res_missing$wide$grp == "A"], 1)
  expect_equal(res_missing$wide$.value[res_missing$wide$grp == "B"], 0)
  expect_equal(res_missing$wide$.value[res_missing$wide$grp == "(Missing)"], 1)

  res_missing_pct_alias <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "Missing %",
    missing_label = "(Missing)",
    show_missing_category = TRUE
  )

  expect_equal(res_missing_pct_alias$config$aggregator, "Missing % within Cell")
  expect_equal(res_missing_pct_alias$wide$.value[res_missing_pct_alias$wide$grp == "A"], 50)
  expect_equal(res_missing_pct_alias$wide$.value[res_missing_pct_alias$wide$grp == "B"], 0)
  expect_equal(res_missing_pct_alias$wide$.value[res_missing_pct_alias$wide$grp == "(Missing)"], 100)

  res_non_missing_pct_alias <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "Non-missing %",
    missing_label = "(Missing)",
    show_missing_category = TRUE
  )

  expect_equal(res_non_missing_pct_alias$config$aggregator, "Non-missing % within Cell")
  expect_equal(res_non_missing_pct_alias$wide$.value[res_non_missing_pct_alias$wide$grp == "A"], 50)
  expect_equal(res_non_missing_pct_alias$wide$.value[res_non_missing_pct_alias$wide$grp == "B"], 100)
  expect_equal(res_non_missing_pct_alias$wide$.value[res_non_missing_pct_alias$wide$grp == "(Missing)"], 0)
})


test_that("safe_pivot_compute treats blank-like value strings as missing", {
  dat <- data.frame(
    grp = rep("A", 9),
    y = c("1", "", "NA", "NaN", "null", "undefined", "-", NA, "0"),
    stringsAsFactors = FALSE
  )

  n_missing <- safe_pivot_compute(dat, rows = "grp", vals = "y", aggregator = "N missing")
  n_non_missing <- safe_pivot_compute(dat, rows = "grp", vals = "y", aggregator = "N non-missing")
  zero_count <- safe_pivot_compute(dat, rows = "grp", vals = "y", aggregator = "N zero")

  expect_equal(n_missing$wide$.value[n_missing$wide$grp == "A"], 7)
  expect_equal(n_non_missing$wide$.value[n_non_missing$wide$grp == "A"], 2)
  expect_equal(zero_count$wide$.value[zero_count$wide$grp == "A"], 1)
})


# -------------------------------------------------------------------------
# Unique-value aggregators
# -------------------------------------------------------------------------

test_that("safe_pivot_compute handles unique-value aggregators and excludes missing values", {
  dat <- data.frame(
    grp = c("A", "A", "A", "B", "B", "B"),
    label = c("x", "y", "x", "z", NA, ""),
    stringsAsFactors = FALSE
  )

  res_count_unique <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "label",
    aggregator = "Count unique"
  )

  expect_equal(res_count_unique$wide$.value[res_count_unique$wide$grp == "A"], 2)
  expect_equal(res_count_unique$wide$.value[res_count_unique$wide$grp == "B"], 1)

  res_list_unique <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "label",
    aggregator = "List unique values"
  )

  expect_equal(res_list_unique$wide$.value[res_list_unique$wide$grp == "A"], "x, y")
  expect_equal(res_list_unique$wide$.value[res_list_unique$wide$grp == "B"], "z")
})


# -------------------------------------------------------------------------
# Sum and count fractions
# -------------------------------------------------------------------------

test_that("safe_pivot_compute handles sum fraction aggregators with rows and columns", {
  dat <- fraction_dat()

  res_total <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    vals = "y",
    aggregator = "Sum as Fraction of Total"
  )

  expect_cell_equal(res_total$wide, "A", "X", 10)
  expect_cell_equal(res_total$wide, "A", "Y", 30)
  expect_cell_equal(res_total$wide, "B", "X", 20)
  expect_cell_equal(res_total$wide, "B", "Y", 40)

  res_rows <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    vals = "y",
    aggregator = "Sum as Fraction of Rows"
  )

  expect_cell_equal(res_rows$wide, "A", "X", 25)
  expect_cell_equal(res_rows$wide, "A", "Y", 75)
  expect_cell_equal(res_rows$wide, "B", "X", 100 * 2 / 6)
  expect_cell_equal(res_rows$wide, "B", "Y", 100 * 4 / 6)

  res_cols <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    vals = "y",
    aggregator = "Sum as Fraction of Columns"
  )

  expect_cell_equal(res_cols$wide, "A", "X", 100 * 1 / 3)
  expect_cell_equal(res_cols$wide, "B", "X", 100 * 2 / 3)
  expect_cell_equal(res_cols$wide, "A", "Y", 100 * 3 / 7)
  expect_cell_equal(res_cols$wide, "B", "Y", 100 * 4 / 7)
})


test_that("safe_pivot_compute handles count fraction aggregators with rows and columns", {
  dat <- fraction_dat()

  count_total <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    aggregator = "Count as Fraction of Total"
  )

  expect_cell_equal(count_total$wide, "A", "X", 25)
  expect_cell_equal(count_total$wide, "A", "Y", 25)
  expect_cell_equal(count_total$wide, "B", "X", 25)
  expect_cell_equal(count_total$wide, "B", "Y", 25)

  count_rows <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    aggregator = "Count as Fraction of Rows"
  )

  expect_cell_equal(count_rows$wide, "A", "X", 50)
  expect_cell_equal(count_rows$wide, "A", "Y", 50)
  expect_cell_equal(count_rows$wide, "B", "X", 50)
  expect_cell_equal(count_rows$wide, "B", "Y", 50)

  count_cols <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    aggregator = "Count as Fraction of Columns"
  )

  expect_cell_equal(count_cols$wide, "A", "X", 50)
  expect_cell_equal(count_cols$wide, "B", "X", 50)
  expect_cell_equal(count_cols$wide, "A", "Y", 50)
  expect_cell_equal(count_cols$wide, "B", "Y", 50)
})


test_that("safe_pivot_compute handles fraction aggregators when cols is empty", {
  dat <- fraction_dat()

  sum_total <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "Sum as Fraction of Total"
  )

  expect_equal(sum_total$wide$.value[sum_total$wide$grp == "A"], 40)
  expect_equal(sum_total$wide$.value[sum_total$wide$grp == "B"], 60)

  sum_rows <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "Sum as Fraction of Rows"
  )

  expect_equal(sum_rows$wide$.value[sum_rows$wide$grp == "A"], 100)
  expect_equal(sum_rows$wide$.value[sum_rows$wide$grp == "B"], 100)

  count_total <- safe_pivot_compute(
    dat,
    rows = "grp",
    aggregator = "Count as Fraction of Total"
  )

  expect_equal(count_total$wide$.value[count_total$wide$grp == "A"], 50)
  expect_equal(count_total$wide$.value[count_total$wide$grp == "B"], 50)

  count_rows <- safe_pivot_compute(
    dat,
    rows = "grp",
    aggregator = "Count as Fraction of Rows"
  )

  expect_equal(count_rows$wide$.value[count_rows$wide$grp == "A"], 100)
  expect_equal(count_rows$wide$.value[count_rows$wide$grp == "B"], 100)
})


test_that("safe_pivot_compute handles fraction aggregators when rows is empty", {
  dat <- fraction_dat()

  sum_total <- safe_pivot_compute(
    dat,
    cols = "col",
    vals = "y",
    aggregator = "Sum as Fraction of Total"
  )

  expect_equal(sum_total$wide$X, 30)
  expect_equal(sum_total$wide$Y, 70)

  sum_cols <- safe_pivot_compute(
    dat,
    cols = "col",
    vals = "y",
    aggregator = "Sum as Fraction of Columns"
  )

  expect_equal(sum_cols$wide$X, 100)
  expect_equal(sum_cols$wide$Y, 100)

  count_total <- safe_pivot_compute(
    dat,
    cols = "col",
    aggregator = "Count as Fraction of Total"
  )

  expect_equal(count_total$wide$X, 50)
  expect_equal(count_total$wide$Y, 50)

  count_cols <- safe_pivot_compute(
    dat,
    cols = "col",
    aggregator = "Count as Fraction of Columns"
  )

  expect_equal(count_cols$wide$X, 100)
  expect_equal(count_cols$wide$Y, 100)
})


test_that("safe_pivot_compute fixes count fraction with rows and no cols", {
  res <- safe_pivot_compute(
    iris,
    rows = "Species",
    vals = "Sepal.Length",
    aggregator = "Count as Fraction of Total"
  )

  expect_safe_pivot_result(res)
  expect_equal(
    res$wide$.value[res$wide$Species == "setosa"],
    100 * 50 / 150,
    tolerance = 1e-8
  )
  expect_equal(
    res$wide$.value[res$wide$Species == "versicolor"],
    100 * 50 / 150,
    tolerance = 1e-8
  )
  expect_equal(
    res$wide$.value[res$wide$Species == "virginica"],
    100 * 50 / 150,
    tolerance = 1e-8
  )
})


# -------------------------------------------------------------------------
# Empty cells, missing cells, and zero cells
# -------------------------------------------------------------------------

test_that("safe_pivot_compute distinguishes empty cells from observed missing values", {
  dat <- quality_dat()

  count_res <- safe_pivot_compute(
    dat,
    rows = "row",
    cols = "col",
    vals = "y",
    aggregator = "Count"
  )

  expect_cell_equal(count_res$wide, "A", "X", 2, row_col = "row")
  expect_cell_equal(count_res$wide, "A", "Y", 1, row_col = "row")
  expect_cell_equal(count_res$wide, "B", "X", 1, row_col = "row")
  expect_cell_equal(count_res$wide, "B", "Y", 1, row_col = "row")
  expect_cell_equal(count_res$wide, "C", "X", 1, row_col = "row")

  # C x Y does not exist in the data.
  expect_cell_na(count_res$wide, "C", "Y", row_col = "row")

  missing_count <- safe_pivot_compute(
    dat,
    rows = "row",
    cols = "col",
    vals = "y",
    aggregator = "N missing"
  )

  expect_cell_equal(missing_count$wide, "A", "X", 0, row_col = "row")
  expect_cell_equal(missing_count$wide, "A", "Y", 1, row_col = "row")
  expect_cell_equal(missing_count$wide, "C", "X", 1, row_col = "row")
  expect_cell_na(missing_count$wide, "C", "Y", row_col = "row")

  non_missing_count <- safe_pivot_compute(
    dat,
    rows = "row",
    cols = "col",
    vals = "y",
    aggregator = "N non-missing"
  )

  expect_cell_equal(non_missing_count$wide, "A", "X", 2, row_col = "row")
  expect_cell_equal(non_missing_count$wide, "A", "Y", 0, row_col = "row")
  expect_cell_equal(non_missing_count$wide, "C", "X", 0, row_col = "row")
  expect_cell_na(non_missing_count$wide, "C", "Y", row_col = "row")
})


test_that("safe_pivot_compute handles within-cell missing and zero percentages", {
  dat <- quality_dat()

  missing_within <- safe_pivot_compute(
    dat,
    rows = "row",
    cols = "col",
    vals = "y",
    aggregator = "Missing % within Cell"
  )

  expect_cell_equal(missing_within$wide, "A", "X", 0, row_col = "row")
  expect_cell_equal(missing_within$wide, "A", "Y", 100, row_col = "row")
  expect_cell_equal(missing_within$wide, "C", "X", 100, row_col = "row")
  expect_cell_na(missing_within$wide, "C", "Y", row_col = "row")

  zero_within <- safe_pivot_compute(
    dat,
    rows = "row",
    cols = "col",
    vals = "y",
    aggregator = "Zero % within Cell"
  )

  expect_cell_equal(zero_within$wide, "A", "X", 50, row_col = "row")
  expect_true(is.na(get_cell(zero_within$wide, "A", "Y", row_col = "row")))
  expect_cell_equal(zero_within$wide, "B", "X", 100, row_col = "row")
  expect_cell_equal(zero_within$wide, "B", "Y", 0, row_col = "row")
  expect_true(is.na(get_cell(zero_within$wide, "C", "X", row_col = "row")))
  expect_cell_na(zero_within$wide, "C", "Y", row_col = "row")
})


test_that("safe_pivot_compute handles row, column, and total context percentages", {
  dat <- quality_dat()

  missing_row <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Missing % of Row")
  missing_col <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Missing % of Column")
  missing_total <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Missing % of Total")

  expect_cell_equal(missing_row$wide, "A", "Y", 100 * 1 / 3, row_col = "row")
  expect_cell_equal(missing_col$wide, "A", "Y", 100 * 1 / 2, row_col = "row")
  expect_cell_equal(missing_total$wide, "A", "Y", 100 * 1 / 6, row_col = "row")

  non_missing_row <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Non-missing % of Row")
  non_missing_col <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Non-missing % of Column")
  non_missing_total <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Non-missing % of Total")

  expect_cell_equal(non_missing_row$wide, "A", "X", 100 * 2 / 3, row_col = "row")
  expect_cell_equal(non_missing_col$wide, "B", "Y", 100 * 1 / 2, row_col = "row")
  expect_cell_equal(non_missing_total$wide, "B", "Y", 100 * 1 / 6, row_col = "row")

  zero_row <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Zero % of Row")
  zero_col <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Zero % of Column")
  zero_total <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Zero % of Total")

  expect_cell_equal(zero_row$wide, "A", "X", 50, row_col = "row")
  expect_cell_equal(zero_row$wide, "A", "Y", 0, row_col = "row")
  expect_cell_equal(zero_col$wide, "A", "X", 100 * 1 / 3, row_col = "row")
  expect_cell_equal(zero_total$wide, "B", "X", 100 * 1 / 4, row_col = "row")
  expect_cell_na(zero_total$wide, "C", "Y", row_col = "row")

  non_zero_row <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Non-zero % of Row")
  non_zero_col <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Non-zero % of Column")
  non_zero_total <- safe_pivot_compute(dat, rows = "row", cols = "col", vals = "y", aggregator = "Non-zero % of Total")

  expect_cell_equal(non_zero_row$wide, "A", "X", 50, row_col = "row")
  expect_cell_equal(non_zero_col$wide, "B", "Y", 100, row_col = "row")
  expect_cell_equal(non_zero_total$wide, "B", "Y", 100 * 1 / 4, row_col = "row")
})


# -------------------------------------------------------------------------
# Coverage over all declared aggregators
# -------------------------------------------------------------------------

test_that("every allowed aggregator can be computed with an appropriate setup", {
  dat <- data.frame(
    grp = c("A", "A", "B", "B", "C"),
    col = c("X", "Y", "X", "Y", "X"),
    y = c(1, 0, 2, NA, 4),
    label = c("a", "b", "a", NA, "c"),
    stringsAsFactors = FALSE
  )

  count_without_value <- c(
    "Count",
    "Count as Fraction of Total",
    "Count as Fraction of Rows",
    "Count as Fraction of Columns"
  )

  text_value <- c("Count unique", "List unique values")

  for (agg in safe_pivot_allowed_aggregators()) {
    vals <- if (agg %in% count_without_value) {
      NULL
    } else if (agg %in% text_value) {
      "label"
    } else {
      "y"
    }

    expect_error(
      safe_pivot_compute(
        dat,
        rows = "grp",
        cols = "col",
        vals = vals,
        aggregator = agg
      ),
      regexp = NA
    )
  }
})


# -------------------------------------------------------------------------
# Config parsing
# -------------------------------------------------------------------------

test_that("safe_pivot_compute_from_config handles Shiny-style config lists", {
  cfg <- list(
    rows = list("Species"),
    cols = list(),
    vals = list("Sepal.Length"),
    aggregatorName = "Median",
    rendererName = "Table"
  )

  res <- safe_pivot_compute_from_config(
    iris,
    config = cfg,
    default_rows = "Species",
    default_vals = "Sepal.Length",
    default_aggregator = "Median"
  )

  expect_safe_pivot_result(res)
  expect_equal(res$config$rows, "Species")
  expect_equal(res$config$vals, "Sepal.Length")
  expect_equal(res$config$aggregator, "Median")
})


test_that("safe_pivot_compute_from_config uses defaults when config is NULL", {
  res <- safe_pivot_compute_from_config(
    iris,
    config = NULL,
    default_rows = "Species",
    default_vals = "Sepal.Length",
    default_aggregator = "Median"
  )

  expect_safe_pivot_result(res)
  expect_equal(res$config$rows, "Species")
  expect_equal(res$config$vals, "Sepal.Length")
  expect_equal(res$config$aggregator, "Median")
})


test_that("safe_pivot_compute_from_config falls back to defaults for empty config fields", {
  cfg <- list(
    rows = list(),
    cols = list(),
    vals = list(),
    aggregatorName = NULL
  )

  res <- safe_pivot_compute_from_config(
    iris,
    config = cfg,
    default_rows = "Species",
    default_vals = "Sepal.Length",
    default_aggregator = "Mean"
  )

  expect_safe_pivot_result(res)
  expect_equal(res$config$rows, "Species")
  expect_equal(res$config$vals, "Sepal.Length")
  expect_equal(res$config$aggregator, "Mean")
})


# -------------------------------------------------------------------------
# Error handling
# -------------------------------------------------------------------------

test_that("safe_pivot_compute rejects unsupported aggregators and invalid inputs", {
  expect_error(
    safe_pivot_compute(
      iris,
      rows = "Species",
      vals = "Sepal.Length",
      aggregator = "Not an aggregator"
    ),
    "Unsupported aggregator"
  )

  expect_error(
    safe_pivot_compute(
      iris,
      rows = "Species",
      aggregator = "Mean"
    ),
    "`vals` is required|requires exactly one value column"
  )

  expect_error(
    safe_pivot_compute(
      iris,
      rows = "Species",
      aggregator = "Sum as Fraction of Total"
    ),
    "requires exactly one value column|`vals` is required"
  )

  expect_error(
    safe_pivot_compute(
      iris,
      rows = "not_a_column",
      vals = "Sepal.Length",
      aggregator = "Mean"
    ),
    "not_a_column|column"
  )

  expect_error(
    safe_pivot_compute(
      iris,
      rows = "Species",
      vals = "not_a_column",
      aggregator = "Mean"
    ),
    "not_a_column|column"
  )
})


test_that("safePivot rejects unsupported renderers", {
  expect_error(
    safePivot(
      iris,
      rows = "Species",
      vals = "Sepal.Length",
      aggregator = "Mean",
      renderer = "Bad Renderer"
    ),
    "Unsupported renderer"
  )
})


test_that("safePivot carries renderer, heatmap, and Plotly options to the widget", {
  w_heatmap <- safePivot(
    iris,
    rows = "Species",
    vals = "Sepal.Length",
    aggregator = "Median",
    renderer = "Heatmap",
    heatmap_palette = "green"
  )

  expect_s3_class(w_heatmap, "htmlwidget")
  expect_equal(w_heatmap$x$renderer, "Heatmap")
  expect_equal(w_heatmap$x$heatmap_palette, "green")

  w_plot <- safePivot(
    iris,
    rows = "Species",
    vals = "Sepal.Length",
    aggregator = "Median",
    renderer = "Bar Chart",
    plot_default_height = 700,
    plot_max_width = 1000,
    plotly_config = list(displayModeBar = TRUE)
  )

  expect_equal(w_plot$x$renderer, "Bar Chart")
  expect_equal(w_plot$x$plot_default_height, 700)
  expect_equal(w_plot$x$plot_max_width, 1000)
  expect_true(is.list(w_plot$x$plotly_config))
})


# -------------------------------------------------------------------------
# Export helpers
# -------------------------------------------------------------------------

test_that("export helpers write CSV, RDS, RData, and Excel files", {
  res <- safe_pivot_compute(
    iris,
    rows = "Species",
    vals = "Sepal.Length",
    aggregator = "Median"
  )

  csv_file <- tempfile(fileext = ".csv")
  rds_file <- tempfile(fileext = ".rds")
  rdata_file <- tempfile(fileext = ".RData")
  xlsx_file <- tempfile(fileext = ".xlsx")

  safe_pivot_write_csv(res, csv_file, which = "wide")
  expect_true(file.exists(csv_file))
  expect_gt(file.info(csv_file)$size, 0)

  csv_read <- utils::read.csv(csv_file, check.names = FALSE)
  expect_true("Species" %in% names(csv_read))

  safe_pivot_write_rds(res, rds_file)
  expect_true(file.exists(rds_file))
  expect_gt(file.info(rds_file)$size, 0)

  rds_read <- readRDS(rds_file)
  expect_safe_pivot_result(rds_read)

  safe_pivot_write_rdata(
    res,
    rdata_file,
    object_name = "safePivot_result"
  )
  expect_true(file.exists(rdata_file))
  expect_gt(file.info(rdata_file)$size, 0)

  env <- new.env(parent = emptyenv())
  load(rdata_file, envir = env)
  expect_true(exists("safePivot_result", envir = env))
  expect_safe_pivot_result(get("safePivot_result", envir = env))

  skip_if_not_installed("openxlsx")

  safe_pivot_write_xlsx(res, xlsx_file)
  expect_true(file.exists(xlsx_file))
  expect_gt(file.info(xlsx_file)$size, 0)
})


test_that("export helpers validate export options", {
  res <- safe_pivot_compute(
    iris,
    rows = "Species",
    vals = "Sepal.Length",
    aggregator = "Median"
  )

  csv_file <- tempfile(fileext = ".csv")

  expect_error(
    safe_pivot_write_csv(res, csv_file, which = "bad"),
    "which|wide|long"
  )
})


test_that("safe_pivot_prepare_data converts one-observed-level factor to character", {
  iris_one <- droplevels(iris[iris$Species == "setosa", ])
  
  out <- safe_pivot_prepare_data(iris_one)
  
  expect_type(out$Species, "character")
  expect_equal(unique(out$Species), "setosa")
})