version 17.0
clear all
set more off
set linesize 255
set seed 20260910

global R5 "$OUTPUT"
log using "$R5/logs/05_supplementary.log", text replace
about
which psmatch2
which khb

local C "c.age_c c.age_c2 i.gender i.marriage c.ln_income i.health3 i.sportsArea"
local FE "i.provcd i.year"

postfile sr str32 model str24 scale str100 term double estimate se p lower upper long N int clusters str16 status str244 note using "$R5/data/supplementary_results.dta", replace
postfile sd str32 model str48 statistic double value str244 note using "$R5/data/supplementary_diagnostics.dta", replace
postfile sb str12 stage str32 variable double treated_mean control_mean smd variance_ratio using "$R5/data/psm_balance.dta", replace

program define postall
    args model scale note
    matrix B=e(b)
    matrix V=e(V)
    local names: colfullnames B
    local n=.
    local c=.
    capture local n=e(N)
    capture local c=e(N_clust)
    local j=0
    foreach term of local names {
        local ++j
        local b=B[1,`j']
        local s=sqrt(V[`j',`j'])
        local pp=cond(`s'>0,2*normal(-abs(`b'/`s')),. )
        post sr ("`model'") ("`scale'") ("`term'") (`b') (`s') (`pp') (`b'-invnormal(.975)*`s') (`b'+invnormal(.975)*`s') (`n') (`c') ("ok") ("`note'")
    }
end

program define postmargins
    args model scale note
    matrix T=r(table)
    local names: colfullnames T
    local n=.
    local c=.
    capture local n=e(N)
    capture local c=e(N_clust)
    local j=0
    foreach term of local names {
        local ++j
        post sr ("`model'") ("`scale'") ("`term'") (T[1,`j']) (T[2,`j']) (T[4,`j']) (T[5,`j']) (T[6,`j']) (`n') (`c') ("ok") ("`note'")
    }
end

* -----------------------------------------------------------------------------
* S1. Prespecified 1:2 propensity-score matching (ATET).
* Treatment is completed junior secondary or above (edu>=3). Matching uses
* the original covariate set plus province and wave indicators. Default
* replacement is retained; no outcome-driven caliper or trimming is introduced.
* -----------------------------------------------------------------------------
use "$R5/data/analysis_primary.dta", clear
isid pid year
gen byte edu_high=edu>=3
capture confirm variable year14
if _rc gen byte year14=year==2014
tab provcd, gen(pv_)
unab pvall: pv_*
local pvbase: word 1 of `pvall'
local pvlist: list pvall - pvbase
local psmvars "plants age_c age_c2 gender marriage ln_income health_fair health_poor sportsArea year14 `pvlist'"
sort pid year
quietly count if edu_high==1
post sd ("S1_PSM") ("treated_before") (r(N)) ("education at least junior secondary")
quietly count if edu_high==0
post sd ("S1_PSM") ("controls_before") (r(N)) ("education below junior secondary")

capture noisily psmatch2 edu_high `psmvars', outcome(exercise) logit neighbor(2) common
local rc_psm=_rc
if `rc_psm' {
    post sr ("S1_PSM") ("ATET") ("edu_high") (.) (.) (.) (.) (.) (.) (.) ("failed") ("psmatch2 return code `rc_psm'; frozen 1:2 common-support specification")
    post sd ("S1_PSM") ("return_code") (`rc_psm') ("psmatch2 failed")
}
else {
    local att=r(att)
    local seatt=r(seatt)
    local patt=2*normal(-abs(`att'/`seatt'))
    quietly count if _treated==1 & _support==1
    local nt=r(N)
    quietly count if _treated==0 & _weight>0 & _support==1
    local nc=r(N)
    post sr ("S1_PSM") ("ATET") ("edu_high") (`att') (`seatt') (`patt') (`att'-invnormal(.975)*`seatt') (`att'+invnormal(.975)*`seatt') (`nt') (.) ("ok") ("1:2 nearest-neighbor matching with replacement and common support; psmatch2 approximate SE")
    post sd ("S1_PSM") ("treated_on_support") (`nt') ("treated observations retained on common support")
    post sd ("S1_PSM") ("unique_controls_used") (`nc') ("control observations with positive matching weight")
    foreach g in 0 1 {
        quietly count if _treated==`g' & _support==0
        post sd ("S1_PSM") ("offsupport_group`g'") (r(N)) ("group 0=below junior secondary; group 1=junior secondary or above")
        quietly summarize _pscore if _treated==`g'
        post sd ("S1_PSM") ("pscore_min_group`g'") (r(min)) ("estimated propensity-score range")
        post sd ("S1_PSM") ("pscore_max_group`g'") (r(max)) ("estimated propensity-score range")
    }

    foreach v of local psmvars {
        quietly summarize `v' if _treated==1
        local mt=r(mean)
        local vt=r(Var)
        quietly summarize `v' if _treated==0
        local mc=r(mean)
        local vc=r(Var)
        local smd=100*(`mt'-`mc')/sqrt((`vt'+`vc')/2)
        local vr=cond(`vc'>0,`vt'/`vc',.)
        post sb ("before") ("`v'") (`mt') (`mc') (`smd') (`vr')

        quietly summarize `v' [aw=_weight] if _treated==1 & _support==1
        local mt=r(mean)
        local vt=r(Var)
        quietly summarize `v' [aw=_weight] if _treated==0 & _support==1 & _weight>0
        local mc=r(mean)
        local vc=r(Var)
        local smd=100*(`mt'-`mc')/sqrt((`vt'+`vc')/2)
        local vr=cond(`vc'>0,`vt'/`vc',.)
        post sb ("after") ("`v'") (`mt') (`mc') (`smd') (`vr')
    }

    preserve
    gen byte score_bin=min(floor(_pscore*20)+1,20) if !missing(_pscore)
    collapse (count) N=_pscore (mean) mean_pscore=_pscore (sum) on_support=_support, by(_treated score_bin)
    rename _treated edu_high
    save "$R5/data/psm_overlap_bins.dta", replace
    export delimited using "$R5/tables/psm_overlap_bins.csv", replace
    restore

    keep pid year exercise edu edu_high _treated _support _weight _pscore _id _nn _n1 _n2
    save "$R5/data/psm_matched_working.dta", replace
}

* -----------------------------------------------------------------------------
* S2. Community-wave leave-one-out mean education instrument.
* The instrument is constructed from every nonmissing education report in the
* original-eligible rural file, before primary crop and complete-case filters.
* -----------------------------------------------------------------------------
use "$R5/data/eligible_rural_before_complete_cases.dta", clear
keep if !missing(edu)
bysort cid_wave: egen double community_edu_sum=total(edu)
bysort cid_wave: gen long community_edu_n=_N
bysort cid_wave: keep if _n==1
keep cid_wave community_edu_sum community_edu_n
tempfile community_edu
save `community_edu'

use "$R5/data/analysis_primary.dta", clear
merge m:1 cid_wave using `community_edu', assert(match using) keep(match) nogen
gen double loo_edu=(community_edu_sum-edu)/(community_edu_n-1) if community_edu_n>1
quietly count if community_edu_n<=1
post sd ("S2_IV") ("singleton_primary_observations") (r(N)) ("excluded because a leave-one-out community-wave mean is undefined")
quietly egen byte tag_singleton=tag(cid_wave) if community_edu_n<=1
quietly count if tag_singleton==1
post sd ("S2_IV") ("singleton_community_waves") (r(N)) ("eligible-rural nonmissing-education community-wave groups of size one")
drop tag_singleton

capture noisily regress edu c.loo_edu i.plants `C' `FE' if !missing(loo_edu), vce(cluster provcd)
local rc_fs=_rc
if `rc_fs' {
    post sr ("S2_IV_firststage") ("coefficient") ("loo_edu") (.) (.) (.) (.) (.) (.) (.) ("failed") ("first-stage return code `rc_fs'")
    post sd ("S2_IV") ("firststage_return_code") (`rc_fs') ("clustered linear first stage failed")
}
else {
    estimates save "$R5/estimates/S2_IV_firststage.ster", replace
    gen byte iv_sample=e(sample)
    matrix B=e(b)
    matrix V=e(V)
    local j=colnumb(B,"loo_edu")
    local b=B[1,`j']
    local s=sqrt(V[`j',`j'])
    local pp=2*ttail(e(df_r),abs(`b'/`s'))
    post sr ("S2_IV_firststage") ("coefficient") ("loo_edu") (`b') (`s') (`pp') (`b'-invttail(e(df_r),.025)*`s') (`b'+invttail(e(df_r),.025)*`s') (e(N)) (e(N_clust)) ("ok") ("community-wave leave-one-out mean from pre-complete-case eligible rural sample")
    test loo_edu
    post sd ("S2_IV") ("firststage_cluster_F") (r(F)) ("one excluded instrument; province-clustered test")
    post sd ("S2_IV") ("firststage_p") (r(p)) ("one excluded instrument; province-clustered test")
    local r2u=e(r2)
    quietly regress edu i.plants `C' `FE' if iv_sample
    local r2r=e(r2)
    local partialr2=(`r2u'-`r2r')/(1-`r2r')
    post sd ("S2_IV") ("firststage_partial_R2") (`partialr2') ("incremental conventional R-squared; clustered F is the inference statistic")
    quietly count if iv_sample
    post sd ("S2_IV") ("analysis_N") (r(N)) ("primary rows with defined leave-one-out instrument")

    capture noisily ivprobit exercise i.plants `C' `FE' (edu=loo_edu) if iv_sample, vce(cluster provcd)
    local rc_iv=_rc
    if `rc_iv' {
        post sr ("S2_IV_probit") ("coefficient") ("edu") (.) (.) (.) (.) (.) (.) (.) ("failed") ("ivprobit return code `rc_iv'; instrument validity is not inferred from relevance")
        post sd ("S2_IV") ("ivprobit_return_code") (`rc_iv') ("maximum-likelihood IV-probit failed")
    }
    else {
        estimates save "$R5/estimates/S2_IV_probit.ster", replace
        postall S2_IV_probit coefficient "maximum-likelihood IV-probit; latent-index coefficients; province-clustered VCE"
        capture noisily margins, dydx(edu) predict(pr)
        local rc_marg=_rc
        if `rc_marg' {
            post sr ("S2_IV_probit") ("AME") ("edu") (.) (.) (.) (.) (.) (e(N)) (e(N_clust)) ("failed") ("IV-probit probability AME return code `rc_marg'")
        }
        else postmargins S2_IV_probit AME "average probability derivative from the fitted IV-probit; not evidence that the exclusion restriction holds"
        capture noisily estat endogenous
    }
}

* -----------------------------------------------------------------------------
* S3. KHB rescaling-adjusted nested-model decomposition with verified comparable
* word and math algorithms; scores are standardized separately within each wave.
* -----------------------------------------------------------------------------
use "$R5/data/analysis_primary.dta", clear
bysort year: egen double word_z=std(wordtest)
bysort year: egen double math_z=std(mathtest)
quietly count if missing(word_z,math_z)
post sd ("S3_KHB") ("cognition_missing") (r(N)) ("wordtest/mathtest special codes were removed during source reconstruction")
capture noisily khb probit exercise c.edu || c.word_z c.math_z, concomitant(i.plants `C' `FE') vce(cluster provcd) summary disentangle
local rc_khb=_rc
if `rc_khb' {
    post sr ("S3_KHB") ("coefficient") ("edu") (.) (.) (.) (.) (.) (.) (.) ("failed") ("khb return code `rc_khb'")
    post sd ("S3_KHB") ("return_code") (`rc_khb') ("KHB probit failed")
}
else {
    estimates save "$R5/estimates/S3_KHB_core.ster", replace
    ereturn list
    matrix list e(b)
    postall S3_KHB coefficient "KHB probit total, direct and rescaling-adjusted difference; cognition is not treated as causally identified mediation"

    capture noisily khb probit exercise c.edu || c.word_z c.math_z, concomitant(i.plants `C' `FE') vce(cluster provcd) disentangle postdisentangle
    local rc_dis=_rc
    if `rc_dis' {
        post sr ("S3_KHB_disentangle") ("component") ("cognition_components") (.) (.) (.) (.) (.) (.) (.) ("failed") ("postdisentangle return code `rc_dis'")
    }
    else {
        estimates save "$R5/estimates/S3_KHB_disentangle.ster", replace
        ereturn list
        matrix list e(b)
        postall S3_KHB_disentangle component "KHB contribution of standardized word and math scores to the nested-model coefficient difference"
    }
}

* -----------------------------------------------------------------------------
* S4. Two-wave temporal-ordering check. The outcome is 2014 exercise; 2010
* cognition and education enter with 2010 exercise and all 2010 controls.
* This selective two-wave sample is not a causal mediation design.
* -----------------------------------------------------------------------------
use "$R5/data/analysis_primary.dta", clear
bysort year: egen double word_z=std(wordtest)
bysort year: egen double math_z=std(mathtest)
tempfile primary_z cohort2010 eligible2014
save `primary_z'
preserve
keep if year==2010
keep pid
isid pid
save `cohort2010'
restore

use "$R5/data/eligible_rural_before_complete_cases.dta", clear
keep if year==2014
keep pid
isid pid
save `eligible2014'
use `cohort2010', clear
merge 1:1 pid using `eligible2014'
quietly count if _merge==3
post sd ("S4_lag") ("2010_primary_with_2014_eligible_rural") (r(N)) ("retained in the 2014 original-eligible rural file before complete-case and crop restrictions")

use `primary_z', clear
keep pid year exercise edu word_z math_z plants age_c age_c2 gender marriage ln_income health3 sportsArea provcd cid_wave
reshape wide exercise edu word_z math_z plants age_c age_c2 gender marriage ln_income health3 sportsArea provcd cid_wave, i(pid) j(year)
quietly count if !missing(exercise2010,exercise2014)
local npair=r(N)
post sd ("S4_lag") ("two_wave_primary_pairs") (`npair') ("meets the corrected primary-sample rules in both waves")
post sd ("S4_lag") ("retention_from_2010_primary") (`npair'/8452) ("two-wave primary pairs divided by 8,452 primary observations in 2010")
keep if !missing(exercise2010,exercise2014)

capture noisily logit exercise2014 c.edu2010 c.word_z2010 c.math_z2010 i.exercise2010 i.plants2010 c.age_c2010 c.age_c22010 i.gender2010 i.marriage2010 c.ln_income2010 i.health32010 i.sportsArea2010 i.provcd2010, vce(cluster provcd2010) nolog
local rc_lag=_rc
if `rc_lag' {
    post sr ("S4_lag") ("coefficient") ("cognition_2010") (.) (.) (.) (.) (.) (.) (.) ("failed") ("lagged logit return code `rc_lag'")
    post sd ("S4_lag") ("return_code") (`rc_lag') ("2014 exercise on 2010 predictors failed")
}
else {
    estimates save "$R5/estimates/S4_lag.ster", replace
    postall S4_lag coefficient "2014 exercise on 2010 education and standardized cognition, controlling 2010 exercise/covariates; selected two-wave sample"
    margins, dydx(edu2010 word_z2010 math_z2010)
    postmargins S4_lag AME "average probability derivatives in the selected two-wave sample; temporal ordering does not identify mediation"
}

postclose sr
postclose sd
postclose sb

foreach f in supplementary_results supplementary_diagnostics psm_balance {
    use "$R5/data/`f'.dta", clear
    export delimited using "$R5/tables/`f'.csv", replace
}

display "SUPPLEMENTARY_COMPLETE"
log close
exit
