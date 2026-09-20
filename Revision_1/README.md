# HSSC Replication Package

## Manuscript

This package reproduces the formal empirical results reported in:

**Historical Agricultural Context and Human Capital: North-South Differences in Physical Exercise Participation among Rural Chinese Residents**

The package was reconciled against `Manuscripi_Revision_1_Clean.docx` in the Revision 1 submission folder.

## Data

The analysis uses the 2010 and 2014 waves of the China Family Panel Studies (CFPS) and a province-level historical agricultural indicator released with Guntuku et al. (2024). The historical paddy measure is documented by the source as the share of cultivated land devoted to paddy fields, based on the 1996 China Statistical Yearbook. In the models, `rice10 = rice_hist * 10`, so one unit represents 10 percentage points.

`HSSC_analysis_data_final.dta` is the analysis dataset corresponding to Revision 1. In an authorized local working copy, it holds 16,035 eligible rural person-wave observations and flags the 15,165-observation primary analytical sample. This DTA is derived from CFPS microdata and is restricted-use material; it is intentionally absent from this public repository.

The CFPS Data User Agreement prohibits distributing original, partial, or modified CFPS datasets on journal websites or unauthorized third-party platforms. Therefore:

- the local DTA must not be uploaded to a journal website, public GitHub repository, public OSF project, cloud drive, or external AI service;
- the public/submission ZIP intentionally excludes `HSSC_analysis_data_final.dta`;
- authorized replicators must obtain CFPS data through the official CFPS data platform and place the prepared authorized local copy at `Revision_1/data/HSSC_analysis_data_final.dta`;
- analysis code and non-microdata documentation may be shared, subject to the external historical-indicator source terms.

The province-level historical indicator workbook is included as `data/historical_rice_province_data.xlsx`. It contains no CFPS individual-level observations.

## Software

- Stata 17 or later
- User-written commands: `fairlie`, `khb`, and `psmatch2`

Install the required commands manually in Stata if necessary:

```stata
ssc install fairlie
ssc install khb
ssc install psmatch2
```

The master file checks these commands and stops with an explicit error if any are unavailable. It does not install packages or access the internet automatically.

## Reproduction

Run the master do-file from the `Revision_1/` directory.

```stata
clear all
do code/HSSC_final_replication.do
```

The master file starts from the single DTA in `data/`, verifies the frozen sample and key variable identities, creates temporary analytical views under `output/data/`, and runs all formal models without relying on a previous Stata session.

The frozen specifications include:

- baseline multilevel logit with a community-wave random intercept, province and year fixed effects, and province-clustered standard errors;
- nested historical-context logit models;
- South-minus-North Fairlie decomposition;
- prespecified wave, all-rural, link-function, income, categorical-education, and leave-one-province-out checks;
- 1:2 nearest-neighbor PSM with replacement and common support;
- leave-one-out community-wave education IV-Probit;
- KHB decomposition using wave-standardized vocabulary and mathematics scores;
- two-wave lagged analysis;
- pooled gender and age-group interaction models.

No caliper, alternative treatment definition, regional heterogeneity, income heterogeneity, exercise-frequency outcome, neighborhood control, or significance-driven model selection is introduced.

## Output

The master do-file writes:

- `output/tables/Table1_sample_construction.csv`
- `output/tables/Table2_descriptive_statistics.csv`
- `output/tables/Table3_baseline.csv`
- `output/tables/Table4_historical_context.csv`
- `output/tables/Table5_fairlie.csv`
- `output/tables/Table6_robustness.csv`
- `output/tables/Table7_psm_iv.csv`
- `output/tables/Table8_khb_lagged.csv`
- `output/tables/Table9_heterogeneity.csv`
- `output/tables/PSM_postmatch_balance.csv`
- `documentation/result_crosswalk.csv`
- `output/logs/HSSC_final_replication.log` and stage logs.

`documentation/result_crosswalk.csv` compares replicated values with the manuscript-frozen values. Any nontrivial mismatch must be retained and documented; model specifications and output numbers must not be altered to force a match.

The current package intentionally carries the status `REVIEW REQUIRED`, not `FINAL`, because the crosswalk contains two failed checks. All other frozen acceptance checks passed in the clean run.

## Interpretation boundaries

The analysis is observational. The IV relevance statistics do not establish the exclusion restriction, KHB does not identify a causal mediation effect, and Fairlie components are decomposition terms rather than causal contributions. The outcome is participation in physical exercise during the previous week, not compliance with a regular-exercise guideline.

## Directory structure

```text
Revision_1/
├── README.md
├── code/
│   ├── HSSC_final_replication.do
│   └── modules/
├── data/
│   ├── HSSC_analysis_data_final.dta       [local restricted file; excluded from public ZIP]
│   ├── historical_rice_province_data.xlsx
│   └── README_DATA_RESTRICTIONS.md
├── documentation/
│   ├── manuscript_table_crosswalk.csv
│   ├── result_crosswalk.csv
│   ├── sample_flow.csv
│   ├── software_requirements.txt
│   └── variable_dictionary.csv
└── output/
    ├── data/
    ├── estimates/
    ├── logs/
    └── tables/
```
