/**********************************************************************
Data file expected in the same folder:SouthRiceNorthWheat_2010and2014.dta

Main outputs are written to:results/
	
Title：Empirical Evidence on the North-South Divide in Physical Activity Participation among Chinese Residents

Author:Cai Minghan

Date:2025-04-21
**********************************************************************/

version 17.0
clear all
set more off
set linesize 255
set seed 1234

* ------------------------------ *
* 0. Paths and user commands
* ------------------------------ *

local project_dir "."
cd "`project_dir'"

local data_file "SouthRiceNorthWheat_2010and2014.dta"
local out_dir "results"
capture mkdir "`out_dir'"

local install_user_commands = 0
local missing_commands = 0

foreach cmd in esttab estpost eststo {
    capture which `cmd'
    if _rc {
        if `install_user_commands' ssc install estout, replace
        else {
            di as error "Missing user-written command: `cmd'. Install with: ssc install estout"
            local missing_commands = 1
        }
    }
}

foreach cmd in winsor2 psmatch2 fairlie khb asdoc {
    capture which `cmd'
    if _rc {
        if `install_user_commands' ssc install `cmd', replace
        else {
            di as error "Missing user-written command: `cmd'. Install with: ssc install `cmd'"
            local missing_commands = 1
        }
    }
}

if `missing_commands' {
    di as error "Install the missing commands or set local install_user_commands = 1, then rerun this do-file."
    exit 111
}

use "`data_file'", clear

* ------------------------------ *
* 1. Analysis sample and labels
* ------------------------------ *

keep if !missing(exercise, edu, plants, part, cid)
keep if inlist(plants, 0, 1)
keep if inlist(part, 0, 1)

label define yesno 0 "No" 1 "Yes", replace
label define southnorth 0 "South" 1 "North", replace
label define crop 0 "Rice" 1 "Wheat", replace
label define income_group 0 "Low income" 1 "High income", replace

label values exercise yesno
label values sportsArea yesno
label values part southnorth
label values plants crop

label variable exercise   "Exercise participation"
label variable edu        "Education attainment"
label variable plants     "Farming practices"
label variable lnage      "Age"
label variable lnage2     "Age squared"
label variable gender     "Gender"
label variable marriage   "Marriage"
label variable lnIncome   "ln(income)"
label variable health     "Health"
label variable lnNeighbor "Neighborhood relations"
label variable sportsArea "Sports facilities"
label variable wordtest   "Literacy test score"
label variable mathtest   "Math test score"
label variable part       "Region"

global controls "lnage lnage2 gender marriage lnIncome health lnNeighbor"
global full_controls "$controls sportsArea"
global desc_vars "exercise edu plants lnage lnage2 gender marriage lnIncome health lnNeighbor sportsArea mathtest wordtest"

drop if missing($desc_vars)

* Recreate standardized cognitive ability variables used in KHB analysis.
capture drop word_std math_std
egen word_std = std(wordtest)
egen math_std = std(mathtest)
label variable word_std "Standardized literacy score"
label variable math_std "Standardized math score"

* Recreate the leave-one-out community average education IV.
capture drop total_edu_cid count_edu_cid iv_community_edu
bysort cid: egen total_edu_cid = total(edu)
bysort cid: egen count_edu_cid = count(edu)
gen iv_community_edu = (total_edu_cid - edu) / (count_edu_cid - 1)
replace iv_community_edu = . if count_edu_cid <= 1
label variable iv_community_edu "Community average education, leave-one-out"

* Recreate high-income group if it is absent.
capture confirm variable inc_high
if _rc {
    egen income_median = median(lnIncome)
    gen inc_high = (lnIncome >= income_median) if !missing(lnIncome)
    drop income_median
}
label values inc_high income_group
label variable inc_high "High-income group"

compress

* ------------------------------ *
* 2. Table 1: descriptive statistics
* ------------------------------ *

eststo clear
estpost summarize $desc_vars
esttab . using "`out_dir'/Table1_descriptive_full.rtf", ///
    cells("mean(fmt(3)) sd(fmt(3)) min(fmt(3)) max(fmt(3)) count(fmt(0))") ///
    label noobs nonumber replace ///
    title("Table 1. Descriptive statistics: full sample")

eststo clear
estpost tabstat $desc_vars, by(part) statistics(mean sd) columns(statistics)
esttab . using "`out_dir'/Table1_descriptive_by_region.rtf", ///
    cells("mean(fmt(3)) sd(fmt(3))") label noobs nonumber replace ///
    title("Table 1. Descriptive statistics by region")

estpost ttest $desc_vars, by(part)
esttab . using "`out_dir'/Table1_region_ttest.rtf", ///
    cells("mu_1(fmt(3)) mu_2(fmt(3)) b(star fmt(3)) t(fmt(2)) p(fmt(3))") ///
    label nogap compress replace ///
    title("Difference tests between southern and northern samples")

* ------------------------------ *
* 3. Table 2: baseline multilevel logit
* ------------------------------ *

eststo clear

melogit exercise i.provcd|| cid:, nolog
estimates store baseline_null
estat icc

melogit exercise edu i.plants i.provcd $controls || cid:, nolog
margins, dydx(edu plants $controls) post
estimates store baseline_individual_ame

melogit exercise edu i.plants i.provcd $full_controls || cid:, nolog
estimates store baseline_full_model
estat icc
margins, dydx(edu plants $full_controls) post
estimates store baseline_full_ame

esttab baseline_individual_ame baseline_full_ame using "`out_dir'/Table2_baseline_AME.rtf", ///
    b(%9.3f) se(%9.3f) nogap compress label replace ///
    mtitle("Individual controls" "Village facility controls") ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N, labels("Observations")) ///
    title("Table 2. Baseline multilevel logit results: average marginal effects")

esttab baseline_null baseline_full_model using "`out_dir'/Table2_baseline_model_coefficients.rtf", ///
    b(%9.3f) se(%9.3f) nogap compress label replace ///
    mtitle("Null model" "Full model") ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N ll chi2 p, labels("Observations" "Log likelihood" "Chi-square" "p-value")) ///
    title("Baseline multilevel logit model coefficients")

* Optional collinearity check for the linear probability approximation.
reg exercise edu i.plants i.provcd $full_controls, vce(cluster cid)
vif

* ------------------------------ *
* 4. Table 3: Fairlie nonlinear decomposition
* ------------------------------ *

capture noisily fairlie exercise edu plants i.provcd $full_controls, by(part) pooled ro reps(100)
if !_rc {
    estimates store fairlie_region
    esttab fairlie_region using "`out_dir'/Table3_fairlie_decomposition.rtf", ///
        b(%9.4f) se(%9.4f) nogap compress replace ///
        star(* 0.1 ** 0.05 *** 0.01) ///
        title("Table 3. Fairlie nonlinear decomposition")
}

* ------------------------------ *
* 5. Table 4: robustness checks
* ------------------------------ *

eststo clear

mixed exercise_freq edu i.plants i.provcd $full_controls || cid:, nolog
estimates store robust_frequency

meprobit exercise edu i.plants i.provcd $full_controls || cid:, nolog
margins, dydx(edu plants $full_controls) post
estimates store robust_probit_ame

capture drop high_edu
gen high_edu = (edu >= 3) if !missing(edu)
label define high_edu_lab 0 "Primary or below" 1 "Junior high or above", replace
label values high_edu high_edu_lab
label variable high_edu "Junior high education or above"

capture noisily psmatch2 high_edu $full_controls i.plants i.provcd, out(exercise) logit ate ties common n(2)
if !_rc {
    pstest $full_controls plants, both
}

teffects psmatch (exercise) (high_edu  $full_controls i.plants i.provcd, logit), atet nneighbor(2) vce(robust)
estimates store robust_psm_atet

esttab robust_frequency robust_probit_ame robust_psm_atet using "`out_dir'/Table4_robustness.rtf", ///
    b(%9.3f) se(%9.3f) nogap compress label replace ///
    mtitle("Exercise frequency" "Multilevel probit AME" "PSM ATET") ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N, labels("Observations")) ///
    title("Table 4. Robustness checks")

* ------------------------------ *
* 6. Table 5: endogeneity test
* ------------------------------ *

eststo clear

reg edu iv_community_edu i.plants i.provcd $full_controls, vce(cluster cid)
estimates store iv_first_stage
test iv_community_edu
scalar first_stage_F = r(F)
scalar first_stage_p = r(p)

ivprobit exercise i.plants i.provcd  $full_controls (edu = iv_community_edu), twostep
estimates store iv_twostep

ivprobit exercise i.plants i.provcd $full_controls (edu = iv_community_edu), vce(cluster cid)
estimates store iv_mle
margins, dydx(edu plants $full_controls) post
estimates store iv_mle_ame

esttab iv_first_stage iv_twostep iv_mle_ame using "`out_dir'/Table5_endogeneity_IV.rtf", ///
    b(%9.3f) se(%9.3f) nogap compress label replace ///
    mtitle("First stage: edu" "IV-Probit two-step" "IV-Probit MLE AME") ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N, labels("Observations")) ///
    title("Table 5. Endogeneity test")

display as text "First-stage F statistic = " %9.3f first_stage_F
display as text "First-stage p value     = " %9.4f first_stage_p

* ------------------------------ *
* 7. Table 6: KHB mediation decomposition
* ------------------------------ *

capture noisily khb probit exercise edu || word_std math_std, ///
    concomitant(i.plants i.provcd $full_controls) decompose summary disentangle

capture which asdoc
if !_rc {
    asdoc khb probit exercise edu || word_std math_std, ///
        concomitant(i.plants i.provcd $full_controls) decompose replace ///
        save("`out_dir'/Table6_KHB_mediation.doc")
    asdoc khb probit exercise edu || word_std math_std, ///
        concomitant(i.plants i.provcd $full_controls) summary disentangle append ///
        save("`out_dir'/Table6_KHB_mediation.doc")
}

* ------------------------------ *
* 8. Table 7 and figures: heterogeneity
* ------------------------------ *

eststo clear

melogit exercise c.edu##i.part i.plants i.provcd sportsArea $controls || cid:, nolog
estimates store hetero_region_full
margins part, dydx(edu) post
estimates store hetero_region_ame

melogit exercise edu i.plants i.provcd $full_controls if part == 0 || cid:, nolog
margins, dydx(edu plants $full_controls) post
estimates store hetero_south_ame

melogit exercise edu i.plants i.provcd $full_controls if part == 1 || cid:, nolog
margins, dydx(edu plants $full_controls) post
estimates store hetero_north_ame

esttab hetero_region_full hetero_south_ame hetero_north_ame using "`out_dir'/Table7_region_heterogeneity.rtf", ///
    b(%9.3f) se(%9.3f) nogap compress label replace ///
    mtitle("Full sample interaction" "South AME" "North AME") ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N, labels("Observations")) ///
    title("Table 7. Regional heterogeneity")

melogit exercise c.edu##i.part i.plants i.provcd sportsArea $controls || cid:, nolog
margins part, at(edu=(1(1)7))
marginsplot, recast(line) noci ///
    title("Education and exercise participation by region") ///
    xtitle("Education attainment") ///
    ytitle("Predicted probability of exercise participation") ///
    legend(order(1 "South" 2 "North"))
graph export "`out_dir'/Figure1_region_heterogeneity.tif", replace width(2400)

melogit exercise c.edu##i.inc_high i.plants i.provcd sportsArea $controls || cid:, nolog
estimates store hetero_income_full
margins inc_high, dydx(edu) post
estimates store hetero_income_ame

melogit exercise edu i.plants i.provcd $full_controls if inc_high == 0 || cid:, nolog
margins, dydx(edu plants $full_controls) post
estimates store hetero_low_income_ame

melogit exercise edu i.plants i.provcd $full_controls if inc_high == 1 || cid:, nolog
margins, dydx(edu plants $full_controls) post
estimates store hetero_high_income_ame

esttab hetero_income_full hetero_low_income_ame hetero_high_income_ame using "`out_dir'/Table7_income_heterogeneity.rtf", ///
    b(%9.3f) se(%9.3f) nogap compress label replace ///
    mtitle("Full sample interaction" "Low-income AME" "High-income AME") ///
    star(* 0.1 ** 0.05 *** 0.01) ///
    stats(N, labels("Observations")) ///
    title("Table 7. Income heterogeneity")

melogit exercise c.edu##i.inc_high i.plants i.provcd sportsArea $controls || cid:, nolog
margins inc_high, at(edu=(1(1)7))
marginsplot, recast(line) noci ///
    title("Education and exercise participation by income group") ///
    xtitle("Education attainment") ///
    ytitle("Predicted probability of exercise participation") ///
    legend(order(1 "Low income" 2 "High income"))
graph export "`out_dir'/Figure2_income_heterogeneity.tif", replace width(2400)

* ------------------------------ *
* 9. Save final analysis data and log sample size
* ------------------------------ *

save "`out_dir'/analysis_sample_for_replication.dta", replace

count
display as text "Final analysis sample size = " r(N)
tab part
tab exercise part, col

display as text "Replication do-file completed successfully."



