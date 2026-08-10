# ============================================================================
# Run the final RF Shiny app locally in R/RStudio.
# Run from the repository root OR from the app/ directory.
# ============================================================================
if (!requireNamespace("shiny", quietly = TRUE)) install.packages("shiny")
app_dir <- if (file.exists(file.path("app", "global.R"))) "app" else "."
shiny::runApp(appDir = app_dir, launch.browser = TRUE)
