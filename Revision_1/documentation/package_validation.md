# Package validation record

Validation date: 20 September 2026
Execution environment: Stata/MP 18.0 running code under `version 17.0`
Entry point: `do code/HSSC_final_replication.do` from the package root

## Clean-session execution

The master file was launched in a new Stata batch process with no prior dataset, macro, matrix, or stored estimate in memory. It completed with the marker `FINAL_REPLICATION_COMPLETE`.

Stage completion markers were observed for:

- analysis-file preparation;
- baseline and historical-context models;
- Fairlie point estimates and 999-draw bootstrap;
- prespecified robustness checks and 1,999-draw province bootstrap;
- PSM, IV-Probit, KHB, and two-wave lagged analysis;
- gender heterogeneity;
- age heterogeneity;
- final table construction and manuscript crosswalk.

All 1,999 province-bootstrap draws succeeded. The Fairlie bootstrap, PSM support counts, IV analysis sample, KHB output, and lagged sample were produced by the clean run rather than copied into the final tables.

## Input and sample checks

- Local restricted input: `data/HSSC_analysis_data_final.dta`
- SHA-256: `84934e495dfe9a5b98dba43dd70fd2e0f2ac65eb29c0cb0983bc4c57bb5a0639`
- Eligible rural rows: 16,035
- Current rice/wheat comparison rows: 15,752
- Final analytical rows: 15,165
- 2010 / 2014: 8,452 / 6,713
- Primary-sample `health3`: 11,916 Good; 1,947 Fair; 1,302 Poor
- Identity checks: `rice10 == rice_hist*10`; `age_c == age-45`; `age_c2 == age_c^2`

## Result gate

The automated crosswalk contains 20 checks: 18 PASS and 2 FAIL. The failures are limited to the two interaction-test p-values documented in `REPLICATION_EXCEPTION_REPORT.md`. They do not alter either test's non-significant conclusion, but they prevent designation of the package as fully final.

## Spreadsheet and machine-readable output checks

The historical-rice workbook and the principal CSV outputs were independently imported and inspected. The historical workbook contains one 32-row by 29-column sheet; the result crosswalk contains 20 result rows; Table 2 contains 14 variables; the post-match balance file contains 32 covariates. No malformed row structure was detected.

## Distribution gate

The local package retains restricted CFPS-derived DTA files for authorized verification. The submission/public candidate archive excludes all DTA and `.ster` files. Logs in that archive are sanitized to remove local absolute paths and user identifiers. See `CFPS_DATA_LICENSE_REVIEW.md`.
