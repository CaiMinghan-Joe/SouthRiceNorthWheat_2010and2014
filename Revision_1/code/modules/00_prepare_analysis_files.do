version 17.0
clear all
set more off

use "$DATA/HSSC_analysis_data_final.dta", clear
isid pid year
count
assert r(N)==16035
assert initial_eligible_N==20148
count if sample_current_ricewheat==1
assert r(N)==15752
count if sample_allrural==1
assert r(N)==15418
count if sample_primary==1
assert r(N)==15165
assert health3==1 if inrange(health_raw,1,3)
assert health3==2 if health_raw==4
assert health3==3 if health_raw==5
assert missing(health3) if health_raw<0 | missing(health_raw)
assert rice10==rice_hist*10 if !missing(rice10,rice_hist)
assert age_c==age-45 if !missing(age)
assert age_c2==age_c^2 if !missing(age_c)

preserve
keep if sample_primary==1
count if year==2010
assert r(N)==8452
count if year==2014
assert r(N)==6713
egen byte tag_province=tag(provcd)
count if tag_province
assert r(N)==23
drop tag_province
egen byte tag_community_wave=tag(cid_wave)
count if tag_community_wave
assert r(N)==506
drop tag_community_wave
save "$OUTPUT/data/analysis_primary.dta", replace
restore

preserve
keep if sample_allrural==1
foreach v in income_clean income_w ln_income ln_income_raw inc_high income_split_log edu_c edu_center {
    replace `v'=`v'_allrural
}
save "$OUTPUT/data/analysis_allrural.dta", replace
restore

save "$OUTPUT/data/eligible_rural_before_complete_cases.dta", replace
display "PREPARE_ANALYSIS_FILES_COMPLETE"
exit
