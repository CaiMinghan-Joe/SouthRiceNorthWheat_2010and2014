version 17.0
clear all
set more off
set linesize 255
set seed 20260914

* Package paths are defined by the master do-file.
capture log close _all
log using "$OUTPUT/logs/07_age_group_heterogeneity.log", text replace

postfile out str24 model str40 statistic double estimate se p lower upper long N int clusters using "$OUTPUT/data/age_group_heterogeneity.dta", replace
use "$OUTPUT/data/analysis_primary.dta", clear
isid pid year
gen byte age_main=cond(inrange(age,16,39),1,cond(inrange(age,40,59),2,3))
assert inlist(age_main,1,2,3)

global X "i.plants c.age_c c.age_c2 i.gender i.marriage c.ln_income i.health3 i.sportsArea"
melogit exercise c.edu##i.age_main $X i.provcd i.year || cid_wave:, vce(cluster provcd) nolog
local nn=e(N)
local cc=e(N_clust)
margins, dydx(edu) over(age_main) predict(mu fixedonly)
matrix MB=r(b)
matrix MV=r(V)
forvalues j=1/3 {
    if `j'==1 local lbl "age_16_39_education_AME"
    if `j'==2 local lbl "age_40_59_education_AME"
    if `j'==3 local lbl "age_60_plus_education_AME"
    local b=MB[1,`j']
    local s=sqrt(MV[`j',`j'])
    local pp=2*normal(-abs(`b'/`s'))
    post out ("age_primary") ("`lbl'") (`b') (`s') (`pp') (`b'-invnormal(.975)*`s') (`b'+invnormal(.975)*`s') (`nn') (`cc')
}
matrix RR=(-1,1,0 \ -1,0,1)
matrix DD=RR*MB'
matrix WW=RR*MV*RR'
matrix QQ=DD'*syminv(WW)*DD
scalar wald=QQ[1,1]
scalar overall_p=chi2tail(2,wald)
post out ("age_primary") ("overall_probability_AME_test") (wald) (.) (overall_p) (.) (.) (`nn') (`cc')

local d=MB[1,3]-MB[1,2]
local s=sqrt(MV[2,2]+MV[3,3]-2*MV[2,3])
local pp=2*normal(-abs(`d'/`s'))
post out ("age_primary") ("age_60_plus_minus_40_59") (`d') (`s') (`pp') (`d'-invnormal(.975)*`s') (`d'+invnormal(.975)*`s') (`nn') (`cc')
postclose out

use "$OUTPUT/data/age_group_heterogeneity.dta", clear
export delimited using "$OUTPUT/tables/age_group_heterogeneity.csv", replace
list, noobs
display "AGE_GROUP_HETEROGENEITY_COMPLETE"
log close
exit
