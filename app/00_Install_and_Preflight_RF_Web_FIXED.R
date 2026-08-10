# ============================================================================
# Portable package install + preflight for the locked RF Shiny calculator
# Run from the repository root OR from the app/ directory.
# ============================================================================

app_dir <- if (file.exists(file.path("app", "global.R"))) "app" else "."
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
setwd(app_dir)

needed <- c("shiny", "caret", "randomForest")
missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing)

cat("R version:\n")
print(R.version.string)
cat("\nPackage versions:\n")
for (p in needed) cat(sprintf("%-15s %s\n", p, as.character(packageVersion(p))))

source("global.R", local = .GlobalEnv)

cat("\nLocked model checks:\n")
cat("Final predictors:", length(bundle$final_vars), "\n")
cat("Predictors:", paste(bundle$final_vars, collapse = ", "), "\n")
cat("Threshold:", bundle$threshold, "\n")
cat("Positive class:", bundle$positive_class, "\n")
cat("Model method:", bundle$model$method, "\n")

stopifnot(length(bundle$final_vars) == 9L)
stopifnot(abs(as.numeric(bundle$threshold) - 0.3228) < 1e-8)
stopifnot(as.character(bundle$positive_class) == "Yes")

example <- data.frame(
  Coffee_consumption = "1",
  Sports_status = "1",
  AHI = 27.1,
  MSaO2 = 92.6,
  Depressive_symptoms_total_score = 8,
  Anxiety_total_score = 12,
  Drowsiness_total_score = 12,
  Stress_total_score = 33,
  Sleep_quality_total_score = 11,
  stringsAsFactors = FALSE
)

p <- predict_mci_probability(bundle, example)
cat(sprintf("Example probability: %.8f (%.2f%%)\n", p, 100 * p))
cat("Recommendation:", classify_for_prioritization(p, bundle), "\n")
cat("\nPRE-FLIGHT PASSED.\n")
