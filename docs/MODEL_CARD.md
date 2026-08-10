# Model card

## Intended purpose
Estimate the probability of a **concurrent clinically defined MCI classification** among patients with OSA in settings where the required polysomnography and questionnaire inputs are already available.

## Intended users
Trained sleep-clinic or respiratory-care professionals. The model is not intended for unsupervised patient use.

## Inputs
Nine required inputs are documented in `../metadata/RF_variable_dictionary.csv`.

## Output
A probability of the positive MCI class. The locked training-derived prioritization threshold is 0.3228.

## Interpretation
A probability at or above 0.3228 indicates **prioritization for formal cognitive assessment**. The threshold is not a diagnostic cutoff.

## Missing data
The locked development and validation workflow used complete cases without an imputation strategy. The public prediction function therefore does not generate a prediction if a required input is missing.

## Validation scope
The model was evaluated in a Changchun modeling sample with a held-out internal-validation set and an independent Shenzhen external-validation sample. Both centers were Chinese tertiary-care settings.

## Important limitations
- Cross-sectional diagnostic prediction only; no incident-MCI or longitudinal prognosis claim.
- External probability calibration was imperfect and requires reassessment before new-site deployment.
- Female event counts were very small; reliable performance in women has not been established.
- The model requires PSG and multiple questionnaire inputs and is not intended for low-data settings without those inputs.
- SHAP explanations describe fitted-model behavior and are not causal evidence.
