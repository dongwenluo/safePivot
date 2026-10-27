# ------------------------------------------------------------------
# Build the HTML pages behind the documentation screenshots.
#
# Usage (from the package root):
#   Rscript tools/doc-figures/figures.R <out_dir>
#   node    tools/doc-figures/shoot.js  <out_dir>
#
# figures.R writes one page per figure plus manifest.json; shoot.js
# (Node + Playwright) screenshots them into man/figures/ (README and
# pkgdown home page) and vignettes/figures/ (articles).
# The widget code here mirrors the examples in README.Rmd and the vignettes.
# ------------------------------------------------------------------

args <- commandArgs(TRUE)
out <- normalizePath(if (length(args)) args[[1]] else tempfile("safePivot-figures"), mustWork = FALSE)
dir.create(out, recursive = TRUE, showWarnings = FALSE)

pkgload::load_all(".", quiet = TRUE)

quality_dat <- data.frame(
  row = c("A", "A", "A", "B", "B", "C"),
  col = c("X", "X", "Y", "X", "Y", "X"),
  y = c(0, 1, NA, 0, 5, NA)
)

badge_dat <- data.frame(
  id = 1:3,
  score = c(1.2, 3.4, 5.6),
  group = factor(c("A", "B", "A")),
  ordered_group = factor(c("low", "medium", "high"),
                         levels = c("low", "medium", "high"), ordered = TRUE),
  name = c("x", "y", "z"),
  flag = c(TRUE, FALSE, TRUE),
  harvest_date = as.Date(c("2026-01-01", "2026-01-02", "2026-01-03")),
  timestamp = as.POSIXct(c("2026-01-01 08:00:00", "2026-01-02 08:00:00",
                           "2026-01-03 08:00:00"))
)

iris2 <- iris
iris2$Species <- factor(iris2$Species, levels = c("virginica", "versicolor", "setosa"))

# name, widget, where it is used, optional action for shoot.js
figures <- list(
  list(name = "basic", targets = c("readme", "vignette"),
       widget = safePivot(iris, rows = "Species", vals = "Sepal.Length",
                          aggregator = "Median", renderer = "Table")),
  list(name = "heatmap", targets = c("readme", "vignette"),
       widget = safePivot(mtcars, rows = "cyl", cols = "gear", vals = "mpg",
                          aggregator = "Mean", renderer = "Heatmap",
                          heatmap_palette = "green")),
  list(name = "chart", targets = c("readme", "vignette"),
       widget = safePivot(mtcars, rows = "cyl", cols = "gear", vals = "mpg",
                          aggregator = "Mean", renderer = "Bar Chart",
                          plot_default_height = 520)),
  list(name = "badges", targets = c("readme", "vignette"), crop = "unused",
       widget = safePivot(badge_dat, vals = "score", aggregator = "Mean",
                          unused_layout = "top")),
  list(name = "factor-order", targets = c("readme"),
       widget = safePivot(iris2, rows = "Species", vals = "Sepal.Length",
                          aggregator = "Median", renderer = "Table",
                          respect_factor_order = TRUE)),
  list(name = "conditional-format", targets = c("readme", "vignette"),
       widget = safePivot(quality_dat, rows = "row", cols = "col", vals = "y",
                          aggregator = "Sum", renderer = "Table",
                          conditional_format = TRUE,
                          conditional_format_mode = "both")),
  list(name = "filters", targets = c("readme", "vignette"), open_filter = "Species",
       widget = safePivot(iris, rows = "Species", vals = "Sepal.Length",
                          aggregator = "Mean", exclusions = list(Species = "setosa"))),
  list(name = "wide-layout", targets = c("readme", "vignette"),
       widget = safePivot(mtcars, rows = "cyl", cols = "gear",
                          unused_layout = "left", aggregator = "Count"))
)

manifest <- lapply(figures, function(f) {
  htmlwidgets::saveWidget(
    f$widget,
    file.path(out, paste0(f$name, ".html")),
    selfcontained = FALSE,
    libdir = "lib",
    background = "white"
  )
  list(name = f$name, targets = as.list(f$targets),
       crop = f$crop %||% "ui", open_filter = f$open_filter %||% "")
})

# Shiny apps: taken from the README / vignette chunks so the picture
# matches the code shown.
extract_chunk <- function(file, marker) {
  lines <- readLines(file)
  starts <- grep("^```\\{r", lines)
  ends <- grep("^```\\s*$", lines)
  for (s in starts) {
    e <- min(ends[ends > s])
    body <- lines[(s + 1):(e - 1)]
    if (any(grepl(marker, body, fixed = TRUE))) return(body)
  }
  stop("chunk not found: ", marker)
}

apps <- list(
  list(name = "shiny-export", targets = list("readme"),
       code = extract_chunk("README.Rmd", "downloadButton(\"download_csv\", \"Download CSV\")")),
  list(name = "shiny-export-app", targets = list("vignette"),
       code = extract_chunk("vignettes/using-safePivot-in-shiny.Rmd", "safePivot export example"))
)

for (a in apps) {
  code <- sub("^shinyApp\\(ui, server\\)$",
              "shiny::runApp(shinyApp(ui, server), port = as.integer(Sys.getenv('PORT')), launch.browser = FALSE)",
              a$code)
  code <- c("pkgload::load_all('.', quiet = TRUE)", code)
  writeLines(code, file.path(out, paste0(a$name, "-app.R")))
  manifest[[length(manifest) + 1]] <- list(name = a$name, targets = a$targets,
                                           crop = "page", open_filter = "",
                                           app = paste0(a$name, "-app.R"))
}

jsonlite::write_json(manifest, file.path(out, "manifest.json"), auto_unbox = TRUE, pretty = TRUE)
cat("Wrote", length(manifest), "figure sources to", out, "\n")
