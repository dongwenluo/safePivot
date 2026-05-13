test_that("safe_pivot_compute handles basic numeric aggregators", {
  dat <- data.frame(
    grp = c("A", "A", "B", "B"),
    y = c(1, 3, 10, 14)
  )
  
  res_mean <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "Mean"
  )
  
  expect_equal(res_mean$wide$.value[res_mean$wide$grp == "A"], 2)
  expect_equal(res_mean$wide$.value[res_mean$wide$grp == "B"], 12)
  
  res_median <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "Median"
  )
  
  expect_equal(res_median$wide$.value[res_median$wide$grp == "A"], 2)
  expect_equal(res_median$wide$.value[res_median$wide$grp == "B"], 12)
  
  res_iqr <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "IQR"
  )
  
  expect_equal(res_iqr$wide$.value[res_iqr$wide$grp == "A"], stats::IQR(c(1, 3)))
  expect_equal(res_iqr$wide$.value[res_iqr$wide$grp == "B"], stats::IQR(c(10, 14)))
})


test_that("safe_pivot_compute handles missing values", {
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
  
  expect_equal(res_missing$wide$.value[res_missing$wide$grp == "A"], 1)
  expect_equal(res_missing$wide$.value[res_missing$wide$grp == "B"], 0)
  expect_equal(res_missing$wide$.value[res_missing$wide$grp == "(Missing)"], 1)
  
  res_missing_pct <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "y",
    aggregator = "Missing %",
    missing_label = "(Missing)",
    show_missing_category = TRUE
  )
  
  expect_equal(res_missing_pct$wide$.value[res_missing_pct$wide$grp == "A"], 50)
  expect_equal(res_missing_pct$wide$.value[res_missing_pct$wide$grp == "B"], 0)
  expect_equal(res_missing_pct$wide$.value[res_missing_pct$wide$grp == "(Missing)"], 100)
})


test_that("safe_pivot_compute handles unique value aggregators", {
  dat <- data.frame(
    grp = c("A", "A", "A", "B", "B"),
    label = c("x", "y", "x", "z", NA)
  )
  
  res_count_unique <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "label",
    aggregator = "Count unique"
  )
  
  expect_equal(res_count_unique$wide$.value[res_count_unique$wide$grp == "A"], 2)
  expect_equal(res_count_unique$wide$.value[res_count_unique$wide$grp == "B"], 2)
  
  res_list_unique <- safe_pivot_compute(
    dat,
    rows = "grp",
    vals = "label",
    aggregator = "List unique values"
  )
  
  expect_equal(res_list_unique$wide$.value[res_list_unique$wide$grp == "A"], "x, y")
  expect_equal(res_list_unique$wide$.value[res_list_unique$wide$grp == "B"], "(Missing), z")
})


test_that("safe_pivot_compute handles sum fraction aggregators", {
  dat <- data.frame(
    grp = c("A", "A", "B", "B"),
    col = c("X", "Y", "X", "Y"),
    y = c(1, 3, 2, 4)
  )
  
  res_total <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    vals = "y",
    aggregator = "Sum as Fraction of Total"
  )
  
  expect_equal(res_total$wide$X[res_total$wide$grp == "A"], 10)
  expect_equal(res_total$wide$Y[res_total$wide$grp == "A"], 30)
  expect_equal(res_total$wide$X[res_total$wide$grp == "B"], 20)
  expect_equal(res_total$wide$Y[res_total$wide$grp == "B"], 40)
  
  res_rows <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    vals = "y",
    aggregator = "Sum as Fraction of Rows"
  )
  
  expect_equal(res_rows$wide$X[res_rows$wide$grp == "A"], 25)
  expect_equal(res_rows$wide$Y[res_rows$wide$grp == "A"], 75)
  expect_equal(res_rows$wide$X[res_rows$wide$grp == "B"], 100 * 2 / 6)
  expect_equal(res_rows$wide$Y[res_rows$wide$grp == "B"], 100 * 4 / 6)
  
  res_cols <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    vals = "y",
    aggregator = "Sum as Fraction of Columns"
  )
  
  expect_equal(res_cols$wide$X[res_cols$wide$grp == "A"], 100 * 1 / 3)
  expect_equal(res_cols$wide$Y[res_cols$wide$grp == "A"], 100 * 3 / 7)
  expect_equal(res_cols$wide$X[res_cols$wide$grp == "B"], 100 * 2 / 3)
  expect_equal(res_cols$wide$Y[res_cols$wide$grp == "B"], 100 * 4 / 7)
})


test_that("safe_pivot_compute handles count fraction aggregators", {
  dat <- data.frame(
    grp = c("A", "A", "B", "B"),
    col = c("X", "Y", "X", "Y"),
    y = c(1, 3, 2, 4)
  )
  
  res_total <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    aggregator = "Count as Fraction of Total"
  )
  
  expect_equal(res_total$wide$X[res_total$wide$grp == "A"], 25)
  expect_equal(res_total$wide$Y[res_total$wide$grp == "A"], 25)
  expect_equal(res_total$wide$X[res_total$wide$grp == "B"], 25)
  expect_equal(res_total$wide$Y[res_total$wide$grp == "B"], 25)
  
  res_rows <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    aggregator = "Count as Fraction of Rows"
  )
  
  expect_equal(res_rows$wide$X[res_rows$wide$grp == "A"], 50)
  expect_equal(res_rows$wide$Y[res_rows$wide$grp == "A"], 50)
  expect_equal(res_rows$wide$X[res_rows$wide$grp == "B"], 50)
  expect_equal(res_rows$wide$Y[res_rows$wide$grp == "B"], 50)
  
  res_cols <- safe_pivot_compute(
    dat,
    rows = "grp",
    cols = "col",
    aggregator = "Count as Fraction of Columns"
  )
  
  expect_equal(res_cols$wide$X[res_cols$wide$grp == "A"], 50)
  expect_equal(res_cols$wide$Y[res_cols$wide$grp == "A"], 50)
  expect_equal(res_cols$wide$X[res_cols$wide$grp == "B"], 50)
  expect_equal(res_cols$wide$Y[res_cols$wide$grp == "B"], 50)
})


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
  
  expect_true(is.list(res))
  expect_true(all(c("long", "wide", "config") %in% names(res)))
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
  
  expect_true(is.list(res))
  expect_true(all(c("long", "wide", "config") %in% names(res)))
  expect_equal(res$config$rows, "Species")
  expect_equal(res$config$vals, "Sepal.Length")
  expect_equal(res$config$aggregator, "Median")
})


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
  expect_true(all(c("long", "wide", "config") %in% names(rds_read)))
  
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
  
  skip_if_not_installed("openxlsx")
  
  safe_pivot_write_xlsx(res, xlsx_file)
  expect_true(file.exists(xlsx_file))
  expect_gt(file.info(xlsx_file)$size, 0)
})
