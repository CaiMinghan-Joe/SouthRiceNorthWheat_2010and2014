# CFPS data licence review

Review date: 20 September 2026

## Conclusion

The CFPS-derived individual-level analytical DTA must not be included in a journal-submission ZIP, public repository, or unauthorized third-party platform without explicit CFPS authorization. The public/submission archive generated from this package must therefore exclude `data/HSSC_analysis_data_final.dta` and all other person-level DTA files.

## Official basis

The current CFPS Data User Agreement states that users may not distribute any part of CFPS data on journal websites or third-party platforms in original or modified form. CFPS guidance on publication and data sharing further clarifies that this restriction covers subsets and user-created derivative microdata. Users may share their own analysis code provided it does not disclose protected information.

The current CFPS policy on AI tools also prohibits transmitting original or derived household- or individual-level CFPS data to external AI services and prohibits granting cloud coding agents access to directories containing such microdata. Replication users should run this package locally in Stata and must not upload its restricted DTA to an AI service.

## Package implementation

- The local package retains `HSSC_analysis_data_final.dta` only for authorized local verification.
- The submission/public ZIP excludes the CFPS-derived DTA and generated person-level working DTA files.
- The ZIP retains Stata code, aggregate result tables, documentation, and the province-level historical indicator workbook.
- README instructions direct authorized replicators to obtain CFPS data through the official CFPS platform and place an authorized local analysis file in the package `data/` directory.

## Official pages

- CFPS Data User Agreement: https://www.isss.pku.edu.cn/cfps/en/data/DataUserAgreement/1201867cfps1382470.htm
- CFPS publication and data-sharing guidance: https://www.isss.pku.edu.cn/cfps/cjwt/fbxg/1201867cfps1379024.htm
- CFPS public-data application guide: https://www.isss.pku.edu.cn/cfps/sjzx/gksj/
- CFPS policy on AI tools: https://www.isss.pku.edu.cn/cfps/en/data/PolicyontheUseofAIToolsforCFPSData/ce44dd324b3b4ffebeee27c9f036b25e.htm
