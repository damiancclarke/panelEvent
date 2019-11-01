*! eventDD: Script for generating event study plot
*! Version 0.0.0 august 3, 2019 @ 22:54:54
*! Author: Damian Clarke & Kathya Tapia Schythe

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

*Sintaxis
#delimit ;
syntax varlist(min=2 fv ts numeric) [if] [in] [pweight fweight aweight iweight],
       timevar(varlist min=1 max=1) /*Standardized*/
       lags(integer) /*To Show*/
       leads(integer) /*To Show*/	   
  [
  baseline(integer -1) /*Elección periodo de referencia*/
  accum /*Acumular en los puntos finales lags+1 y leads+1*/
  ytitle(passthru)
  ylabel(passthru)
  mco fe hdfe /*tipo estimación FE, HDFE (defecto: MCVF)*/
  absorb(passthru)
  *balanced      /*usar sólo panel balanceado*/
  *wboot         /*errore wild bootstrap*/
  cluster(passthru) /*clusterizar errores*/
  *
  ];
#delimit cr

local wt [`weight' `exp']

preserve

rename `timevar' ptime
local tvar ptime

*Chequeamos sólo 1 opción de estimación
if ("`mco'"!="") + ("`fe'"!="") + ("`hdfe'"!="") >1 { 
    di as err "choose only one of {bf:mco}, {bf:fe}, or {bf:hdfe}"
    exit 198 
}

*Chequeamos baseline/lags/leads sean periodos disponibles 
qui sum `tvar'
local min  = r(min)
local max  = r(max)
if `baseline' < `min' | `baseline' > `max' { 
    di as err "{bf:baseline} not found"
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
		
*Chequeamos que el baseline esté dentro de los periodos de interés lags/leads (necesario?)
if `baseline' < -`lags' | `baseline' > `leads' { 
    di as err "{bf:baseline} is not between {bf:lags} and {bf:leads}"
    exit 198 
}


		
*Definición lags and leads
local lendpoint = `lags' +1 /*lower endpoint*/
local uendpoint = `leads'+1 /*upper endpoint*/
*Opción acumular en endpoints
if ("`accum'"=="accum")== 1{
    /*Acumulamos en endpoints -t1 y t2+ y asignamos -1 a los controles*/
    qui recode `tvar' (.=`baseline') (-1000/-`lendpoint'=-`lendpoint') (`uendpoint'/1000=`uendpoint')
    /*t=baseline es categoría de referencia*/
    qui char `tvar'[omit] `baseline'
    qui xi i.`tvar', pref(_lf)
    local time _lf*
}
else {
    /*t=baseline es categoría de referencia; pero no se acumula en endpoints*/
    qui recode `tvar' (.=`baseline') /*controles=-1?*/
    qui char `tvar'[omit] `baseline'
    qui xi i.`tvar', pref(_lf)
    local time _lf*
}


*Método Estimación
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
	
    dis as text " Note: with {bf:HDFE} option do not include in {bf:varlist} the categorical variables that identify the fixed effects to be absorbed in {bf:absorb()}"

    reghdfe `varlist' `time' `if' `in' `wt' , `absorb' `options'    
}

else if ("`fe'"=="fe") == 1 {
    dis as text "Note: with {bf:FE} option do not include in {bf:varlist} the categorical variables that identify the individual fixed effect" 
    
    *baseline -1 genera problemas, no es equivalente a estimación manual (que es igual a MCVF y HDFE)
    xtreg `varlist' `time' `if' `in' `wt' , fe `options' 
  
	
}
else {
    reg `varlist' `time' `if' `in' `wt' , `options' 
}

*Cálculo Intervalos 
qui sum `tvar'
*Locals para variables ficticias de periodos
local pre  = (-(r(min)-(`baseline')-1))-1 /*dummy periodo previo a baseline   */
local post = (-(r(min)-(`baseline')-1))+1 /*dummy periodo posterior a baseline*/
local tot  = r(max)-r(min)+1              /*dummy periodo final disponible    */
*Locals para variable de tiempo 
local min  = r(min)                       /*primer periodo disponible   */
local max  = r(max)                       /*último periodo disponible   */
local blpre  = `baseline'-1               /*periodo previo a baseline   */
local blpost = `baseline'+1               /*periodo posterior a baseline*/


foreach var in times point uCI lCI {
    tempvar `var'
    qui gen ``var''=.
}


if `baseline'==`min' {
local j = 1
foreach ld of numlist `blpost'(1)`tot' {
    qui replace `times'=`ld' in `j'
	local ++j
}
qui replace `times'=`baseline' in `j'


local i = 1
foreach t of numlist 2(1)`tot' {
    qui replace `point'=_b[_lfptime_`t'] in `i'
    qui replace `lCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.975)*_se[_lfptime_`t'] in `i'
    qui replace `uCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.025)*_se[_lfptime_`t'] in `i'
    local ++i
}
qui replace `point'=0 if `times'==`baseline'
qui replace `uCI'  =0 if `times'==`baseline'
qui replace `lCI'  =0 if `times'==`baseline'

}

else if `baseline'==`max' {
local j = 1
foreach ld of numlist `min'(1)`blpre' {
    qui replace `times'=`ld' in `j'
	local ++j
}
qui replace `times'=`baseline' in `j'


local i = 1
foreach t of numlist 1 (1)`pre' {
    qui replace `point'=_b[_lfptime_`t'] in `i'
    qui replace `lCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.975)*_se[_lfptime_`t'] in `i'
    qui replace `uCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.025)*_se[_lfptime_`t'] in `i'
    local ++i
}
qui replace `point'=0 if `times'==`baseline'
qui replace `uCI'  =0 if `times'==`baseline'
qui replace `lCI'  =0 if `times'==`baseline'

}

else {
local j = 1
foreach ld of numlist `min'(1)`blpre' `blpost'(1)`max' {
    qui replace `times'=`ld' in `j'
	local ++j
}
qui replace `times'=`baseline' in `j'


local i = 1
foreach t of numlist 1/`pre' `post'/`tot' {
    qui replace `point'=_b[_lfptime_`t'] in `i'
    qui replace `lCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.975)*_se[_lfptime_`t'] in `i'
    qui replace `uCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.025)*_se[_lfptime_`t'] in `i'
    local ++i
}
qui replace `point'=0 if `times'==`baseline'
qui replace `uCI'  =0 if `times'==`baseline'
qui replace `lCI'  =0 if `times'==`baseline'

}


sort `times'
*Gráfico
graph set eps fontface "Times New Roman"
set scheme s1mono
#delimit ;
twoway rarea `lCI' `uCI' `times' if inrange(`times', -`lags', `leads'),
       color(gs14%40) yline(0, lcolor(red))       
    || scatter `point' `times' if inrange(`times', -`lags', `leads'), 
	   ms(dh) mc(blue)	   
xline(`baseline', lcolor(black) lpattern(solid))
xlabel(-`lags'(1)`leads') legend(order(2 "Point Estimate" 1 "95% CI"))
`ytitle'`ylabel' xtitle("Time");
#delimit cr

restore

end
