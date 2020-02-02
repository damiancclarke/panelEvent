*! eventDD: Estimate panel event study models and generate plots
*! Version 1.0.0 february 2, 2020 @ 11:06:20
*! Author: Damian Clarke & Kathya Tapia Schythe

cap program drop eventDD
program eventDD, eclass
vers 11.0

*-------------------------------------------------------------------------------
*--- (1) Syntax definition and set-up
*-------------------------------------------------------------------------------    
#delimit ;
syntax varlist(min=2 fv ts numeric) [if] [in] [pweight fweight aweight iweight],
xtitle(passthru) timevar(varlist min=1 max=1) /*Standardized*/
  [
  baseline(integer -1)          /*Reference period*/
  accum                         /*Accumulate time in final lags and leads*/
  noend                         /*Don't plot end points with accum*/
  keepbal(varlist min=1 max=1)  /*Use only units which are balanced in all lags and leads*/  
  lags(integer 0)               /*Number of lags to display with accum*/
  leads(integer 0)              /*Number of leads to display with accum*/
  mco fe hdfe                   /*Type of fixed effect estimation: FE, HDFE (default: MCVF)*/
  absorb(passthru)              /*Only to be used where hdfe is specified*/
  balanced                      /*Use only a balanced panel in all lags and leads selected*/
  wboot                         /*Wild bootstrap standard errors*/
  seed(passthru)	            /*Sets seed for replicating wild bootstrap SEs.*/
  graph_op(string)              /*Graph options*/
  *
  ];
#delimit cr

local wt [`weight' `exp']

preserve

rename `timevar' ptime
local tvar ptime

*-------------------------------------------------------------------------------
*--- (2) General syntax consistency check
*-------------------------------------------------------------------------------    
*Ensure only 1 estimation option specified
if ("`mco'"!="") + ("`fe'"!="") + ("`hdfe'"!="") >1 { 
    di as err "choose only one of {bf:mco}, {bf:fe}, or {bf:hdfe}"
    exit 198 
}

*Ensure that hdfe is not combined with wboot
if ("`hdfe'"!="") + ("`wboot'"!="")  >1 { 
    local soln "please respecify your model to use regress or xtreg, fe."
    di as err "{bf:hdfe} may not be combined with {bf:wboot}."
    di as err "If you wish to estimate wild bootstrapped standard errors, `soln'."
    exit 198 
}

*Ensure accum and balanced are not combined
if ("`accum'"!="") + ("`balanced'"!="")  >1 { 
    di as err "{bf:accum} may not be combined with {bf:balanced}"
    exit 198 
}
		
*Chequeamos indicación noend sólo con accum
if ("`accum'"=="") + ("`end'"!="")  >1 { 
    di as err "option {bf:noend} requires {bf:accum}"
    exit 198 
}

*Chequeamos sólo 1 opción: keepbal o accum
if ("`accum'"=="accum") + ("`keepbal'"!="")  >1 { 
    di as err "choose only one of {bf:accum} or {bf:keepbal}" 
    exit 198 
}
		
*Chequeamos baseline sea periodo disponible
qui sum `tvar'
local min  = r(min)
local max  = r(max)
if `baseline' < `min' | `baseline' > `max' { 
    di as err "{bf:baseline} not found"
    exit 198 
}
		
*Opción accum con lags/leads
*Chequeamos indicación de lags/leads sólo con accum o keepbal
if ("`lags'" != "0" ) & ("`accum'" == "" ) & ("`keepbal'" == "")  ==1{
    di as err "options {bf:lags()} and {bf:leads()} require {bf:accum} or {bf:keepbal}"
    exit 198
}
if ("`leads'" != "0" ) & ("`accum'" == "" ) & ("`keepbal'" == "") ==1{
    di as err "options {bf:lags()} and {bf:leads()} require {bf:accum} or {bf:keepbal}"
    exit 198
}
	
if ("`accum'" == "accum" ) + ("`keepbal'" != "") ==1{
*Chequeamos indiquen lags/leads cuando indican accum o keepbal
if ("`lags'" == "0" ) ==  1{
    di as err "options {bf:lags()} and {bf:leads()} required"
    exit 198
}
if ("`leads'" == "0" ) == 1{
    di as err "options {bf:lags()} and {bf:leads()} required"
    exit 198
}
*Chequeamos que lags/leads sean periodos disponibles
if  `min' > -`lags' { 
    di as err "{bf:lags} not found"
    exit 198 
}
if `max' < `leads' { 
    di as err "{bf:leads} not found"
    exit 198 
}
*Chequeamos que el baseline esté dentro de los periodos de interés lags/leads
if `baseline' < -`lags' | `baseline' > `leads' { 
    di as err "{bf:baseline} is not between {bf:lags} and {bf:leads}"
    exit 198 
}
}

*-------------------------------------------------------------------------------
*--- (3) Define lags and leads
*-------------------------------------------------------------------------------    
*Definición lags and leads
*Opción acumular en endpoints
if ("`keepbal'"!="")== 1 {
    local tbal=`lags'+`leads'+1
    qui tab `tvar' if `tvar'>=-`lags' & `tvar'<=`leads', gen(tbal)
    qui egen rbal=rowtotal(tbal*)
    qui bysort `keepbal': egen bal=total(rbal) if rbal!=0
    qui count if bal==`tbal'
    local un=r(N)
    if `un'==0{
        di as err "no unit meets the criteria"
	exit 
    }
    else {
        qui keep if bal==`tbal' | `tvar'==.
    }
    /*Asignamos baseline a los controles*/
    qui recode `tvar' (.=`baseline')
    /*t=baseline es categoría de referencia*/
    qui char `tvar'[omit] `baseline'
    qui xi i.`tvar', pref(_lf)
    local time _lf*
}
else if ("`accum'"=="accum")== 1 {
    /*Acumulamos en endpoints -t1 y t2+ y asignamos baseline a los controles*/
    qui recode `tvar' (.=`baseline') (-1000/-`lags'=-`lags') (`leads'/1000=`leads')
    /*t=baseline es categoría de referencia*/
    qui char `tvar'[omit] `baseline'
    qui xi i.`tvar', pref(_lf)
    local time _lf*
}
else {
    /*t=baseline es categoría de referencia; pero no se acumula en endpoints, se usan todos los periodos*/
    qui recode `tvar' (.=`baseline') /*controles=-1*/
    qui char `tvar'[omit] `baseline'
    qui xi i.`tvar', pref(_lf)
    local time _lf*
}


*-------------------------------------------------------------------------------
*--- (4) Estimate models
*-------------------------------------------------------------------------------    
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
	
	dis as err " Note: with {bf:HDFE} option do not include in {bf:varlist} the categorical variables that identify the fixed effects to be absorbed in {bf:absorb()}"

    reghdfe `varlist' `time' `if' `in' `wt' , `absorb' `options' 

}

else if ("`fe'"=="fe") == 1{

	dis as err "Note: with {bf:FE} option do not include in {bf:varlist} the categorical variables that identify the individual fixed effect" 
    
   *baseline -1 genera problemas, no es equivalente a estimación manual (que es igual a MCVF y HDFE)
	xtreg `varlist' `time' `if' `in' `wt' , fe `options' 
  
	
}
	
else {

    reg `varlist' `time' `if' `in' `wt' , `options' 
}

*-------------------------------------------------------------------------------
*--- (5) Calculate confidence intervals
*-------------------------------------------------------------------------------    
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
if ("`wboot'"=="wboot") == 1{
foreach t of numlist 2(1)`tot'{
    qui replace `point'=_b[_lfptime_`t'] in `i'
	
    cap qui boottest _lfptime_`t', nograph `seed'
    cap mat ci_`t'= r(CI)
    cap qui replace `lCI'  = ci_`t'[1,1] in `i'
    cap qui replace `uCI'  = ci_`t'[1,2] in `i'
    local ++i
}
}

else {
foreach t of numlist 2(1)`tot' {
    qui replace `point'=_b[_lfptime_`t'] in `i'
    qui replace `lCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.975)*_se[_lfptime_`t'] in `i'
    qui replace `uCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.025)*_se[_lfptime_`t'] in `i'
    local ++i
}
}

qui replace `point'=0 if `times'==`baseline'
qui replace `uCI'  =0 if `times'==`baseline'
qui replace `lCI'  =0 if `times'==`baseline'

qui replace `uCI'  =0 if `times'!=. & `uCI'==.
qui replace `lCI'  =0 if `times'!=. & `lCI'==.

}

else if `baseline'==`max' {
local j = 1
foreach ld of numlist `min'(1)`blpre' {
    qui replace `times'=`ld' in `j'
	local ++j
}
qui replace `times'=`baseline' in `j'


local i = 1
if ("`wboot'"=="wboot") == 1{
foreach t of numlist 1 (1)`pre'{
    qui replace `point'=_b[_lfptime_`t'] in `i'
	
    cap qui boottest _lfptime_`t', nograph `seed'
    cap mat ci_`t'= r(CI)
    cap qui replace `lCI'  = ci_`t'[1,1] in `i'
    cap qui replace `uCI'  = ci_`t'[1,2] in `i'
    local ++i
}
}

else {
foreach t of numlist 1 (1)`pre' {
    qui replace `point'=_b[_lfptime_`t'] in `i'
    qui replace `lCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.975)*_se[_lfptime_`t'] in `i'
    qui replace `uCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.025)*_se[_lfptime_`t'] in `i'
    local ++i
}
}

qui replace `point'=0 if `times'==`baseline'
qui replace `uCI'  =0 if `times'==`baseline'
qui replace `lCI'  =0 if `times'==`baseline'

qui replace `uCI'  =0 if `times'!=. & `uCI'==.
qui replace `lCI'  =0 if `times'!=. & `lCI'==.

}

else {
local j = 1
foreach ld of numlist `min'(1)`blpre' `blpost'(1)`max' {
    qui replace `times'=`ld' in `j'
	local ++j
}
qui replace `times'=`baseline' in `j'

local i = 1
if ("`wboot'"=="wboot") == 1{
foreach t of numlist 1/`pre' `post'/`tot' {
    qui replace `point'=_b[_lfptime_`t'] in `i'
	
	cap qui boottest _lfptime_`t', nograph `seed'
    cap mat ci_`t'= r(CI)
    cap qui replace `lCI'  = ci_`t'[1,1] in `i'
    cap qui replace `uCI'  = ci_`t'[1,2] in `i'
    local ++i
}
}

else {
foreach t of numlist 1/`pre' `post'/`tot' {
    qui replace `point'=_b[_lfptime_`t'] in `i'
    qui replace `lCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.975)*_se[_lfptime_`t'] in `i'
    qui replace `uCI'  =_b[_lfptime_`t']+invttail(e(df_r),0.025)*_se[_lfptime_`t'] in `i'
    local ++i
}
}

qui replace `point'=0 if `times'==`baseline'
qui replace `uCI'  =0 if `times'==`baseline'
qui replace `lCI'  =0 if `times'==`baseline'

qui replace `uCI'  =0 if `times'!=. & `uCI'==.
qui replace `lCI'  =0 if `times'!=. & `lCI'==.

}

*-------------------------------------------------------------------------------
*--- (6) Plot graphs
*-------------------------------------------------------------------------------    
sort `times'

*Opción graficar sólo periodos balanceados entre los lags/leads elegidos
if ("`balanced'"=="balanced") == 1{
foreach var in obs {
    tempvar `var'
    qui gen ``var''=.
}
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
local max2=el(x,2,1) /*guardamos 2° mayor, si hay controles y reemplazamos sus periodos estandarizados por -1, entonces -1 es el observados más frecuente*/
qui tab `times' if `obs'>=`max2'
local bal=r(r)

#delimit ;
twoway rarea `lCI' `uCI' `times' if `obs'>=`max2',
       color(gs14%40) yline(0, lcolor(red))       
    || scatter `point' `times'   if `obs'>=`max2', 
	   ms(dh) mc(blue)	   
xline(`baseline', lcolor(black) lpattern(solid))
legend(order(2 "Point Estimate" 1 "95% CI"))
`xtitle' `graph_op';
#delimit cr
}

else if ("`accum'"=="accum") == 1{

if ("`end'"=="noend") == 1{
local lpoint = `lags' -1 /*lower point*/
local upoint = `leads'-1 /*upper point*/
graph set eps fontface "Times New Roman"
set scheme s1mono
#delimit ;
twoway rarea `lCI' `uCI' `times' if inrange(`times', -`lpoint', `upoint'),
       color(gs14%40) yline(0, lcolor(red))       
    || scatter `point' `times' if inrange(`times', -`lpoint', `upoint'), 
	   ms(dh) mc(blue)
xline(`baseline', lcolor(black) lpattern(solid))
legend(order(2 "Point Estimate" 1 "95% CI"))
`xtitle' `graph_op';
#delimit cr
}

else{
graph set eps fontface "Times New Roman"
set scheme s1mono
#delimit ;
twoway rarea `lCI' `uCI' `times',
       color(gs14%40) yline(0, lcolor(red))       
    || scatter `point' `times', 
	   ms(dh) mc(blue)
	|| scatter `point' `times' if `times'==-`lags' | `times'==`leads', 
	   ms(D) mc(blue)
xline(`baseline', lcolor(black) lpattern(solid))
legend(order(2 "Point Estimate" 1 "95% CI"))
`xtitle' `graph_op';
#delimit cr
}
}

else if ("`keepbal'"!="") == 1{
graph set eps fontface "Times New Roman"
set scheme s1mono
#delimit ;
twoway rarea `lCI' `uCI' `times',
       color(gs14%40) yline(0, lcolor(red))       
    || scatter `point' `times', 
	   ms(dh) mc(blue)
xline(`baseline', lcolor(black) lpattern(solid))
legend(order(2 "Point Estimate" 1 "95% CI"))
`xtitle' `graph_op';
#delimit cr
}

else{
graph set eps fontface "Times New Roman"
set scheme s1mono
#delimit ;
twoway rarea `lCI' `uCI' `times' if inrange(`times', `min', `max'),
       color(gs14%40) yline(0, lcolor(red))       
    || scatter `point' `times' if inrange(`times', `min', `max'), 
	   ms(dh) mc(blue)	   
xline(`baseline', lcolor(black) lpattern(solid))
legend(order(2 "Point Estimate" 1 "95% CI"))
`xtitle' `graph_op';
#delimit cr
}

restore

end
