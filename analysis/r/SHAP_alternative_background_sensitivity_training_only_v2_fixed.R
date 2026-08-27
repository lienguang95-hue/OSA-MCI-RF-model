# ============================================================================
# OSA-MCI locked RF: training-only Kernel SHAP + alternative-background sensitivity
# Purpose:
#   1) Recompute primary SHAP using the LOCKED RF and TRAINING-ONLY background.
#   2) Assess sensitivity to alternative random training backgrounds and background sizes.
#   3) Keep the model, preprocessing, predictor set, and threshold unchanged.
#
# Run this script from the extracted root folder of 1.zip (or any parent folder
# containing the files; the script searches recursively).
# ============================================================================
# v2 FIX: corrected feature-rank sorting and added cache reuse so completed
# Kernel SHAP runs do not need to be recomputed after a downstream error.
# ============================================================================

options(stringsAsFactors = FALSE)
set.seed(2026)

required_pkgs <- c("caret", "randomForest", "kernelshap", "dplyr", "tidyr", "ggplot2", "readr")
missing <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) {
  stop("Please install required package(s) first: ", paste(missing, collapse = ", "))
}

suppressPackageStartupMessages({
  library(caret)
  library(randomForest)
  library(kernelshap)
  library(dplyr)
  library(tidyr)
  library(ggplot2)
  library(readr)
})

# ---------- 1. Locate locked bundle and training data ----------
find_one <- function(pattern, root = getwd()) {
  hits <- list.files(root, pattern = pattern, recursive = TRUE, full.names = TRUE)
  if (length(hits) == 0) stop("Cannot find file matching: ", pattern)
  if (length(hits) > 1) message("Multiple matches found; using: ", hits[1])
  hits[1]
}

bundle_file <- find_one("^AAA_locked_RF_bundle\\.rds$")
train_file  <- find_one("^AAA_训练集_详细完整版\\.csv$")

message("Locked bundle: ", bundle_file)
message("Training data: ", train_file)

bundle <- readRDS(bundle_file)
train_raw <- read.csv(train_file, check.names = FALSE, fileEncoding = "UTF-8-BOM")

EXPECTED_VARS <- c(
  "Coffee_consumption",
  "Sports_status",
  "AHI",
  "MSaO2",
  "Depressive_symptoms_total_score",
  "Anxiety_total_score",
  "Drowsiness_total_score",
  "Stress_total_score",
  "Sleep_quality_total_score"
)

stopifnot(all(EXPECTED_VARS %in% names(train_raw)))
stopifnot(nrow(train_raw) == 280)
stopifnot(all(c("model", "preprocessor", "final_vars", "threshold", "factor_levels", "positive_class") %in% names(bundle)))
stopifnot(setequal(as.character(bundle$final_vars), EXPECTED_VARS))
stopifnot(abs(as.numeric(bundle$threshold) - 0.3228) < 1e-8)
stopifnot(identical(as.character(bundle$positive_class), "Yes"))

# Raw nine-predictor matrix only. No validation data enter SHAP.
X_all <- train_raw[, EXPECTED_VARS, drop = FALSE]
if (anyNA(X_all)) stop("Training nine-predictor matrix contains missing values.")

# Preserve categorical codes as character; locked factor levels are applied below.
X_all$Coffee_consumption <- as.character(X_all$Coffee_consumption)
X_all$Sports_status <- as.character(X_all$Sports_status)

# ---------- 2. Locked prediction helper ----------
prepare_raw_predictors <- function(object, newdata) {
  x <- as.data.frame(newdata)
  x <- x[, object$final_vars, drop = FALSE]
  for (v in intersect(names(object$factor_levels), names(x))) {
    x[[v]] <- factor(as.character(x[[v]]), levels = object$factor_levels[[v]])
    if (anyNA(x[[v]])) stop("Invalid factor level encountered for ", v)
  }
  x
}

apply_locked_preprocessor <- function(object, raw_x) {
  x_design <- as.data.frame(predict(object$preprocessor$dummy, newdata = raw_x))
  missing_cols <- setdiff(object$preprocessor$keep_cols, names(x_design))
  if (length(missing_cols)) for (v in missing_cols) x_design[[v]] <- 0
  x_design[, object$preprocessor$keep_cols, drop = FALSE]
}

predict_locked_prob <- function(object, newdata) {
  raw_x <- prepare_raw_predictors(object, newdata)
  x_design <- apply_locked_preprocessor(object, raw_x)
  out <- predict(object$model, newdata = x_design, type = "prob")
  if (!(object$positive_class %in% colnames(out))) stop("Positive class probability not found.")
  as.numeric(out[, object$positive_class])
}

# Sanity check: probabilities must be deterministic.
p_a <- predict_locked_prob(bundle, X_all[1:10, , drop = FALSE])
p_b <- predict_locked_prob(bundle, X_all[1:10, , drop = FALSE])
stopifnot(isTRUE(all.equal(p_a, p_b, tolerance = 1e-15)))

# ---------- 3. Background specifications ----------
# Primary = n=120, seed=2026, training-only.
# Alternative same-size random backgrounds = seeds 2027-2030.
# Size sensitivity = n=60 and n=180 at seed 2026.
bg_specs <- tibble::tribble(
  ~spec,               ~n_bg, ~seed,
  "n120_seed2026",       120,  2026,
  "n120_seed2027",       120,  2027,
  "n120_seed2028",       120,  2028,
  "n120_seed2029",       120,  2029,
  "n120_seed2030",       120,  2030,
  "n60_seed2026",         60,  2026,
  "n180_seed2026",       180,  2026
)

out_dir <- file.path(getwd(), "SHAP_background_sensitivity_outputs")
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

# Explain ALL 280 training observations so global importance is not affected by
# a second explanation-sample draw. This analysis changes only bg_X.
X_explain <- X_all

run_one <- function(spec, n_bg, seed) {
  cache_file <- file.path(out_dir, paste0(spec, "_kernelshap.rds"))
  bg_rows_file <- file.path(out_dir, paste0(spec, "_background_rows.csv"))

  # Reuse an already-computed Kernel SHAP result when available.
  # This is especially useful if a later summary/export step failed after the
  # expensive SHAP calculations had already completed.
  if (file.exists(cache_file)) {
    message("Loading cached SHAP result: ", spec)
    cached <- readRDS(cache_file)
    S <- as.data.frame(cached$S)
    idx_bg <- cached$idx_bg
    baseline <- cached$baseline
  } else {
    set.seed(seed)
    idx_bg <- sort(sample(seq_len(nrow(X_all)), size = n_bg, replace = FALSE))
    X_bg <- X_all[idx_bg, , drop = FALSE]

    message("Running ", spec, " | background n=", n_bg, " seed=", seed)
    ks <- kernelshap::kernelshap(
      object = bundle,
      X = X_explain,
      bg_X = X_bg,
      pred_fun = function(object, newdata) predict_locked_prob(object, newdata)
    )
    S <- as.data.frame(ks$S)
    baseline <- ks$baseline

    write.csv(data.frame(row_index = idx_bg), bg_rows_file, row.names = FALSE)
    saveRDS(list(spec = spec, n_bg = n_bg, seed = seed, idx_bg = idx_bg, S = S, baseline = baseline),
            cache_file)
  }
  if (!identical(colnames(S), colnames(X_explain))) {
    # Some versions preserve names but possibly reorder; enforce expected order.
    S <- S[, colnames(X_explain), drop = FALSE]
  }

  imp <- tibble(
    spec = spec,
    n_bg = n_bg,
    seed = seed,
    feature = colnames(S),
    mean_abs_shap = vapply(S, function(z) mean(abs(z), na.rm = TRUE), numeric(1))
  ) %>%
    arrange(desc(mean_abs_shap)) %>%
    mutate(rank = row_number())

  # Ensure background indices are available even when loading a cached result.
  if (!file.exists(bg_rows_file)) {
    write.csv(data.frame(row_index = idx_bg), bg_rows_file, row.names = FALSE)
  }

  list(S = S, imp = imp, baseline = baseline, idx_bg = idx_bg)
}

results <- vector("list", nrow(bg_specs))
names(results) <- bg_specs$spec
for (i in seq_len(nrow(bg_specs))) {
  results[[i]] <- run_one(bg_specs$spec[i], bg_specs$n_bg[i], bg_specs$seed[i])
  names(results)[i] <- bg_specs$spec[i]
}

# ---------- 4. Global rank/importance sensitivity ----------
imp_long <- bind_rows(lapply(results, `[[`, "imp"))
write.csv(imp_long, file.path(out_dir, "SHAP_global_importance_by_background.csv"), row.names = FALSE)

primary_name <- "n120_seed2026"
primary_imp <- results[[primary_name]]$imp %>% select(feature, primary_mean_abs_shap = mean_abs_shap, primary_rank = rank)

concordance <- lapply(names(results), function(nm) {
  cur <- results[[nm]]$imp %>% select(feature, mean_abs_shap, rank)
  z <- primary_imp %>% inner_join(cur, by = "feature")
  top3_p <- primary_imp %>% filter(primary_rank <= 3) %>% pull(feature)
  top5_p <- primary_imp %>% filter(primary_rank <= 5) %>% pull(feature)
  top3_c <- cur %>% filter(rank <= 3) %>% pull(feature)
  top5_c <- cur %>% filter(rank <= 5) %>% pull(feature)
  tibble(
    spec = nm,
    n_bg = bg_specs$n_bg[match(nm, bg_specs$spec)],
    seed = bg_specs$seed[match(nm, bg_specs$spec)],
    spearman_rank_vs_primary = suppressWarnings(cor(z$primary_rank, z$rank, method = "spearman")),
    spearman_importance_vs_primary = suppressWarnings(cor(z$primary_mean_abs_shap, z$mean_abs_shap, method = "spearman")),
    top3_overlap_n = length(intersect(top3_p, top3_c)),
    top5_overlap_n = length(intersect(top5_p, top5_c))
  )
}) %>% bind_rows()

write.csv(concordance, file.path(out_dir, "SHAP_background_concordance_summary.csv"), row.names = FALSE)

# Feature-wise variability across all background specifications.
feature_variability <- imp_long %>%
  group_by(feature) %>%
  summarise(
    mean_of_mean_abs_shap = mean(mean_abs_shap),
    sd_of_mean_abs_shap = sd(mean_abs_shap),
    min_mean_abs_shap = min(mean_abs_shap),
    max_mean_abs_shap = max(mean_abs_shap),
    min_rank = min(rank),
    max_rank = max(rank),
    .groups = "drop"
  ) %>%
  mutate(mean_rank_range = (min_rank + max_rank) / 2) %>%
  arrange(mean_rank_range, min_rank, feature)
write.csv(feature_variability, file.path(out_dir, "SHAP_feature_variability_across_backgrounds.csv"), row.names = FALSE)

# ---------- 5. Local-case sensitivity for rows 200 and 265 ----------
local_rows <- c(200L, 265L)
stopifnot(max(local_rows) <= nrow(X_all))
if ("Result" %in% names(train_raw)) {
  stopifnot(all(train_raw$Result[local_rows] %in% c(1, "1", "Yes", "yes")))
}

primary_S <- results[[primary_name]]$S
local_summary <- lapply(names(results), function(nm) {
  S <- results[[nm]]$S
  bind_rows(lapply(local_rows, function(r) {
    pvec <- as.numeric(primary_S[r, ])
    cvec <- as.numeric(S[r, ])
    feats <- colnames(S)
    top3_p <- feats[order(abs(pvec), decreasing = TRUE)][1:3]
    top3_c <- feats[order(abs(cvec), decreasing = TRUE)][1:3]
    tibble(
      spec = nm,
      case_row = r,
      shap_spearman_vs_primary = suppressWarnings(cor(pvec, cvec, method = "spearman")),
      sign_agreement_fraction = mean(sign(pvec) == sign(cvec)),
      local_top3_overlap_n = length(intersect(top3_p, top3_c)),
      predicted_probability = predict_locked_prob(bundle, X_all[r, , drop = FALSE])
    )
  }))
}) %>% bind_rows()
write.csv(local_summary, file.path(out_dir, "SHAP_local_cases_background_sensitivity.csv"), row.names = FALSE)

local_feature_long <- bind_rows(lapply(names(results), function(nm) {
  S <- results[[nm]]$S
  bind_rows(lapply(local_rows, function(r) {
    tibble(spec = nm, case_row = r, feature = colnames(S), shap_value = as.numeric(S[r, ]))
  }))
}))
write.csv(local_feature_long, file.path(out_dir, "SHAP_local_feature_values_all_backgrounds.csv"), row.names = FALSE)

# ---------- 6. Publication-friendly plots ----------
# Rank stability plot
p_rank <- ggplot(imp_long, aes(x = spec, y = rank, group = feature)) +
  geom_line(alpha = 0.45) +
  geom_point(size = 1.8) +
  scale_y_reverse(breaks = 1:9) +
  coord_flip() +
  labs(x = NULL, y = "Global SHAP importance rank", title = "SHAP rank stability across training-only backgrounds") +
  theme_bw(base_size = 11) +
  theme(legend.position = "none")
ggsave(file.path(out_dir, "SHAP_background_rank_stability.pdf"), p_rank, width = 8.5, height = 6.2)

# Importance stability plot
p_imp <- ggplot(imp_long, aes(x = feature, y = mean_abs_shap, group = spec)) +
  geom_point(position = position_jitter(width = 0.08, height = 0), alpha = 0.75) +
  stat_summary(fun = mean, geom = "point", shape = 18, size = 3) +
  coord_flip() +
  labs(x = NULL, y = "Mean |SHAP|", title = "Global SHAP importance across training-only backgrounds") +
  theme_bw(base_size = 11)
ggsave(file.path(out_dir, "SHAP_background_importance_stability.pdf"), p_imp, width = 8.0, height = 6.2)

# ---------- 7. Human-readable console summary ----------
cat("\n================ PRIMARY TRAINING-ONLY SHAP RANKING ================\n")
print(results[[primary_name]]$imp)
cat("\n================ BACKGROUND CONCORDANCE ================\n")
print(concordance)
cat("\n================ LOCAL CASE SENSITIVITY ================\n")
print(local_summary)
cat("\nOutputs written to: ", normalizePath(out_dir), "\n", sep = "")
cat("IMPORTANT: These analyses assess explanation robustness only. They do not refit the RF,\n",
    "do not change the locked threshold, and do not establish causal importance or clinical validity.\n", sep = "")
