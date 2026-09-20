version 17.0
clear all
set more off
set linesize 255
set seed 20260910
global R2 "$OUTPUT"
log using "$R2/logs/02_main_models.log", text replace
about
which fairlie
which khb
which psmatch2
global C2 "c.age_c c.age_c2 i.gender i.marriage c.ln_income i.health3 i.sportsArea"
global FE2 "i.provcd i.year"
postfile result str32 model str16 scale str100 term double estimate se p lower upper long N int clusters using "$R2/data/main_model_results.dta", replace
postfile diag str32 model str40 statistic double value using "$R2/data/main_model_diagnostics.dta", replace

program define savecoef
    args model
    estimates save "$R2/estimates/`model'.ster", replace
    matrix BB=e(b)
    matrix VV=e(V)
    local names: colfullnames BB
    local j=0
    foreach term of local names {
        local ++j
        local b=BB[1,`j']
        local se=sqrt(VV[`j',`j'])
        local pp=cond(`se'>0,2*normal(-abs(`b'/`se')),.)
        post result ("`model'") ("coefficient") ("`term'") (`b') (`se') (`pp') (`b'-invnormal(.975)*`se') (`b'+invnormal(.975)*`se') (e(N)) (e(N_clust))
    }
    foreach st in N N_clust ll converged {
        capture post diag ("`model'") ("`st'") (e(`st'))
    }
end

program define savemarg
    args model scale
    matrix TT=r(table)
    local names: colfullnames TT
    local j=0
    foreach term of local names {
        local ++j
        post result ("`model'") ("`scale'") ("`term'") (TT[1,`j']) (TT[2,`j']) (TT[4,`j']) (TT[5,`j']) (TT[6,`j']) (e(N)) (e(N_clust))
    }
end

program define savecontrast
    args model term
    matrix CB=r(b)
    matrix CV=r(V)
    assert colsof(CB)==2
    local d=CB[1,2]-CB[1,1]
    local s=sqrt(CV[1,1]+CV[2,2]-2*CV[1,2])
    local p=2*normal(-abs(`d'/`s'))
    post result ("`model'") ("AME_difference") ("`term'") (`d') (`s') (`p') (`d'-invnormal(.975)*`s') (`d'+invnormal(.975)*`s') (e(N)) (e(N_clust))
end

use "$R2/data/analysis_primary.dta", clear
isid pid year
assert _N==15165
quietly summarize edu
local ec=r(mean)
quietly summarize rice10, detail
local r25=r(p25)
local r75=r(p75)
post diag ("sample") ("education_center") (`ec')
post diag ("sample") ("rice10_p25") (`r25')
post diag ("sample") ("rice10_p75") (`r75')
quietly summarize income_split_log
post diag ("sample") ("income_median_log") (r(mean))

* Descriptive statistics use exactly the primary estimation sample.
preserve
postfile ds str20 group str32 variable double N mean sd min max using "$R2/data/descriptive.dta", replace
foreach g in All South North Wave2010 Wave2014 Rice Wheat {
    local iff "1"
    if "`g'"=="South" local iff "part==0"
    if "`g'"=="North" local iff "part==1"
    if "`g'"=="Wave2010" local iff "year==2010"
    if "`g'"=="Wave2014" local iff "year==2014"
    if "`g'"=="Rice" local iff "plants==0"
    if "`g'"=="Wheat" local iff "plants==1"
    foreach v in exercise exercise_freq edu plants age gender marriage income_raw ln_income health3 sportsArea rice_hist ln_gdp_hist urban2000 wordtest mathtest {
        quietly summarize `v' if `iff'
        post ds ("`g'") ("`v'") (r(N)) (r(mean)) (r(sd)) (r(min)) (r(max))
    }
}
postclose ds
restore

* Canonical baseline ID baseline-9e91decddf7a.
melogit exercise i.provcd i.year || cid_wave:, vce(cluster provcd) nolog
savecoef B0_null
estat icc
return list
melogit exercise c.edu i.plants $C2 $FE2 || cid_wave:, vce(cluster provcd) nolog
savecoef B1_baseline
estat icc
return list
margins, dydx(edu plants) predict(mu fixedonly)
savemarg B1_baseline AME_fixed

* Population-level logit alternative and historical-context progression.
logit exercise c.edu i.plants $C2 $FE2, vce(cluster provcd) nolog
savecoef B2_logit_FE
margins, dydx(edu plants)
savemarg B2_logit_FE AME

forvalues k=0/2 {
    local ctx ""
    if `k'>=1 local ctx "c.ln_gdp_hist"
    if `k'==2 local ctx "c.ln_gdp_hist c.urban2000_10"
    logit exercise c.edu c.rice10 i.plants $C2 `ctx' i.year, vce(cluster provcd) nolog
    savecoef H`k'_context
    margins, dydx(edu rice10 plants)
    savemarg H`k'_context AME
}

* Pooled regional interaction: do not set region counterfactually while
* keeping province FE fixed. Region main effect is absorbed by province FE.
melogit exercise c.edu i.part#c.edu i.plants $C2 $FE2 || cid_wave:, vce(cluster provcd) nolog
savecoef G1_region
test 1.part#c.edu
post diag ("G1_region") ("interaction_wald_p") (r(p))
margins, dydx(edu) over(part) predict(mu fixedonly)
savemarg G1_region AME_observed
savecontrast G1_region North_minus_South
margins, over(part) at(edu=(1 2 3 4 5 6)) predict(mu fixedonly) saving("$R2/data/figure_region_predictions.dta", replace)

foreach g in 0 1 {
    melogit exercise c.edu i.plants $C2 $FE2 if part==`g' || cid_wave:, vce(cluster provcd) nolog
    savecoef G1_split`g'
    margins, dydx(edu plants) predict(mu fixedonly)
    savemarg G1_split`g' AME_fixed
}

* Original income split retained, rebuilt using corrected pooled median.
melogit exercise c.edu##i.inc_high i.plants $C2 $FE2 || cid_wave:, vce(cluster provcd) nolog
savecoef G2_income
test 1.inc_high#c.edu
post diag ("G2_income") ("interaction_wald_p") (r(p))
margins, dydx(edu) over(inc_high) predict(mu fixedonly)
savemarg G2_income AME_observed
savecontrast G2_income High_minus_Low
margins, over(inc_high) at(edu=(1 2 3 4 5 6)) predict(mu fixedonly) saving("$R2/data/figure_income_predictions.dta", replace)
foreach g in 0 1 {
    melogit exercise c.edu i.plants $C2 $FE2 if inc_high==`g' || cid_wave:, vce(cluster provcd) nolog
    savecoef G2_split`g'
    margins, dydx(edu plants) predict(mu fixedonly)
    savemarg G2_split`g' AME_fixed
}

* Historical interaction is exploratory, schooling centered for rice main effect.
logit exercise c.edu_c##c.rice10 i.plants $C2 c.ln_gdp_hist c.urban2000_10 i.year, vce(cluster provcd) nolog
savecoef H3_interaction
test c.edu_c#c.rice10
post diag ("H3_interaction") ("interaction_wald_p") (r(p))
margins, dydx(edu_c) at(rice10=(`r25' `r75'))
savemarg H3_interaction AME_quartiles
savecontrast H3_interaction P75_minus_P25
margins, dydx(edu_c) at(rice10=(0(.5)8.5)) saving("$R2/data/figure_historical_AME.dta", replace)

postclose result
postclose diag
foreach f in main_model_results main_model_diagnostics descriptive {
    use "$R2/data/`f'.dta", clear
    export delimited using "$R2/tables/`f'.csv", replace
}
display "MAIN_MODELS_COMPLETE"
log close
exit
