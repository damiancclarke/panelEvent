*! eventdd: Estimate panel event study models and generate plots
*! Version 1.0.0 february 14, 2020 @ 11:06:20
*! Author: Damian Clarke & Kathya Tapia Schythe

cap program drop eventdd
program eventdd, eclass
vers 13.0

*-------------------------------------------------------------------------------
*--- (1) Syntax definition and set-up
*-------------------------------------------------------------------------------
#delimit ;
syntax varlist(min=2 fv ts numeric) [if] [in] [pw fw aw iw],
timevar(varname)             /*Standardized time variable*/
ci(string)                   /*Type of CI, rarea, rcap or rline*/
  [
  baseline(integer -1)       /*Reference period*/
  accum                      /*Accumulate time in final lags and leads*/
  noend                      /*Don't plot end points with accum*/
  keepbal(varname)           /*Use only units balanced in all lags and leads*/
  lags(integer 0)            /*Number of lags to display with accum*/
  leads(integer 0)           /*Number of leads to display with accum*/
  ols fe hdfe                /*Type of FE estimation: FE, HDFE (default: OLS)*/
  absorb(passthru)           /*Only to be used where hdfe is specified*/
  wboot                      /*Wild bootstrap standard errors*/
  wboot_op(string)           /*Options for boottest*/
  *                          /*Other regression options*/
  balanced                   /*Use a balanced panel in all lags/leads selected*/
  inrange				     /*Show periods between lags and leads*/
  graph_op(string asis)      /*General graphing options: titles, subtitle, scheme, note, label */
  ci_op(string asis)         /*CI (rcap/rarea/line) graphing options*/
  coef_op(string)            /*Coef (scatter) graphing options*/
  endpoints_op(string asis)  /*Endpoints (scatter) graphing options*/
  ];
#delimit cr

local wt [`weight' `exp']

preserve


if strmatch("`varlist'", "*lead*")==0 { 
    capture drop lead*
}

if strpos("`varlist'", "*lag*")==0 { 
    capture drop lag*
}


rename `timevar' _Ptime
local tvar _Ptime

*-------------------------------------------------------------------------------
*--- (2) General syntax consistency check
*-------------------------------------------------------------------------------
if ("`ols'"!="") + ("`fe'"!="") + ("`hdfe'"!="") >1 { 
    di as err "choose only one of {bf:ols}, {bf:fe}, or {bf:hdfe}"
    exit 198 
}

if ("`hdfe'"!="") + ("`wboot'"!="")  >1 { 
    di as err "{bf:hdfe} may not be combined with {bf:wboot}"
    exit 198 
}

if ("`accum'"!="") + ("`balanced'"!="")  >1 { 
    di as err "choose only one of {bf:accum} or {bf:balanced}"
    exit 198 
}
		
if ("`accum'"=="") + ("`end'"!="")  >1 { 
    di as err "option {bf:end} requires {bf:accum}"
    exit 198 
}

if ("`accum'"!="") + ("`keepbal'"!="")  >1 { 
    di as err "choose only one of {bf:accum} or {bf:keepbal}" 
    exit 198 
}

if ("`balanced'"!="") + ("`keepbal'"!="")  >1 { 
    di as err "choose only one of {bf:balanced} or {bf:keepbal}" 
    exit 198 
}

if ("`inrange'"!="") + ("`keepbal'"!="")  >1 { 
    di as err "choose only one of {bf:inrange} or {bf:keepbal}" 
    exit 198 
}

if ("`balanced'"!="") + ("`inrange'"!="")  >1 { 
    di as err "choose only one of {bf:balanced} or {bf:inrange}" 
    exit 198 
}

if ("`accum'"!="") + ("`inrange'"!="")  >1 { 
    di as err "choose only one of {bf:accum} or {bf:inrange}"
    exit 198 
}

		
qui sum `tvar'
local min  = r(min)
local max  = r(max)
if `baseline' < `min' | `baseline' > `max' { 
    di as err "{bf:baseline} not found"
    exit 198 
}
		
if ("`lags'" != "0" ) & ("`accum'" == "" ) & ("`keepbal'" == "") & ("`inrange'" == "") ==1{
    di as err "options {bf:lags()} and {bf:leads()} require {bf:accum}, {bf:keepbal}  or {bf:inrange}"
    exit 198
}
if ("`leads'" != "0" ) & ("`accum'" == "" ) & ("`keepbal'" == "") & ("`inrange'" == "") ==1{
    di as err "options {bf:lags()} and {bf:leads()} require {bf:accum}, {bf:keepbal} or {bf:inrange}"
    exit 198
}
	
if ("`accum'" != "" ) + ("`keepbal'" != "") + ("`inrange'" != "") ==1  {
    if ("`lags'" == "0" ) ==  1{
        di as err "options {bf:lags()} and {bf:leads()} required"
        exit 198
    }
    if ("`leads'" == "0" ) == 1{
	di as err "options {bf:lags()} and {bf:leads()} required"
	exit 198
    }
    if  `min' > -`lags' { 
	di as err "{bf:lags} not found"
	exit 198 
    }
    if `max' < `leads' { 
	di as err "{bf:leads} not found"
	exit 198 
    }
    if `baseline' < -`lags' | `baseline' > `leads' { 
	di as err "{bf:baseline} is not between {bf:lags} and {bf:leads}"
	exit 198 
    }
}

if ("`ci'" != "rarea" ) & ("`ci'" != "rcap" ) & ("`ci'" != "rline" )==1{
    di as err "choose {bf:rarea}, {bf:rcap} or {bf:rline} in {bf:ci()}" 
    exit 198 
}

if ("`endpoints_op'" != "" ) & ("`accum'" == "" ) ==1{
    di as err "options {bf:endpoints_op} require {bf:accum}"
    exit 198
}

if strmatch(`"`ci_op'"', "*rarea*") + strmatch(`"`ci_op'"', "*rcap*") + strmatch(`"`ci_op'"', "*rline*")>=1 {
    di as err "specify the type of graph for confidence intervals (rarea, rcap or rline) in {bf:ci()}" 
    exit 198 
}

if strmatch(`"`coef_op'"', "*rarea*") + strmatch(`"`coef_op'"', "*rcap*") + strmatch(`"`coef_op'"', "*rline*")>=1 {
    di as err "specify the type of graph for confidence intervals (rarea, rcap or rline) in {bf:ci()}" 
    exit 198 
}

if strmatch(`"`graph_op'"', "*rarea*") + strmatch(`"`graph_op'"', "*rcap*") + strmatch(`"`graph_op'"', "*rline*")>=1 {
    di as err "specify the type of graph for confidence intervals (rarea, rcap or rline) in {bf:ci()}" 
    exit 198 
}

if strmatch(`"`ci_op'"', "*ti*") + strmatch(`"`coef_op'"', "*ti*") + strmatch(`"`endpoints_op'"', "*ti*")>=1 {
    di as err "specify the general options for graph (eg titles, labels, legends, scheme) in {bf:graph_op()}" 
    exit 198 
}

if strmatch(`"`ci_op'"', "*sch*") + strmatch(`"`coef_op'"', "*sch*") + strmatch(`"`endpoints_op'"', "*sch*")>=1 {
    di as err "specify the general options for graph (eg titles, labels, legends, scheme) in {bf:graph_op()}" 
    exit 198 
}

if strmatch(`"`ci_op'"', "*lab*") + strmatch(`"`coef_op'"', "*lab*") + strmatch(`"`endpoints_op'"', "*lab*")>=1 {
    di as err "specify the general options for graph (eg titles, labels, legends, scheme) in {bf:graph_op()}" 
    exit 198 
}

if strmatch(`"`ci_op'"', "*note*") + strmatch(`"`coef_op'"', "*note*") + strmatch(`"`endpoints_op'"', "*note*")>=1 {
    di as err "specify the general options for graph (eg titles, labels, legends, scheme) in {bf:graph_op()}" 
    exit 198 
}

if strmatch(`"`ci_op'"', "*leg*") + strmatch(`"`coef_op'"', "*leg*") + strmatch(`"`endpoints_op'"', "*leg*")>=1 {
    di as err "specify the general options for graph (eg titles, labels, legends, scheme) in {bf:graph_op()}" 
    exit 198 
}

*-------------------------------------------------------------------------------
*--- (3) Define lags and leads
*-------------------------------------------------------------------------------     
if ("`keepbal'"!="")== 1{
    local tbal=`lags'+`leads'+1
    qui tab `tvar' if `tvar'>=-`lags' & `tvar'<=`leads', gen(_Tbal)
	tempvar rbal
    qui egen `rbal'=rowtotal(_Tbal*)
	tempvar bal
    qui bysort `keepbal': egen `bal'=total(`rbal') if `rbal'!=0
    qui count if `bal'==`tbal'
    local un=r(N)
    if `un'==0{
        di as err "no unit meets the criteria"
	exit 
    }
    else {
        qui keep if `bal'==`tbal' | `tvar'==.
    }
    qui recode `tvar' (.=`baseline')
    qui char `tvar'[omit] `baseline'
    qui xi i.`tvar', pref(_lf)
}

else if ("`accum'"=="accum")== 1{
    qui recode `tvar' (.=`baseline') (-1000/-`lags'=-`lags') (`leads'/1000=`leads')
    qui char `tvar'[omit] `baseline'
    qui xi i.`tvar', pref(_lf)
}

else {
    qui recode `tvar' (.=`baseline')
    qui char `tvar'[omit] `baseline'
    qui xi i.`tvar', pref(_lf)
}

qui sum `tvar'
local tot  = r(max)-r(min)+1             
local min  = r(min)                      
local max  = r(max)                 
local blpre  = `baseline'-1              
local blpost = `baseline'+1
local _baseline = abs(`baseline') 
local _blpre    = abs(`baseline')-1
local _blpost   = abs(`baseline')+1
local t0  = abs(`min')+1
local t_1 = abs(`min')
local t_2 = abs(`min')-1
local t_3 = `max'-1
if `baseline'<=0 {
    local base = abs(`min')-abs(`baseline')+1
}
else {
    local base = abs(`min')+1 +`baseline'
}
local prebase  =`base'-1
local postbase =`base'+1

tempvar times
qui gen `times'=.


if `baseline'==`min' {
    local j = 1
    foreach ld of numlist `blpost'(1)`max' {
        qui replace `times'=`ld' in `j'
	local ++j
    }
    qui replace `times'=`baseline' in `j'
}
else if `baseline'==`max' {
    local j = 1
    foreach ld of numlist `min'(1)`blpre' {
        qui replace `times'=`ld' in `j'
	local ++j
    }
    qui replace `times'=`baseline' in `j'
}
else {
    local j = 1
    foreach ld of numlist `min'(1)`blpre' `blpost'(1)`max' {
        qui replace `times'=`ld' in `j'
	local ++j
    }
    qui replace `times'=`baseline' in `j'
}

sort `times'

if `baseline'<0 {
    if `baseline'==`min' {
        local i = 1
        foreach n of numlist `t_1'(-1)2{
            qui rename _lf_Ptime_`n' lag`i'
            local ++i
        }
    }
    else if `baseline'==-1 {
        local i = 2
        foreach n of numlist `prebase'(-1)1{
            qui rename _lf_Ptime_`n' lag`i'
            local ++i
        }
    }
    else {
        local i = 1
        foreach n of numlist `t_1'(-1)`postbase' `prebase'(-1)1{
            qui rename _lf_Ptime_`n' lag`i'
            local ++i
            if `n'== `postbase'{
                local ++i
            }
        }
    }
    local k = 0
    foreach n of numlist `t0'(1)`tot'{
        qui rename _lf_Ptime_`n' lead`k'
	local ++k
    }
    
    local tot_lags lag*
    local tot_leads lead*
}
else if `baseline'>=0 {
    if `baseline'==`max' {
        local k = 0
        foreach n of numlist `t0'(1)`prebase'{
            qui rename _lf_Ptime_`n' lead`k'
            local ++k
        }
    }
    else if `baseline'==0 {
        local k = 1
        foreach n of numlist `postbase'(1)`tot'{
            qui rename _lf_Ptime_`n' lead`k'
            local ++k
        }
    }
    else {
        local k = 0
        foreach n of numlist `t0'(1)`prebase' `postbase'(1)`tot'{
            qui rename _lf_Ptime_`n' lead`k'
            local ++k
            if `n'== `prebase'{
                local ++k
            }
        }
    }
    local i = 1
    foreach n of numlist `t_1'(-1)1{
        qui rename _lf_Ptime_`n' lag`i'
	local ++i
    }
    
    local tot_lags lag*
    local tot_leads lead*
}

*-------------------------------------------------------------------------------
*--- (4) Estimate models
*-------------------------------------------------------------------------------     
if ("`hdfe'"=="hdfe") == 1{
    foreach ado in hdfe ftools {
        cap which `ado'
        if _rc!=0 ssc install `ado'
    }
    cap reghdfe, compile
    
    if ("`absorb'" == "") ==1{
	di as err "option {bf:absorb()} required"
	exit 198
    }
    dis as err "Note: with {bf:HDFE} option do not include in {bf:varlist} the categorical variables" 
	dis as err "      that identify the fixed effects to be absorbed in {bf:absorb()}"
		
    reghdfe `varlist' `tot_lags' `tot_leads' `if' `in' `wt' , `absorb' `options' 
}

else if ("`fe'"=="fe") == 1{
	dis as err "Note: with {bf:FE} option do not include in {bf:varlist} the categorical variables" 
	dis as err "      that identify the individual fixed effect" 
    
    xtreg `varlist' `tot_lags' `tot_leads' `if' `in' `wt' , fe `options' 
}
	
else {
    reg `varlist' `tot_lags' `tot_leads' `if' `in' `wt' , `options' 
}

qui matrix v=e(V)

*-------------------------------------------------------------------------------
*--- (5) Generate point estimates and confidence intervals
*-------------------------------------------------------------------------------
 
foreach var in point uCI lCI {
    tempvar `var'
    qui gen ``var''=.
}

sort `times'

if `baseline'<0 {
    if ("`wboot'"=="wboot") == 1{
        if `baseline'==`min' {
            local i = 2
            foreach t of numlist `t_2'(-1)1{
                qui replace `point'=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op'
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI'  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lag`t'[1,2] in `i'
                local ++i
            }
        }
        else if `baseline'==-1 {
            local i = 1
            foreach t of numlist `t_1'(-1)2{
                qui replace `point'=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op'
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI'  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lag`t'[1,2] in `i'
                local ++i
            }
            local ++i
        }
        else {
            local i = 1
            foreach t of numlist `t_1'(-1)`_blpost' `_blpre'(-1)1{
                qui replace `point'=_b[lag`t'] in `i'
                
                cap qui boottest lag`t', nograph `wboot_op'
                cap mat ci_lag`t'= r(CI)
                cap qui replace `lCI'  = ci_lag`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lag`t'[1,2] in `i'
                local ++i
                if `t'== `_blpost'{
                    local ++i
                }
            }
        }
        foreach t of numlist 0(1)`max'{
            qui replace `point'=_b[lead`t'] in `i'
            
            cap qui boottest lead`t', nograph `wboot_op'
            cap mat ci_lead`t'= r(CI)
            cap qui replace `lCI'  = ci_lead`t'[1,1] in `i'
            cap qui replace `uCI'  = ci_lead`t'[1,2] in `i'
            local ++i
        }
    local lev   = r(level)
	
	}
    else {
	local lev   = r(level)
	local alp   = (100-r(level))/100
	local critu = `alp'/2
	local critl = 1-`critu'
	
        if `baseline'==`min' {
            local i = 2
            foreach t of numlist `t_2'(-1)1{
                qui replace `point'=_b[lag`t'] in `i'
                qui replace `lCI'  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI'  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
            }
        }
        else if `baseline'==-1 {
            local i = 1
            foreach t of numlist `t_1'(-1)2{
                qui replace `point'=_b[lag`t'] in `i'
                qui replace `lCI'  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI'  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
            }
            local ++i
        }
        else {
            local i = 1
            foreach t of numlist `t_1'(-1)`_blpost' `_blpre'(-1)1{
                qui replace `point'=_b[lag`t'] in `i'
                qui replace `lCI'  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
                qui replace `uCI'  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
                local ++i
                if `t'== `_blpost'{
                    local ++i
                }
            }
        }
        foreach t of numlist 0(1)`max'{
            qui replace `point'=_b[lead`t'] in `i'
            qui replace `lCI'  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
            qui replace `uCI'  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
            local ++i
        }
    }
    
    qui replace `point'=0 if `times'==`baseline'
    qui replace `uCI'  =0 if `times'==`baseline'
    qui replace `lCI'  =0 if `times'==`baseline'
    
    qui replace `uCI'  =0 if `times'!=. & `uCI'==.
    qui replace `lCI'  =0 if `times'!=. & `lCI'==.
    
    
    sort `times'
    
    tempvar lgs
    qui gen `lgs'= abs(`times')
    qui mkmat `lgs' `lCI' `point' `uCI' if `times'<0 & `times'!=., matrix(lags)
    qui matrix colnames lags = Lag LB Est UB
    *qui matrix rownames lags = .
    qui matsort lags 1 "up"
    
    tempvar lds
    qui gen `lds'=`times'
    qui mkmat `lds' `lCI' `point' `uCI' if `times'>=0 & `times'!=., matrix(leads)
    qui matrix colnames leads = Lead LB Est UB
    *qui matrix rownames leads = .
    qui matsort leads 1 "up"
    
    /*
    di %~59s "Lags Matrix"
    if ("`accum'"=="accum") == 1{
        di %~59s "Lag `lags' corresponds to `lags'+"
    }
    
    mat list lags, noheader
    di %~59s " "
    di %~59s "Leads Matrix"
    if ("`accum'"=="accum") == 1{
       di %~59s "Lead `leads' corresponds to `leads'+"
    }
    mat list leads, noheader
    */
}
else if `baseline'>=0 {
    if ("`wboot'"=="wboot") == 1{
        local i = 1
        foreach t of numlist `t_1'(-1)1{
            qui replace `point'=_b[lag`t'] in `i'
            
            cap qui boottest lag`t', nograph `wboot_op'
            cap mat ci_lag`t'= r(CI)
            cap qui replace `lCI'  = ci_lag`t'[1,1] in `i'
            cap qui replace `uCI'  = ci_lag`t'[1,2] in `i'
            local ++i
        }
        if `baseline'==`max' {
            foreach t of numlist 0(1)`t_3'{
                qui replace `point'=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op'
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI'  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lead`t'[1,2] in `i'
                local ++i
            }
        }
        else if `baseline'==0 {
            local ++i
            foreach t of numlist 1(1)`max'{
                qui replace `point'=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op'
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI'  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lead`t'[1,2] in `i'
                local ++i
            }
        }
        else {
            foreach t of numlist 0(1)`_blpre' `_blpost'(1)`max'{
                qui replace `point'=_b[lead`t'] in `i'
                
                cap qui boottest lead`t', nograph `wboot_op'
                cap mat ci_lead`t'= r(CI)
                cap qui replace `lCI'  = ci_lead`t'[1,1] in `i'
                cap qui replace `uCI'  = ci_lead`t'[1,2] in `i'
                local ++i
                if `t'== `_blpre'{
                    local ++i
                }
            }
        }
    local lev   = r(level)
	
	}
    else {
	local lev   = r(level)
	local alp   = (100-r(level))/100
	local critu = `alp'/2
	local critl = 1-`critu'
	
        local i=1
        foreach t of numlist `t_1'(-1)1{
            qui replace `point'=_b[lag`t'] in `i'
            qui replace `lCI'  =_b[lag`t']+invttail(e(df_r),`critl')*_se[lag`t'] in `i'
            qui replace `uCI'  =_b[lag`t']+invttail(e(df_r),`critu')*_se[lag`t'] in `i'
            local ++i
        }
        if `baseline'==`max' {
            foreach t of numlist 0(1)`t_3'{
                qui replace `point'=_b[lead`t'] in `i'
                qui replace `lCI'  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI'  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
            }
        }
        else if `baseline'==0 {
            local ++i
            foreach t of numlist 1(1)`max'{
                qui replace `point'=_b[lead`t'] in `i'
                qui replace `lCI'  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI'  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
            }
        }
        else {
            foreach t of numlist 0(1)`_blpre' `_blpost'(1)`max'{
                qui replace `point'=_b[lead`t'] in `i'
                qui replace `lCI'  =_b[lead`t']+invttail(e(df_r),`critl')*_se[lead`t'] in `i'
                qui replace `uCI'  =_b[lead`t']+invttail(e(df_r),`critu')*_se[lead`t'] in `i'
                local ++i
                if `t'== `_blpre'{
                    local ++i
                }
            }
        }
    }
    
    qui replace `point'=0 if `times'==`baseline'
    qui replace `uCI'  =0 if `times'==`baseline'
    qui replace `lCI'  =0 if `times'==`baseline'
    
    qui replace `uCI'  =0 if `times'!=. & `uCI'==.
    qui replace `lCI'  =0 if `times'!=. & `lCI'==.
    
    
    sort `times'
    
    tempvar lgs
    qui gen `lgs'= abs(`times')
    qui mkmat `lgs' `lCI' `point' `uCI' if `times'<0 & `times'!=., matrix(lags)
    qui matrix colnames lags = Lag LB Est UB
    *qui matrix rownames lags = .
    qui matsort lags 1 "up"
    
    tempvar lds
    qui gen `lds'=`times'
    qui mkmat `lds' `lCI' `point' `uCI' if `times'>=0 & `times'!=., matrix(leads)
    qui matrix colnames leads = Lead LB Est UB
    *qui matrix rownames leads = .
    qui matsort leads 1 "up"

    /*
    di %~59s "Lags Matrix"
    if ("`accum'"=="accum") == 1{
       di %~59s "Lag `lags' corresponds to `lags'+"
    }  
    mat list lags, noheader
    di %~59s " "
    di %~59s "Leads Matrix"
    if ("`accum'"=="accum") == 1{
        di %~59s "Lead `leads' corresponds to `leads'+"
    }
    mat list leads, noheader
    */
}

qui sum `times'
local minlag  = -r(min)
local maxlead = r(max)

qui matrix vll=v["lag`minlag'".."lead`maxlead'", "lag`minlag'".."lead`maxlead'"]

*-------------------------------------------------------------------------------
*--- (6) Graph
*-------------------------------------------------------------------------------     
sort `times'

foreach var in zero col {
    tempvar `var'
    qui gen ``var''=.
}

if `lCI'==`point'==`uCI'==0 & _n==1 & `baseline'!=`min'{
qui replace `zero'=1 if `lCI'==0 & `point'==0 & `uCI'==0
qui replace `col' =1 if (`zero'[_n]==`zero'[_n+1] & `zero'!=.) | (`zero'[_n]==`zero'[_n-1] & `zero'!=.)

qui replace `lCI'  =. if `col'==1 & `times'<`baseline'
qui replace `point'=. if `col'==1 & `times'<`baseline' 
qui replace `uCI'  =. if `col'==1 & `times'<`baseline'
qui replace `times'=. if `col'==1 & `times'<`baseline'
}

if `lCI'==`point'==`uCI'==0 & _n==`tot' & `baseline'!=`max'{
qui replace `zero'=1 if `lCI'==0 & `point'==0 & `uCI'==0
qui replace `col' =1 if (`zero'[_n]==`zero'[_n-1] & `zero'!=.) | (`zero'[_n]==`zero'[_n+1] & `zero'!=.)

qui replace `lCI'  =. if `col'==1 & `times'>`baseline'
qui replace `point'=. if `col'==1 & `times'>`baseline'
qui replace `uCI'  =. if `col'==1 & `times'>`baseline'
qui replace `times'=. if `col'==1 & `times'>`baseline'
}

if strmatch(`"`graph_op'"', "*leg*")==1 {

if strmatch(`"`graph_op'"', "*xti*")==1 { 
    if ("`balanced'"=="balanced") == 1{
        tempvar obs
        qui gen `obs'=.
       
        local k = 1
        foreach t of numlist `min'(1)`max' {
            qui sum `tvar' if `tvar'==`t'
            qui replace `obs'=r(N)  in `k'
            local ++k
        }
        qui tab `tvar', matcell(x)
        foreach ado in matsort {
            cap which `ado'
            if _rc!=0 ssc install `ado'
        }
        matsort  x 1 "down"
        local max2=el(x,2,1) 
        qui tab `times' if `obs'>=`max2'
        local bal=r(r)
        
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if `obs'>=`max2',
        `ci_op'
		yline(0, lcolor(red))
        || scatter `point' `times'   if `obs'>=`max2', 
        `coef_op'  
        xline(`baseline', lcolor(black) lpattern(solid))
        `graph_op';
        #delimit cr
    }
    else if ("`accum'"=="accum") == 1{
        if ("`end'"=="noend") == 1{
            local lpoint = `lags' -1 
            local upoint = `leads'-1 
			
            #delimit ;
            twoway `ci' `lCI' `uCI' `times' if inrange(`times', -`lpoint', `upoint'),
            `ci_op'
			yline(0, lcolor(red))       
            || scatter `point' `times' if inrange(`times', -`lpoint', `upoint'), 
            `coef_op' 
			xline(`baseline', lcolor(black) lpattern(solid))
            `graph_op';
            #delimit cr
        }
        else {
			
            #delimit ;
            twoway `ci' `lCI' `uCI' `times',
            `ci_op'
			yline(0, lcolor(red))       
            || scatter `point' `times', 
			`coef_op'
            || scatter `point' `times' if `times'==-`lags' | `times'==`leads', 
			`endpoints_op'
            xline(`baseline', lcolor(black) lpattern(solid))
            `graph_op';
            #delimit cr
        }
    }
    else if ("`keepbal'"!="") == 1 {

        #delimit ;
        twoway `ci' `lCI' `uCI' `times',
        `ci_op'
		yline(0, lcolor(red))       
        || scatter `point' `times', 
        `coef_op'
        xline(`baseline', lcolor(black) lpattern(solid))
        `graph_op';
        #delimit cr
    }
    else if ("`inrange'"!="") == 1 {
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if inrange(`times', -`lags', `leads'),
        `ci_op'
		yline(0, lcolor(red))       
        || scatter `point' `times' if inrange(`times', -`lags', `leads'), 
        `coef_op'
        xline(`baseline', lcolor(black) lpattern(solid))
        `graph_op';
        #delimit cr	
		}
    else {
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if inrange(`times', `min', `max'),
        `ci_op' 
		yline(0, lcolor(red))       
        || scatter `point' `times' if inrange(`times', `min', `max'), 
        `coef_op'
		xline(`baseline', lcolor(black) lpattern(solid))
        `graph_op';
        #delimit cr
    }
}

else { 
    if ("`balanced'"=="balanced") == 1{
        tempvar obs
        qui gen `obs'=.
        
        local k = 1
        foreach t of numlist `min'(1)`max' {
            qui sum `tvar' if `tvar'==`t'
            qui replace `obs'=r(N)  in `k'
            local ++k
        }
        qui tab `tvar', matcell(x)
        foreach ado in matsort {
            cap which `ado'
            if _rc!=0 ssc install `ado'
        }
        matsort  x 1 "down"
        local max2=el(x,2,1) 
        qui tab `times' if `obs'>=`max2'
        local bal=r(r)
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if `obs'>=`max2',
        `ci_op' 
		yline(0, lcolor(red))       
        || scatter `point' `times'   if `obs'>=`max2', 
        `coef_op'	   
        xline(`baseline', lcolor(black) lpattern(solid))
        `graph_op'
        xtitle("Time");
        #delimit cr
    }
    else if ("`accum'"=="accum") == 1 {
        if ("`end'"=="noend") == 1{
            local lpoint = `lags' -1 
            local upoint = `leads'-1 
			
            #delimit ;
            twoway `ci' `lCI' `uCI' `times' if inrange(`times', -`lpoint', `upoint'),
            `ci_op' 
			yline(0, lcolor(red))       
            || scatter `point' `times' if inrange(`times', -`lpoint', `upoint'), 
            `coef_op' 
			xline(`baseline', lcolor(black) lpattern(solid))
            `graph_op'
            xtitle("Time");
           #delimit cr
        }
        else {

            #delimit ;
            twoway `ci' `lCI' `uCI' `times', 
			`ci_op'
			yline(0, lcolor(red))       
            || scatter `point' `times', 
            `coef_op'
            || scatter `point' `times' if `times'==-`lags' | `times'==`leads', 
			`endpoints_op'
		    xline(`baseline', lcolor(black) lpattern(solid))
            `graph_op'
            xtitle("Time");
            #delimit cr
        }
    }
    else if ("`keepbal'"!="") == 1{
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times',
        `ci_op' 
		yline(0, lcolor(red))       
        || scatter `point' `times', 
        `coef_op'
		xline(`baseline', lcolor(black) lpattern(solid))
        `graph_op'
        xtitle("Time");
        #delimit cr
    }
	else if ("`inrange'"!="") == 1 {
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if inrange(`times', -`lags', `leads'),
        `ci_op'
		yline(0, lcolor(red))       
        || scatter `point' `times' if inrange(`times', -`lags', `leads'), 
        `coef_op'
        xline(`baseline', lcolor(black) lpattern(solid))
        `graph_op'
		xtitle("Time");
        #delimit cr	
		}
	else {

        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if inrange(`times', `min', `max'),
        `ci_op'
		yline(0, lcolor(red))       
        || scatter `point' `times' if inrange(`times', `min', `max'), 
        `coef_op'   
        xline(`baseline', lcolor(black) lpattern(solid))
        `graph_op'
        xtitle("Time");
        #delimit cr
    }
}
}


else{

if strmatch(`"`graph_op'"', "*xti*")==1 { 
    if ("`balanced'"=="balanced") == 1{
        tempvar obs
        qui gen `obs'=.
       
        local k = 1
        foreach t of numlist `min'(1)`max' {
            qui sum `tvar' if `tvar'==`t'
            qui replace `obs'=r(N)  in `k'
            local ++k
        }
        qui tab `tvar', matcell(x)
        foreach ado in matsort {
            cap which `ado'
            if _rc!=0 ssc install `ado'
        }
        matsort  x 1 "down"
        local max2=el(x,2,1) 
        qui tab `times' if `obs'>=`max2'
        local bal=r(r)
        
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if `obs'>=`max2',
        `ci_op'
		yline(0, lcolor(red))
        || scatter `point' `times'   if `obs'>=`max2', 
        `coef_op'  
        xline(`baseline', lcolor(black) lpattern(solid))
        legend(order(2 "Point Estimate" 1 "`lev'% CI"))
		`graph_op';
        #delimit cr
    }
    else if ("`accum'"=="accum") == 1{
        if ("`end'"=="noend") == 1{
            local lpoint = `lags' -1 
            local upoint = `leads'-1 
			
            #delimit ;
            twoway `ci' `lCI' `uCI' `times' if inrange(`times', -`lpoint', `upoint'),
            `ci_op'
			yline(0, lcolor(red))       
            || scatter `point' `times' if inrange(`times', -`lpoint', `upoint'), 
            `coef_op' 
			xline(`baseline', lcolor(black) lpattern(solid))
            legend(order(2 "Point Estimate" 1 "`lev'% CI"))
			`graph_op';
            #delimit cr
        }
        else {
			
            #delimit ;
            twoway `ci' `lCI' `uCI' `times',
            `ci_op'
			yline(0, lcolor(red))       
            || scatter `point' `times', 
			`coef_op'
            || scatter `point' `times' if `times'==-`lags' | `times'==`leads', 
			`endpoints_op'
            xline(`baseline', lcolor(black) lpattern(solid))
            legend(order(2 "Point Estimate" 1 "`lev'% CI"))
			`graph_op';
            #delimit cr
        }
    }
    else if ("`keepbal'"!="") == 1 {
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times',
        `ci_op'
		yline(0, lcolor(red))       
        || scatter `point' `times', 
        `coef_op'
        xline(`baseline', lcolor(black) lpattern(solid))
        legend(order(2 "Point Estimate" 1 "`lev'% CI"))
		`graph_op';
        #delimit cr
    }
    else if ("`inrange'"!="") == 1 {
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if inrange(`times', -`lags', `leads'),
        `ci_op'
		yline(0, lcolor(red))       
        || scatter `point' `times' if inrange(`times', -`lags', `leads'), 
        `coef_op'
        xline(`baseline', lcolor(black) lpattern(solid))
        legend(order(2 "Point Estimate" 1 "`lev'% CI"))
		`graph_op';
        #delimit cr	
		}
    else {
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if inrange(`times', `min', `max'),
        `ci_op' 
		yline(0, lcolor(red))       
        || scatter `point' `times' if inrange(`times', `min', `max'), 
        `coef_op'
		xline(`baseline', lcolor(black) lpattern(solid))
        legend(order(2 "Point Estimate" 1 "`lev'% CI"))
		`graph_op';
        #delimit cr
    }
}

else { 
    if ("`balanced'"=="balanced") == 1{
        tempvar obs
        qui gen `obs'=.
        
        local k = 1
        foreach t of numlist `min'(1)`max' {
            qui sum `tvar' if `tvar'==`t'
            qui replace `obs'=r(N)  in `k'
            local ++k
        }
        qui tab `tvar', matcell(x)
        foreach ado in matsort {
            cap which `ado'
            if _rc!=0 ssc install `ado'
        }
        matsort  x 1 "down"
        local max2=el(x,2,1) 
        qui tab `times' if `obs'>=`max2'
        local bal=r(r)
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if `obs'>=`max2',
        `ci_op' 
		yline(0, lcolor(red))       
        || scatter `point' `times'   if `obs'>=`max2', 
        `coef_op'	   
        xline(`baseline', lcolor(black) lpattern(solid))
        legend(order(2 "Point Estimate" 1 "`lev'% CI"))
        xtitle("Time")
		`graph_op';
        #delimit cr
    }
    else if ("`accum'"=="accum") == 1 {
        if ("`end'"=="noend") == 1{
            local lpoint = `lags' -1 
            local upoint = `leads'-1 
			
            #delimit ;
            twoway `ci' `lCI' `uCI' `times' if inrange(`times', -`lpoint', `upoint'),
            `ci_op' 
			yline(0, lcolor(red))       
            || scatter `point' `times' if inrange(`times', -`lpoint', `upoint'), 
            `coef_op' 
			xline(`baseline', lcolor(black) lpattern(solid))
            legend(order(2 "Point Estimate" 1 "`lev'% CI"))
            xtitle("Time")
			`graph_op';
           #delimit cr
        }
        else {
			
            #delimit ;
            twoway `ci' `lCI' `uCI' `times', 
			`ci_op'
			yline(0, lcolor(red))       
            || scatter `point' `times', 
            `coef_op'
            || scatter `point' `times' if `times'==-`lags' | `times'==`leads', 
			`endpoints_op'
		    xline(`baseline', lcolor(black) lpattern(solid))
            legend(order(2 "Point Estimate" 1 "`lev'% CI"))
            xtitle("Time")
			`graph_op';
            #delimit cr
        }
    }
    else if ("`keepbal'"!="") == 1{
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times',
        `ci_op' 
		yline(0, lcolor(red))       
        || scatter `point' `times', 
        `coef_op'
		xline(`baseline', lcolor(black) lpattern(solid))
        legend(order(2 "Point Estimate" 1 "`lev'% CI"))
        xtitle("Time")
		`graph_op';
        #delimit cr
    }
	else if ("`inrange'"!="") == 1 {
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if inrange(`times', -`lags', `leads'),
        `ci_op'
		yline(0, lcolor(red))       
        || scatter `point' `times' if inrange(`times', -`lags', `leads'), 
        `coef_op'
        xline(`baseline', lcolor(black) lpattern(solid))
        legend(order(2 "Point Estimate" 1 "`lev'% CI"))
		xtitle("Time")
		`graph_op';
        #delimit cr	
		}
	else {
		
        #delimit ;
        twoway `ci' `lCI' `uCI' `times' if inrange(`times', `min', `max'),
        `ci_op'
		yline(0, lcolor(red))       
        || scatter `point' `times' if inrange(`times', `min', `max'), 
        `coef_op'   
        xline(`baseline', lcolor(black) lpattern(solid))
        legend(order(2 "Point Estimate" 1 "`lev'% CI"))
        xtitle("Time")
		`graph_op';
        #delimit cr
    }
}
}


*-------------------------------------------------------------------------------
*--- (7) Return
*-------------------------------------------------------------------------------     
ereturn local cmdline `"`0'"'
ereturn local cmd "eventdd"
ereturn scalar level=`lev'
ereturn matrix lags  lags
ereturn matrix leads leads
ereturn matrix V_lags_leads vll

restore

end
