# SHAP background-sensitivity analysis (round-2 revision)

This directory contains the publication-facing summary outputs for the alternative-background sensitivity analysis requested during peer review.

## Analysis design

- Locked model: final nine-predictor random forest; **no refitting or retuning**.
- Explained cohort: all 280 training observations in every run.
- Validation data: **not used** as SHAP background or explained data in this sensitivity analysis.
- Primary Kernel SHAP background: `n=120`, seed `2026`.
- Alternative same-size backgrounds: `n=120`, seeds `2027`, `2028`, `2029`, and `2030`.
- Background-size sensitivity: `n=60` and `n=180`, both using seed `2026`.
- Local cases: training rows `200` and `265`, selected according to the manuscript workflow.

The executable R script is stored at:

`analysis/r/SHAP_alternative_background_sensitivity_training_only_v2_fixed.R`

## Public summary files

- `SHAP_background_concordance_summary.csv`: rank/importance correlations and Top-3/Top-5 overlap versus the primary background.
- `SHAP_global_importance_by_background.csv`: mean absolute SHAP values and ranks for all nine predictors under each background.
- `SHAP_feature_variability_across_backgrounds.csv`: feature-wise magnitude and rank variability across backgrounds.
- `SHAP_local_cases_background_sensitivity.csv`: local SHAP correlation, sign agreement, Top-3 overlap, and unchanged locked-model probabilities for cases 200 and 265.

## Main reproducibility findings

Across the six alternative training-only backgrounds, global feature-rank Spearman correlation versus the primary background ranged from approximately `0.917` to `0.983`. The Top-3 feature set was unchanged in every alternative run. The Top-5 set was unchanged in five of six alternatives and differed by one feature in the remaining run. Local feature-level SHAP correlations ranged from `0.950-1.000` for case 200 and `0.900-1.000` for case 265; all nine contribution signs and all local Top-3 contributors were preserved in every alternative background.

These results assess sensitivity of the **post-hoc explanation to reference-background choice only**. They do not establish causal importance, feature-selection stability, fairness, clinical validity, or transportability.
