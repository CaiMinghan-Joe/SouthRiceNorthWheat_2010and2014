version 17.0
clear all
set more off
set linesize 255
set seed 20260914

* Package paths are defined by the master do-file.
capture log close _all
log using "$OUTPUT/logs/06_gender_heterogeneity.log", text replace

postfile out str24 model str32 statistic double estimate se p lower upper long N int clusters using "$OUTPUT/data/gender_heterogeneity.dta", replace
use "$OUTPUT/data/analysis_primary.dta", clear
isid pid year

melogit exercise c.edu##i.gender i.plants c.age_c c.age_c2 i.marriage c.ln_income i.health3 i.sportsArea i.provcd i.year || cid_wave:, vce(cluster provcd) nolog
local nn=e(N)
local cc=e(N_clust)
margins, dydx(edu) over(gender) predict(mu fixedonly)
matrix MB=r(b)
matrix MV=r(V)
forvalues j=1/2 {
    if `j'==1 local lbl "female_education_AME"
    if `j'==2 local lbl "male_education_AME"
    local b=MB[1,`j']
    local s=sqrt(MV[`j',`j'])
    local pp=2*normal(-abs(`b'/`s'))
    post out ("G3_gender") ("`lbl'") (`b') (`s') (`pp') (`b'-invnormal(.975)*`s') (`b'+invnormal(.975)*`s') (`nn') (`cc')
}
local d=MB[1,2]-MB[1,1]
local s=sqrt(MV[1,1]+MV[2,2]-2*MV[1,2])
local pp=2*normal(-abs(`d'/`s'))
post out ("G3_gender") ("male_minus_female") (`d') (`s') (`pp') (`d'-invnormal(.975)*`s') (`d'+invnormal(.975)*`s') (`nn') (`cc')
postclose out

use "$OUTPUT/data/gender_heterogeneity.dta", clear
export delimited using "$OUTPUT/tables/gender_heterogeneity.csv", replace
list, noobs
display "GENDER_HETEROGENEITY_COMPLETE"
log close
exit
