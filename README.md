# OSA-MCI locked random-forest model: code and web-calculator reproducibility package

This public repository supports the revised manuscript **“Interpretable machine learning for identifying mild cognitive impairment among Chinese patients with obstructive sleep apnea: a multicenter cross-sectional study.”**

## What reviewers can inspect here

The repository provides the Shiny calculator source, locked prediction/preprocessing logic, example prediction code, a variable dictionary, synthetic example input/output, software-concordance code, software/session information, data/code provenance notes, publication-lock feature-selection code, and the round-2 **training-only SHAP alternative-background sensitivity analysis**.

**Patient-level development and validation data are not included** because of privacy, informed-consent, and institutional-governance restrictions.

## Public web calculator

https://mciriskmodel.shinyapps.io/make_web/

The calculator estimates the probability of **concurrent clinically defined MCI** in patients with OSA and is intended only to prioritize formal cognitive assessment. It is not a stand-alone diagnosis, does not predict future cognitive decline, and should not replace standardized cognitive assessment or clinical judgment. New-site use requires reassessment of calibration and, when indicated, recalibration.

## Locked model specification

- Model: random forest
- Final predictors: 9
- Positive class: `Yes`
- Training-derived prioritization threshold: `0.3228`
- Canonical RDS SHA-256: `7aac8100312e67b8929c353465e41702c14bcf1ae9d54bc5418540a6eaf6b463`

The nine required inputs are:

1. Coffee consumption
2. Physical activity
3. AHI
4. Mean oxygen saturation (MSaO2)
5. PHQ-9 total score
6. GAD-7 total score
7. ESS total score
8. CPSS-14 total score
9. PSQI total score

See `metadata/RF_variable_dictionary.csv` for coding and units.

## Repository structure

```text
app/           Shiny source and preflight/local-run scripts
prediction/    example prediction and synthetic software-concordance checks
metadata/      variable dictionary, model specification, R session information
examples/      synthetic example input/output and concordance cases
analysis/      publication-lock feature selection and round-2 SHAP sensitivity code/results
analysis/shap/ publication-facing SHAP background-sensitivity summary outputs
docs/          model card, data availability, provenance, security, reviewer guide
model/         locked-model archival status and SHA-256
```

## Feature-selection publication lock

The authoritative public implementation for the revised feature-selection description is:

- `analysis/python/01_redundancy_review_0p70.py`
- `analysis/python/02_dummy_matrix_lasso_boruta_consensus.py`

These scripts document the synchronized `>=0.70` redundancy-review trigger and the common dummy-coded matrix used by both LASSO and Boruta, followed by mapping back to parent predictors: `27 -> 24` original predictors, `34` dummy-coded columns, `17` LASSO parent predictors, `11` Boruta parent predictors, and `9` consensus predictors.

## SHAP alternative-background sensitivity analysis

The round-2 reviewer-requested SHAP sensitivity analysis is now public.

Executable script:

- `analysis/r/SHAP_alternative_background_sensitivity_training_only_v2_fixed.R`

Publication-facing summary outputs:

- `analysis/shap/SHAP_background_concordance_summary.csv`
- `analysis/shap/SHAP_global_importance_by_background.csv`
- `analysis/shap/SHAP_feature_variability_across_backgrounds.csv`
- `analysis/shap/SHAP_local_cases_background_sensitivity.csv`
- `analysis/shap/README.md`

Design: the locked RF was explained on all 280 training observations using a primary training-only Kernel SHAP background of `n=120, seed=2026`; alternative training-only backgrounds used `n=120` with seeds `2027-2030`, plus size variants `n=60` and `n=180` with seed `2026`. No validation data were used in the SHAP background, and the RF model, preprocessing, feature set, and threshold were not refitted or altered.

Across alternative backgrounds, global rank concordance versus the primary analysis was high (Spearman approximately `0.917-0.983`), the Top-3 set was unchanged in every run, and the two displayed local cases retained complete SHAP-sign agreement and complete Top-3 overlap. These analyses assess explanation robustness to background choice only and do not establish causal importance, fairness, clinical validity, or transportability.

## Example prediction

`examples/RF_example_input.csv` corresponds to an estimated probability of approximately `0.556` with the locked threshold `0.3228`, resulting in **Prioritize formal cognitive assessment**.

The local prediction script is `prediction/01_RF_Prediction_Example.R`. The synthetic repeated-prediction check is `prediction/05_RF_Web_Concordance_Check.R`.

## Permanent Zenodo archive

The versioned software/model archive is published in Zenodo:

**DOI: 10.5281/zenodo.21872475**

https://doi.org/10.5281/zenodo.21872475

The Zenodo archive contains the canonical locked RF RDS object and the deployment copy, each with SHA-256 `7aac8100312e67b8929c353465e41702c14bcf1ae9d54bc5418540a6eaf6b463`, together with versioned reproducibility materials. The round-2 SHAP sensitivity addendum is synchronized in this GitHub repository and should be included in the next Zenodo version before final manuscript submission.

The binary RDS object is not stored directly in this GitHub tree; the published Zenodo record is the permanent archive for the binary locked model.

## Data availability

No patient-level data are included in this public package. See `docs/DATA_AVAILABILITY.md`.

## Clinical-use limitation

The calculator is an implementation of the locked research model, not a prospectively validated medical device or clinical decision-support product. New-site use requires reassessment of calibration and clinical utility.

## Version

Repository publication-lock code package: `v1.1.0` (2026-08-27). This revision adds the training-only alternative-background SHAP sensitivity analysis requested during round-2 peer review.
