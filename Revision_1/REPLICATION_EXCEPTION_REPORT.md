# HSSC Replication Exception Report

## Status

The health3-corrected replication outputs reproduce the manuscript's core sample counts, main effects, historical-rice result, Fairlie decomposition, PSM, IV-Probit, KHB, lagged analysis, and gender/age heterogeneity results. Two interaction-test p-values do not match the clean manuscript at three-decimal precision.

No model, sample, variable coding, seed, manuscript text, or reported value was changed to remove these differences.

## Exceptions

| Item | Clean manuscript | Health3-corrected replication | Absolute difference | Three-decimal result |
|---|---:|---:|---:|---|
| Education × historical rice interaction, p-value | 0.585 | 0.580217415357 | 0.004782584643 | FAIL (0.585 vs 0.580) |
| P75–P25 education AME difference, p-value | 0.903 | 0.904431940000 | 0.001431940000 | FAIL (0.903 vs 0.904) |

## Interpretation

Both replicated p-values remain far above conventional significance thresholds. The numerical differences therefore do not change the substantive conclusion that the interaction and the P75–P25 contrast are not statistically significant. They do, however, prevent a claim of exact three-decimal reproduction of those two manuscript entries.

## Evidence locations

- Clean manuscript: `Manuscripi_Revision_1_Clean.docx` in the Revision 1 submission folder.
- Replication crosswalk: `documentation/manuscript_table_crosswalk.csv`.
- Interaction and contrast outputs: `output/tables/historical_interaction.csv` and `output/tables/historical_ame_contrast.csv`.
- Reproduction code: `code/modules/04_robustness.do` and `code/modules/99_finalize_outputs.do`.

## Release consequence

Because the acceptance rule requires every manuscript crosswalk item to pass at the stated precision, this package is marked **REVIEW REQUIRED** rather than **FINAL**. The package documents the discrepancy without altering the frozen health3-corrected specification.
