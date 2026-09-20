version 17.0
clear all
set more off
set linesize 255
set seed 20260910

global R4 "$OUTPUT"
log using "$R4/logs/04_robustness.log", text replace

* Frozen robustness menu. Facility-control estimates are provisional pending
* source-level audit of conditional community-question skip codes.
local C "c.age_c c.age_c2 i.gender i.marriage c.ln_income i.health3 i.sportsArea"
local FE "i.provcd i.year"
postfile rr str40 robustness_variant_id str24 model str32 term double estimate se p long N int clusters str18 status str120 note using "$R4/data/robustness_results.dta", replace
postfile bb int rep str12 target double ame_edu ame_rice ame_diff byte success using "$R4/data/historical_province_bootstrap_draws.dta", replace

program define post_edu
    args variant model note
    matrix B=e(b)
    matrix V=e(V)
    local pos=colnumb(B,"edu")
    if `pos' > 0 {
        local b=B[1,`pos']
        local s=sqrt(V[`pos',`pos'])
        local p=2*normal(-abs(`b'/`s'))
        post rr ("`variant'") ("`model'") ("edu") (`b') (`s') (`p') (e(N)) (e(N_clust)) ("ok") ("`note'")
    }
end

program define post_ame_edu
    args variant model note
    quietly margins, dydx(edu)
    matrix T=r(table)
    local b=T[1,1]
    local s=T[2,1]
    local p=T[4,1]
    post rr ("`variant'") ("`model'") ("AME_edu") (`b') (`s') (`p') (e(N)) (e(N_clust)) ("ok") ("`note'")
end

* Pre-specified wave estimands and all-rural crop-status sensitivity.
use "$R4/data/analysis_primary.dta", clear
foreach y in 2010 2014 {
    capture noisily melogit exercise c.edu i.plants `C' `FE' if year==`y' || cid_wave:, vce(cluster provcd) nolog
    if _rc post rr ("wave_`y'") ("melogit") ("edu") (.) (.) (.) (.) (.) ("failed") ("return code `_rc'; facility control provisional")
    else {
        post_edu wave_`y' melogit "frozen baseline within wave; facility control provisional"
        post_ame_edu wave_`y' melogit "fixed-part AME; facility control provisional"
    }
}

use "$R4/data/analysis_allrural.dta", clear
capture noisily melogit exercise c.edu i.crop_status `C' `FE' || cid_wave:, vce(cluster provcd) nolog
if _rc post rr ("allrural_cropstatus") ("melogit") ("edu") (.) (.) (.) (.) (.) ("failed") ("return code `_rc'; crop_status=neither/rice/wheat/mixed")
else {
    post_edu allrural_cropstatus melogit "all rural; i.crop_status retains neither and mixed; facility control provisional"
    post_ame_edu allrural_cropstatus melogit "fixed-part AME; facility control provisional"
}

* Link-function, education-functional-form, and income-transform sensitivities.
use "$R4/data/analysis_primary.dta", clear
capture noisily probit exercise c.edu i.plants `C' `FE', vce(cluster provcd) nolog
if _rc post rr ("probit") ("probit") ("edu") (.) (.) (.) (.) (.) ("failed") ("return code `_rc'; facility control provisional")
else {
    post_edu probit probit "province/year FE, province clustered; facility control provisional"
    post_ame_edu probit probit "AME; facility control provisional"
}

capture noisily melogit exercise i.edu_cat i.plants `C' `FE' || cid_wave:, vce(cluster provcd) nolog
if _rc post rr ("education_categorical") ("melogit") ("education_categories") (.) (.) (.) (.) (.) ("failed") ("return code `_rc'; categories 6+ combined")
else {
    matrix B=e(b)
    matrix V=e(V)
    local cn: colfullnames B
    foreach z of local cn {
        if strpos("`z'",".edu_cat") {
            local j=colnumb(B,"`z'")
            local b=B[1,`j']
            local s=sqrt(V[`j',`j'])
            local p=2*normal(-abs(`b'/`s'))
            post rr ("education_categorical") ("melogit") ("`z'") (`b') (`s') (`p') (e(N)) (e(N_clust)) ("ok") ("education categories, 6+ combined; facility control provisional")
        }
    }
}

local Craw "c.age_c c.age_c2 i.gender i.marriage c.ln_income_raw i.health3 i.sportsArea"
capture noisily melogit exercise c.edu i.plants `Craw' `FE' || cid_wave:, vce(cluster provcd) nolog
if _rc post rr ("unwinsorized_income") ("melogit") ("edu") (.) (.) (.) (.) (.) ("failed") ("return code `_rc'; no income winsorization")
else {
    post_edu unwinsorized_income melogit "uses ln_income_raw; facility control provisional"
    post_ame_edu unwinsorized_income melogit "fixed-part AME; facility control provisional"
}

* Leave-one-province-out uses the frozen primary specification and preserves every attempt.
use "$R4/data/analysis_primary.dta", clear
levelsof provcd, local(provs)
foreach p of local provs {
    capture noisily melogit exercise c.edu i.plants `C' `FE' if provcd!=`p' || cid_wave:, vce(cluster provcd) nolog
    if _rc post rr ("leaveout_p`p'") ("melogit") ("edu") (.) (.) (.) (.) (.) ("failed") ("return code `_rc'; facility control provisional")
    else {
        post_edu leaveout_p`p' melogit "excluded province `p'; facility control provisional"
        post_ame_edu leaveout_p`p' melogit "excluded province `p'; fixed-part AME; facility control provisional"
    }
}

* Historical estimands: logit + year FE + province clustering, no province FE.
use "$R4/data/analysis_primary.dta", clear
capture noisily logit exercise c.edu c.rice10 i.plants `C' c.ln_gdp_hist c.urban2016_10 i.year, vce(cluster provcd) nolog
if _rc post rr ("historical_urban2016") ("logit") ("edu") (.) (.) (.) (.) (.) ("failed") ("return code `_rc'; urban2016 replacement")
else {
    post_edu historical_urban2016 logit "historical urban2016 replacement; facility control provisional"
    quietly margins, dydx(rice10)
    matrix T=r(table)
    post rr ("historical_urban2016") ("logit") ("AME_rice10") (T[1,1]) (T[2,1]) (T[4,1]) (e(N)) (e(N_clust)) ("ok") ("historical urban2016 replacement; facility control provisional")
}

capture noisily logit exercise c.edu c.rice10 i.plants `C' c.ln_gdp_hist c.urban2000_10 i.year if !inlist(provcd,50,51), vce(cluster provcd) nolog
if _rc post rr ("historical_excl_SC_CQ") ("logit") ("edu") (.) (.) (.) (.) (.) ("failed") ("return code `_rc'; exclude Sichuan/Chongqing")
else {
    post_edu historical_excl_SC_CQ logit "exclude provinces 50 and 51; facility control provisional"
    quietly margins, dydx(rice10)
    matrix T=r(table)
    post rr ("historical_excl_SC_CQ") ("logit") ("AME_rice10") (T[1,1]) (T[2,1]) (T[4,1]) (e(N)) (e(N_clust)) ("ok") ("exclude provinces 50 and 51; facility control provisional")
}

* External 1,999-draw province bootstrap. Quantiles and education centering are
* frozen from the original primary data and retained in each draw.
use "$R4/data/analysis_primary.dta", clear
quietly summarize rice10, detail
local r25=r(p25)
local r75=r(p75)
tempfile base
save `base'
forvalues r=1/1999 {
    use `base', clear
    bsample, cluster(provcd) idcluster(bs_prov)
    capture noisily logit exercise c.edu c.rice10 i.plants `C' c.ln_gdp_hist c.urban2000_10 i.year, nolog
    if _rc {
        post bb (`r') ("H2") (.) (.) (.) (0)
    }
    else {
        capture quietly margins, dydx(edu rice10)
        if _rc post bb (`r') ("H2") (.) (.) (.) (0)
        else {
            matrix T=r(table)
            post bb (`r') ("H2") (T[1,1]) (T[1,2]) (.) (1)
        }
    }
    use `base', clear
    bsample, cluster(provcd) idcluster(bs_prov)
    capture noisily logit exercise c.edu_c##c.rice10 i.plants `C' c.ln_gdp_hist c.urban2000_10 i.year, nolog
    if _rc post bb (`r') ("H3") (.) (.) (.) (0)
    else {
        capture quietly margins, dydx(edu_c) at(rice10=(`r25' `r75'))
        if _rc post bb (`r') ("H3") (.) (.) (.) (0)
        else {
            matrix T=r(table)
            local d=T[1,2]-T[1,1]
            post bb (`r') ("H3") (T[1,1]) (.) (`d') (1)
        }
    }
    if mod(`r',100)==0 display "BOOTSTRAP_REP=`r'"
}
postclose bb
postclose rr

use "$R4/data/robustness_results.dta", clear
export delimited using "$R4/tables/robustness_results.csv", replace

use "$R4/data/main_model_results.dta", clear
quietly summarize estimate if model=="H2_context" & scale=="AME" & term=="edu", meanonly
local point_h2_edu=r(mean)
quietly summarize estimate if model=="H2_context" & scale=="AME" & term=="rice10", meanonly
local point_h2_rice=r(mean)
quietly summarize estimate if model=="H3_interaction" & scale=="AME_difference" & term=="P75_minus_P25", meanonly
local point_h3_diff=r(mean)

use "$R4/data/historical_province_bootstrap_draws.dta", clear
postfile hs str8 target str24 term double estimate long attempted successful failures double bootstrap_se lower upper using "$R4/data/historical_province_bootstrap_summary.dta", replace
quietly count if target=="H2"
local attempted_h2=r(N)
quietly count if target=="H2" & success==1
local successful_h2=r(N)
foreach v in ame_edu ame_rice {
    quietly summarize `v' if target=="H2" & success==1
    local bse=r(sd)
    quietly _pctile `v' if target=="H2" & success==1, p(2.5 97.5)
    local lo=r(r1)
    local hi=r(r2)
    if "`v'"=="ame_edu" local point=`point_h2_edu'
    if "`v'"=="ame_rice" local point=`point_h2_rice'
    post hs ("H2") ("`v'") (`point') (`attempted_h2') (`successful_h2') (`attempted_h2'-`successful_h2') (`bse') (`lo') (`hi')
}
quietly count if target=="H3"
local attempted_h3=r(N)
quietly count if target=="H3" & success==1
local successful_h3=r(N)
quietly summarize ame_diff if target=="H3" & success==1
local bse=r(sd)
quietly _pctile ame_diff if target=="H3" & success==1, p(2.5 97.5)
post hs ("H3") ("P75_minus_P25") (`point_h3_diff') (`attempted_h3') (`successful_h3') (`attempted_h3'-`successful_h3') (`bse') (r(r1)) (r(r2))
postclose hs
use "$R4/data/historical_province_bootstrap_summary.dta", clear
export delimited using "$R4/tables/historical_province_bootstrap_summary.csv", replace
display "ROBUSTNESS_COMPLETE"
log close
exit
