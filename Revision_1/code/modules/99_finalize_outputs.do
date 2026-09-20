version 17.0
clear all
set more off
capture log close _all
log using "$OUTPUT/logs/99_finalize_outputs.log", text replace

* Table 1. Analytical sample construction.
use "$DATA/HSSC_analysis_data_final.dta", clear
quietly summarize initial_eligible_N, meanonly
local n_initial=r(mean)
quietly count
local n_rural=r(N)
quietly count if sample_current_ricewheat==1
local n_ricewheat=r(N)
quietly count if sample_primary==1
local n_primary=r(N)
postfile t1 str64 step long N using "$OUTPUT/data/Table1_sample_construction.dta", replace
post t1 ("Initial eligible observations") (`n_initial')
post t1 ("Restricted to rural residents") (`n_rural')
post t1 ("Restricted to current rice-wheat comparison sample") (`n_ricewheat')
post t1 ("Final analytical sample") (`n_primary')
postclose t1
use "$OUTPUT/data/Table1_sample_construction.dta", clear
export delimited using "$TABLES/Table1_sample_construction.csv", replace
export delimited using "$ROOT/documentation/sample_flow.csv", replace

* Table 2. Descriptive statistics on the frozen primary sample.
use "$OUTPUT/data/analysis_primary.dta", clear
postfile t2 str80 manuscript_name str32 variable long N double mean sd min max using "$OUTPUT/data/Table2_descriptive_statistics.dta", replace
local vars "exercise edu plants rice10 ln_gdp_hist urban2000_10 age gender marriage ln_income health3 sportsArea wordtest mathtest"
local names `""Previous-week physical exercise participation" "Educational attainment" "Current household cultivation" "Historical rice share" "Historical economic condition" "Historical urbanisation" "Age" "Sex" "Marital status" "Household income" "Self-rated health" "Community sports facility" "Vocabulary test score" "Mathematics test score""'
local k=0
foreach v of local vars {
    local ++k
    local nm: word `k' of `names'
    quietly summarize `v'
    post t2 ("`nm'") ("`v'") (r(N)) (r(mean)) (r(sd)) (r(min)) (r(max))
}
postclose t2
use "$OUTPUT/data/Table2_descriptive_statistics.dta", clear
export delimited using "$TABLES/Table2_descriptive_statistics.csv", replace

* Table 3. Baseline average marginal effects.
use "$OUTPUT/data/main_model_results.dta", clear
keep if model=="B1_baseline" & scale=="AME_fixed" & inlist(term,"edu","1.plants")
keep term estimate se lower upper p N clusters
gen str48 result=cond(term=="edu","Educational attainment","Current household cultivation (wheat vs rice)")
order result term estimate se lower upper p N clusters
export delimited using "$TABLES/Table3_baseline.csv", replace

* Table 4. Historical-context progression plus interaction diagnostics.
use "$OUTPUT/data/main_model_results.dta", clear
keep if inlist(model,"H0_context","H1_context","H2_context") & scale=="AME" & inlist(term,"edu","rice10","1.plants")
keep model term estimate se lower upper p N clusters
export delimited using "$TABLES/Table4_historical_context.csv", replace

* Fairlie bootstrap summary and Table 5.
use "$OUTPUT/data/fairlie_bootstrap_draws.dta", clear
keep if rc==0
levelsof term, local(fairlie_terms)
postfile fci str32 term double lower upper using "$OUTPUT/data/fairlie_bootstrap_ci.dta", replace
foreach v of local fairlie_terms {
    quietly _pctile estimate if term=="`v'", p(2.5 97.5)
    post fci ("`v'") (r(r1)) (r(r2))
}
postclose fci
collapse (count) successful=draw (sd) bootstrap_se=estimate, by(term)
merge 1:1 term using "$OUTPUT/data/fairlie_bootstrap_ci.dta", assert(match) nogen
save "$OUTPUT/data/fairlie_bootstrap_summary.dta", replace
export delimited using "$TABLES/fairlie_bootstrap_summary.csv", replace
rename lower bootstrap_lower
rename upper bootstrap_upper
tempfile fairboot
save `fairboot'
use "$OUTPUT/data/fairlie_point.dta", clear
keep if model=="F2"
merge 1:1 term using `fairboot', nogen keep(master match)
order term estimate share_raw_gap bootstrap_se bootstrap_lower bootstrap_upper N N_south N_north reps successful
export delimited using "$TABLES/Table5_fairlie.csv", replace

* Table 6. Prespecified robustness checks reported in the manuscript.
use "$OUTPUT/data/robustness_results.dta", clear
keep if (inlist(robustness_variant_id,"wave_2010","wave_2014","allrural_cropstatus","probit","unwinsorized_income") & inlist(term,"AME_edu","AME_edu_RE_marginal")) | (substr(robustness_variant_id,1,10)=="leaveout_p" & term=="AME_edu_RE_marginal")
keep robustness_variant_id model term estimate se p N clusters status note
export delimited using "$TABLES/Table6_robustness.csv", replace

* PSM balance summaries used in Table 7 and the supplement.
use "$OUTPUT/data/psm_balance.dta", clear
keep if stage=="after"
gen double abs_smd=abs(smd)
quietly summarize abs_smd, detail
local psm_mean_smd=r(mean)
local psm_median_smd=r(p50)
local psm_max_smd=r(max)
quietly count if abs_smd>10
local psm_over10=r(N)
gsort -abs_smd
local psm_max_var=variable[1]
export delimited using "$TABLES/PSM_postmatch_balance.csv", replace

* Table 7. PSM and IV-Probit.
postfile t7 str16 analysis str48 statistic double estimate se lower upper p str120 diagnostic using "$OUTPUT/data/Table7_psm_iv.dta", replace
use "$OUTPUT/data/supplementary_results.dta", clear
quietly summarize estimate if model=="S1_PSM" & scale=="ATET", meanonly
local psm_att=r(mean)
quietly summarize se if model=="S1_PSM" & scale=="ATET", meanonly
local psm_se=r(mean)
quietly summarize lower if model=="S1_PSM" & scale=="ATET", meanonly
local psm_lo=r(mean)
quietly summarize upper if model=="S1_PSM" & scale=="ATET", meanonly
local psm_hi=r(mean)
quietly summarize p if model=="S1_PSM" & scale=="ATET", meanonly
local psm_p=r(mean)
post t7 ("PSM") ("ATET") (`psm_att') (`psm_se') (`psm_lo') (`psm_hi') (`psm_p') ("Mean abs SMD=`psm_mean_smd'; median=`psm_median_smd'; max=`psm_max_smd' (`psm_max_var'); >10%=`psm_over10'")

quietly summarize estimate if model=="S2_IV_firststage" & term=="loo_edu", meanonly
local iv_b=r(mean)
quietly summarize p if model=="S2_IV_firststage" & term=="loo_edu", meanonly
local iv_bp=r(mean)
quietly summarize estimate if model=="S2_IV_probit" & scale=="AME" & term=="edu", meanonly
local iv_ame=r(mean)
quietly summarize se if model=="S2_IV_probit" & scale=="AME" & term=="edu", meanonly
local iv_se=r(mean)
quietly summarize lower if model=="S2_IV_probit" & scale=="AME" & term=="edu", meanonly
local iv_lo=r(mean)
quietly summarize upper if model=="S2_IV_probit" & scale=="AME" & term=="edu", meanonly
local iv_hi=r(mean)
quietly summarize p if model=="S2_IV_probit" & scale=="AME" & term=="edu", meanonly
local iv_p=r(mean)
use "$OUTPUT/data/supplementary_diagnostics.dta", clear
quietly summarize value if model=="S2_IV" & statistic=="firststage_cluster_F", meanonly
local iv_f=r(mean)
quietly summarize value if model=="S2_IV" & statistic=="firststage_partial_R2", meanonly
local iv_r2=r(mean)
post t7 ("IV-Probit") ("First-stage IV coefficient") (`iv_b') (.) (.) (.) (`iv_bp') ("F=`iv_f'; partial R2=`iv_r2'")
post t7 ("IV-Probit") ("Education AME") (`iv_ame') (`iv_se') (`iv_lo') (`iv_hi') (`iv_p') ("")
postclose t7
use "$OUTPUT/data/Table7_psm_iv.dta", clear
export delimited using "$TABLES/Table7_psm_iv.csv", replace

* Table 8. KHB and two-wave lagged analysis.
use "$OUTPUT/data/supplementary_results.dta", clear
keep if inlist(model,"S3_KHB","S3_KHB_disentangle","S4_lag") & (model!="S4_lag" | scale=="AME")
keep model scale term estimate se lower upper p N clusters status note
export delimited using "$TABLES/Table8_khb_lagged.csv", replace

* Table 9. Gender and age-group heterogeneity.
use "$OUTPUT/data/gender_heterogeneity.dta", clear
gen str16 dimension="Gender"
rename statistic result
append using "$OUTPUT/data/age_group_heterogeneity.dta"
replace dimension="Age" if missing(dimension)
capture confirm variable statistic
if !_rc replace result=statistic if result==""
keep dimension model result estimate se lower upper p N clusters
export delimited using "$TABLES/Table9_heterogeneity.csv", replace

* FINAL RESULT VERIFICATION.
capture program drop addcheck
program define addcheck
    args label expected actual tolerance
    local difference=`actual'-`expected'
    local status=cond(abs(`difference')<=`tolerance',"PASS","FAIL")
    post cw ("`label'") (`expected') (`actual') (`difference') (`tolerance') ("`status'")
end

postfile cw str64 result double manuscript_value replicated_value difference tolerance str8 status using "$ROOT/documentation/result_crosswalk.dta", replace
addcheck "Final N" 15165 `n_primary' 0

use "$OUTPUT/data/main_model_results.dta", clear
quietly summarize estimate if model=="B1_baseline" & scale=="AME_fixed" & term=="edu", meanonly
local baseline_edu=r(mean)
quietly summarize estimate if model=="B1_baseline" & scale=="AME_fixed" & term=="1.plants", meanonly
local baseline_plants=r(mean)
quietly summarize estimate if model=="H2_context" & scale=="AME" & term=="rice10", meanonly
local h2_rice=r(mean)
quietly summarize p if model=="H3_interaction" & scale=="coefficient" & term=="exercise:c.edu_c#c.rice10", meanonly
local interaction_p=r(mean)
quietly summarize p if model=="H3_interaction" & scale=="AME_difference" & term=="P75_minus_P25", meanonly
local p75p25_p=r(mean)
addcheck "Education AME" .045273 `baseline_edu' .0000005
addcheck "Cultivation AME" -.015222 `baseline_plants' .0000005
addcheck "Historical rice AME H2" -.007304 `h2_rice' .0000005

use "$OUTPUT/data/fairlie_point.dta", clear
quietly summarize share_raw_gap if model=="F2" & term=="expl", meanonly
local fairlie_share=r(mean)
addcheck "Fairlie explained share" 92.072 `fairlie_share' .0005

addcheck "PSM ATET" .085199 `psm_att' .0000005
addcheck "PSM mean absolute SMD" 2.594 `psm_mean_smd' .0005
addcheck "PSM maximum absolute SMD" 12.156 `psm_max_smd' .0005
addcheck "IV first-stage F" 284.743 `iv_f' .0005
addcheck "IV AME" .077790 `iv_ame' .0000005

use "$OUTPUT/data/supplementary_results.dta", clear
quietly summarize estimate if model=="S3_KHB" & term=="edu:Reduced", meanonly
local khb_reduced=r(mean)
quietly summarize estimate if model=="S3_KHB" & term=="edu:Full", meanonly
local khb_full=r(mean)
quietly summarize estimate if model=="S3_KHB" & term=="edu:Diff", meanonly
local khb_diff=r(mean)
local khb_share=100*`khb_diff'/`khb_reduced'
quietly summarize estimate if model=="S4_lag" & scale=="AME" & term=="edu2010", meanonly
local lag_edu=r(mean)
addcheck "KHB Full" .092987 `khb_full' .0000005
addcheck "KHB share" 53.706 `khb_share' .0005
addcheck "Lagged education AME" .035893 `lag_edu' .0000005

use "$OUTPUT/data/gender_heterogeneity.dta", clear
quietly summarize estimate if statistic=="female_education_AME", meanonly
local female_ame=r(mean)
quietly summarize estimate if statistic=="male_education_AME", meanonly
local male_ame=r(mean)
addcheck "Female AME" .035337 `female_ame' .0000005
addcheck "Male AME" .055097 `male_ame' .0000005

use "$OUTPUT/data/age_group_heterogeneity.dta", clear
quietly summarize estimate if statistic=="age_16_39_education_AME", meanonly
local age1=r(mean)
quietly summarize estimate if statistic=="age_40_59_education_AME", meanonly
local age2=r(mean)
quietly summarize estimate if statistic=="age_60_plus_education_AME", meanonly
local age3=r(mean)
addcheck "Age 16-39 AME" .051144 `age1' .0000005
addcheck "Age 40-59 AME" .035575 `age2' .0000005
addcheck "Age 60+ AME" .066945 `age3' .0000005
addcheck "Education x historical rice p" .585 `interaction_p' .0005
addcheck "P75-P25 education AME difference p" .903 `p75p25_p' .0005
postclose cw

use "$ROOT/documentation/result_crosswalk.dta", clear
export delimited using "$ROOT/documentation/result_crosswalk.csv", replace
count if status=="FAIL"
local failures=r(N)
display "FINAL_RESULT_VERIFICATION_FAILURES=`failures'"
display "FINALIZE_OUTPUTS_COMPLETE"
log close
exit
