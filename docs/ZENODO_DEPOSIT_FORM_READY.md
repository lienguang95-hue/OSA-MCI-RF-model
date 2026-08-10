# Zenodo deposit form — ready-to-copy metadata

## Deposit type
Software

## Title
OSA-MCI locked random-forest model and Shiny calculator reproducibility package

## Version
1.0.0

## Publication date
2026-08-10

## Creators
1. Li, Enguang — College of Management, Changchun University of Chinese Medicine, Changchun, Jilin, China
2. Ai, Fangzhu — School of Nursing, Liaoning University of Traditional Chinese Medicine, Shenyang, Liaoning, China
3. Cai, Peipei — Department of Accounting and Finance, Heilongjiang Polytechnic, Harbin, Heilongjiang, China
4. Wen, Kuo — College of Traditional Chinese Medicine, Changchun University of Chinese Medicine, Changchun, Jilin, China
5. Guo, Botang — Psychology and Health Management Center, Harbin Medical University, Harbin, Heilongjiang, China; Department of General Practice, The Affiliated Luohu Hospital of Shenzhen University Medical School, Shenzhen, Guangdong, China
6. Wen, Hongjuan — College of Management, Changchun University of Chinese Medicine, Changchun, Jilin, China

## Description
This versioned software and model archive supports the revised manuscript “Interpretable machine learning for identifying mild cognitive impairment among Chinese patients with obstructive sleep apnea: a multicenter cross-sectional study.”

The archive contains the canonical locked nine-predictor random-forest (RF) model object, the deployment copy used by the Shiny application, Shiny source code, example prediction code, a variable dictionary, synthetic example input/output files, software-concordance checks, software/session information, and synchronized publication-lock feature-selection code.

The locked model uses nine required predictors: coffee consumption, physical activity, apnea–hypopnea index (AHI), mean oxygen saturation (MSaO2), PHQ-9 total score, GAD-7 total score, Epworth Sleepiness Scale (ESS) total score, 14-item Chinese Perceived Stress Scale (CPSS-14) total score, and Pittsburgh Sleep Quality Index (PSQI) total score. The positive class is “Yes,” and the training-derived prioritization threshold is 0.3228.

The deployed calculator estimates the probability of concurrent clinically defined mild cognitive impairment (MCI) in patients with obstructive sleep apnea (OSA) for prioritization of formal cognitive assessment. It is not a stand-alone diagnostic tool, does not predict future cognitive decline, and does not replace standardized cognitive assessment or clinical judgment.

Patient-level development and validation datasets are not included because of privacy, informed-consent, and institutional-governance restrictions.

GitHub source repository: https://github.com/lienguang95-hue/OSA-MCI-RF-model

Live Shiny calculator: https://mciriskmodel.shinyapps.io/make_web/

Canonical locked RF object SHA-256: `7aac8100312e67b8929c353465e41702c14bcf1ae9d54bc5418540a6eaf6b463`

## Keywords
obstructive sleep apnea; mild cognitive impairment; random forest; clinical prediction model; diagnostic prediction; explainable artificial intelligence; SHAP; Shiny; machine learning; reproducibility

## Language
English

## Visibility
Public

## Publisher
Zenodo

## DOI field
Select “No, this upload does not already have a DOI,” then use Zenodo's “Get a DOI now!” function to reserve the DOI before publication. Never invent a DOI or reuse the future journal-article DOI for this software record.

## License — author decision required before publication
Zenodo requires a license for a public record. MIT is recommended for an openly reusable software/code archive, but selecting MIT grants reuse rights and should only be done after explicit author approval. If MIT is not desired, choose another appropriate software license or a custom rights statement consistent with the authors' intended reuse policy.

## Funding note
Associated-study funding: Jilin Provincial Administration of Traditional Chinese Medicine (No. 2024260); Changchun University of Traditional Chinese Medicine Theme Case Project (No. 2024YJ03); Development Center for Degree and Graduate Education, Ministry of Education (No. ZT-2510199001).
