# Publication-lock feature-selection code

The revised manuscript describes a single synchronized feature-selection workflow. The authoritative implementation for that description is the Python code in this folder.

## Files

- `01_redundancy_review_0p70.py` — applies the locked redundancy-review rule and exports the variables retained after redundancy review.
- `02_dummy_matrix_lasso_boruta_consensus.py` — builds the common dummy-coded design matrix, applies LASSO and Boruta to that same matrix, maps supported design-matrix terms back to parent predictors, and exports the consensus set.

## Publication-lock logic

The workflow represented by these scripts is:

1. Start from the 27 modeling candidates after excluding the derived OSA-severity variable.
2. Apply the common absolute-association trigger of `>= 0.70` for redundancy review.
3. Retain 24 original predictors after the locked redundancy decisions.
4. Dummy-code categorical predictors to obtain a common 34-column design matrix.
5. Apply LASSO and Boruta to that same design matrix.
6. Map non-zero/supporting design-matrix terms back to their parent predictors.
7. Report 17 LASSO-supported parent predictors, 11 Boruta-supported parent predictors, and their 9-predictor consensus.

The final consensus predictors are:

- Coffee consumption
- Physical activity
- AHI
- MSaO2
- PHQ-9 total score
- GAD-7 total score
- ESS total score
- CPSS-14 total score
- PSQI total score

These files are intended to document the synchronized publication-lock implementation. Patient-level source data are not included in the public archive because of privacy, consent, and institutional-governance restrictions.
