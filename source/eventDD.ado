*! eventDD: Script for generating event study plot
*! Version 0.0.0 august 3, 2019 @ 22:54:54
*! Author: Damian Clarke

/*
TO ADD:
 - use only 'balanced' sample
 - look at building CIs with wild clustered SEs?
 - give alternative graph options
 - allow for xtreg , fe version...
 - error checking -- ie what if a lag or lead has no units with this particular lag

*/

cap program drop eventDD
program eventDD, eclass
vers 11.0

#delimit ;
syntax varlist(min=2 fv ts numeric) [if] [in] [pweight fweight aweight iweight],
  timevar(varlist min=1 max=1)
  lags(integer)
  leads(integer)
  [
  baseline(integer -1)
  ytitle(passthru)
  *
  ];
#delimit cr

local wt [`weight' `exp']


local lagvars
foreach lag of numlist 0(1)`lags' {
    tempvar lag`lag'
    gen `lag`lag''=`timevar'==`lag'
    local lagvars `lagvars' `lag`lag''
}
local leadvars
foreach lead of numlist `leads'(-1)2 {
    tempvar lead`lead'
    gen `lead`lead''=`timevar'==-`lead'
    local leadvars `leadvars' `lead`lead''   
}

reg `varlist' `leadvars' `lagvars' `if' `in' `wt' , `options' 

foreach var in time point uCI lCI {
    tempvar `var'
    qui gen ``var''=.
}

local i = 1
foreach lead of numlist `leads'(-1)2 {
    qui replace `time'=-`lead' in `i'
    qui replace `point'=_b[`lead`lead''] in `i'
    qui replace `uCI'  =_b[`lead`lead'']+invttail(e(N),0.975)*_se[`lead`lead''] in `i'
    qui replace `lCI'  =_b[`lead`lead'']+invttail(e(N),0.025)*_se[`lead`lead''] in `i'
    local ++i
}
qui replace `time'=-1 in `i'
qui replace `point'=0 in `i'
qui replace `uCI'  =0 in `i'
qui replace `lCI'  =0 in `i'
local ++i
foreach lag of numlist 0(1)`lags' {
    qui replace `time'=`lag' in `i'
    qui replace `point'=_b[`lag`lag''] in `i'
    qui replace `uCI'  =_b[`lag`lag'']+invttail(e(N),0.975)*_se[`lag`lag''] in `i'
    qui replace `lCI'  =_b[`lag`lag'']+invttail(e(N),0.025)*_se[`lag`lag''] in `i'
    local ++i
}
local --i

graph set eps fontface "Times New Roman"
set scheme s1mono
#delimit ;
twoway rarea `lCI' `uCI' `time', color(gs14%40) yline(0, lcolor(red))
    || scatter `point' `time' in 1/`i', ms(dh) mc(blue)
xline(-1, lcolor(black) lpattern(solid))
xlabel(-`leads'(1)`lags') legend(order(2 "Point Estimate" 1 "95% CI"))
`ytitle' xtitle("Time");
#delimit cr

end
