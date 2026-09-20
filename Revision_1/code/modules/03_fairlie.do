version 17.0
clear all
set more off
set processors 2
set linesize 255
set seed 20260910
global R3 "$OUTPUT"
log using "$R3/logs/03_fairlie.log", text replace
use "$R3/data/analysis_primary.dta", clear
assert _N==15165
isid pid year
global Fbase "edu plants (age: age_c age_c2) gender marriage ln_income (health: health_fair health_poor) sportsArea year14"
global Fhist "$Fbase rice10"
global Ffull "$Fhist ln_gdp_hist urban2000_10"

* All three point models share the complete primary sample and year adjustment.
* The age polynomial and health dummy set are swapped jointly, not separately.
* Contributions and gap use South minus North; shares divide by the raw gap.
* Built-in variances are not used for cross-component inference.
postfile fp str8 model str32 term double estimate double builtin_se double share_raw_gap long N long N_south long N_north long reps using "$R3/data/fairlie_point.dta", replace
forvalues k=0/2 {
    local rhs "$Fbase"
    if `k'==1 local rhs "$Fhist"
    if `k'==2 local rhs "$Ffull"
    set seed 20260910
    fairlie exercise `rhs', by(part) pooled ro reps(1000) nodots
    estimates save "$R3/estimates/F`k'_fairlie.ster", replace
    matrix FB=e(b)
    matrix FV=e(V)
    local fterms: colnames FB
    local gap=e(diff)
    local j=0
    foreach v of local fterms {
        local ++j
        post fp ("F`k'") ("`v'") (FB[1,`j']) (sqrt(FV[`j',`j'])) (100*FB[1,`j']/`gap') (e(N)) (e(N_0)) (e(N_1)) (e(reps))
    }
    foreach v in diff expl pr_0 pr_1 {
        post fp ("F`k'") ("`v'") (e(`v')) (.) (cond(inlist("`v'","diff","expl"),100*e(`v')/`gap',.)) (e(N)) (e(N_0)) (e(N_1)) (e(reps))
    }
}
postclose fp
preserve
use "$R3/data/fairlie_point.dta", clear
export delimited using "$R3/tables/fairlie_point.csv", replace
restore
display "FAIRLIE_POINT_COMPLETE"

* Province clusters are resampled within the original South/North strata.
* Full F2 only: 999 outer draws, 100 random-order matches per draw.
* Each draw refits the pooled reference model. No significance selection.
postfile fb int draw int rc str32 term double estimate double raw_gap long N using "$R3/data/fairlie_bootstrap_draws.dta", replace
set seed 20260910
forvalues b=1/999 {
    preserve
    bsample, strata(part) cluster(provcd)
    capture quietly fairlie exercise $Ffull, by(part) pooled ro reps(100) nodots
    local rc=_rc
    if `rc'==0 {
        matrix BT=e(b)
        local terms: colnames BT
        local j=0
        foreach v of local terms {
            local ++j
            post fb (`b') (0) ("`v'") (BT[1,`j']) (e(diff)) (e(N))
        }
        foreach v in diff expl pr_0 pr_1 {
            post fb (`b') (0) ("`v'") (e(`v')) (e(diff)) (e(N))
        }
    }
    else post fb (`b') (`rc') ("FAILED") (.) (.) (_N)
    restore
    if mod(`b',25)==0 display "FAIRLIE_OUTER_DRAW `b'"
}
postclose fb
use "$R3/data/fairlie_bootstrap_draws.dta", clear
export delimited using "$R3/tables/fairlie_bootstrap_draws.csv", replace
display "FAIRLIE_BOOTSTRAP_COMPLETE"
log close
exit
