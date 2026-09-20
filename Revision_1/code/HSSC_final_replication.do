****************************************************
* HSSC FINAL REPLICATION
****************************************************
version 17.0
clear all
set more off
set linesize 255
set seed 20260910
capture log close _all

* 0. Paths. Run this file from the package root directory.
global ROOT "."
global DATA "$ROOT/data"
global OUTPUT "$ROOT/output"
global TABLES "$OUTPUT/tables"
global LOGS "$OUTPUT/logs"
global ESTIMATES "$OUTPUT/estimates"

capture confirm file "$DATA/HSSC_analysis_data_final.dta"
if _rc {
    di as error "Required restricted-use file data/HSSC_analysis_data_final.dta was not found."
    di as error "See README.md for CFPS data-access and redistribution restrictions."
    exit 601
}

capture mkdir "$OUTPUT"
capture mkdir "$TABLES"
capture mkdir "$LOGS"
capture mkdir "$OUTPUT/data"
capture mkdir "$ESTIMATES"
log using "$LOGS/HSSC_final_replication.log", text replace name(master)

* 1. Required user-written commands. Installation is never performed silently.
foreach cmd in fairlie khb psmatch2 {
    capture which `cmd'
    if _rc {
        di as error "Required command `cmd' is not installed. See README.md."
        log close master
        exit 199
    }
}

* 2. Prepare all frozen analysis views from the single submitted DTA.
do "$ROOT/code/modules/00_prepare_analysis_files.do"

* 3. Table 2, baseline, historical-context models and interaction checks.
do "$ROOT/code/modules/02_main_models.do"

* 4. Fairlie South-minus-North decomposition and frozen bootstrap.
do "$ROOT/code/modules/03_fairlie.do"

* 5. Prespecified robustness checks and province bootstrap.
do "$ROOT/code/modules/04_robustness.do"

* 6. PSM, IV-Probit, KHB and two-wave lagged analysis.
do "$ROOT/code/modules/05_supplementary.do"

* 7. Gender and age-group heterogeneity.
do "$ROOT/code/modules/06_gender_heterogeneity.do"
do "$ROOT/code/modules/07_age_group_heterogeneity.do"

* 8. Manuscript tables, result crosswalk and exception report inputs.
do "$ROOT/code/modules/99_finalize_outputs.do"

capture log close _all
log using "$LOGS/HSSC_final_replication.log", text append name(master)
display "FINAL_REPLICATION_COMPLETE"
log close master
exit
