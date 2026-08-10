# ============================================================================
# Synthetic software-concordance check for the locked RF prediction function.
# Run from the repository root.
# ============================================================================
old_wd <- getwd()
on.exit(setwd(old_wd), add = TRUE)
if (!file.exists(file.path("app", "global.R"))) stop("Run this script from the repository root.")
setwd("app")
source("global.R", local = FALSE)
setwd(old_wd)

synthetic_cases <- data.frame(
  Coffee_consumption = c("1", "2", "3"),
  Sports_status = c("1", "2", "3"),
  AHI = c(15, 35, 70),
  MSaO2 = c(94, 92, 88),
  Depressive_symptoms_total_score = c(4, 9, 15),
  Anxiety_total_score = c(4, 12, 18),
  Drowsiness_total_score = c(5, 12, 20),
  Stress_total_score = c(15, 33, 50),
  Sleep_quality_total_score = c(5, 11, 18),
  stringsAsFactors = FALSE
)

p1 <- predict_mci_probability(bundle, synthetic_cases)
p2 <- predict_mci_probability(bundle, synthetic_cases)
if (!isTRUE(all.equal(p1, p2, tolerance = 1e-15))) stop("Repeated locked-RF predictions are not identical.")
if (any(!is.finite(p1)) || any(p1 < 0 | p1 > 1)) stop("Invalid RF probability detected.")
out <- cbind(
  synthetic_cases,
  Predicted_MCI_probability = p1,
  Locked_threshold = bundle$threshold,
  Prioritization = classify_for_prioritization(p1, bundle)
)
write.csv(out, "RF_web_concordance_synthetic_cases.csv", row.names = FALSE)
print(out)
cat("Concordance check PASSED.\n")
