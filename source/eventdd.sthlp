{smcl}
{* *! version 1.0 20 Jan 2020}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "Install command2" "ssc install command2"}{...}
{vieweralsosee "Help command2 (if installed)" "help command2"}{...}
{viewerjumpto "Syntax" "eventDD##syntax"}{...}
{viewerjumpto "Description" "eventDD##description"}{...}
{viewerjumpto "Options" "eventDD##options"}{...}
{viewerjumpto "Remarks" "eventDD##remarks"}{...}
{viewerjumpto "Examples" "eventDD##examples"}{...}
{title:Title}
{phang}
{bf:eventDD} {hline 2} Event study plots in panel data

{marker syntax}{...}
{title:Syntax}
{p 8 17 2}
{cmdab:eventDD}
varlist(min=2
fv
ts
numeric)
[{help if}]
[{help in}]
[pw
fw
aw
iw]
[{cmd:,}
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt timevar(varname)}}  specifies the standardized time variable. Is required.

{pstd}
{p_end}
{synopt:{opt xtitle(passthru)}}  specifies the label for the time variable in plot. Is required.

{pstd}
{p_end}
{synopt:{opt baseline(#)}}  specifies the baseline period; default is -1.

{pstd}
{p_end}
{synopt:{opt accum}}  accumulate the periods in endpoints.

{pstd}
{p_end}
{synopt:{opt noend}}  no show the endpoints in plot. Only required when specifying the {cmd:accum} option.

{pstd}
{p_end}
{synopt:{opt keepbal(varname)}}  specifies the panel variable to keep only balanced units in the data.

{pstd}
{p_end}
{synopt:{opt lags(#)}}  specifies the number of lags to include. Only required when specifying the {cmd:accum} or {cmd:keepbal} options.

{pstd}
{p_end}
{synopt:{opt leads(#)}}  specifies the number of leads to include. Only required when specifying the {cmd:accum} option.

{pstd}
{p_end}
{synopt:{opt ols}}  use ordinary least-squares estimator; default.

{pstd}
{p_end}
{synopt:{opt fe}}  use fixed-effects estimator.

{pstd}
{p_end}
{synopt:{opt hdfe}}  generalization of fixed-effects estimator absorbing multiple levels of fixed effects. May not be combined with {cmd:wboot} option.

{pstd}
{p_end}
{synopt:{opt absorb(passthru)}}  categorical variables that identify the fixed effects to be absorbed. Only required when specifying the {cmd:hdfe} option.

{pstd}
{p_end}
{synopt:{opt wboot}}  specifies Wild Bootstrap standard errors. May not be combined with {cmd:hdfe} option.

{pstd}
{p_end}
{synopt:{opt seed(passthru)}}  initialize random number seed for Wild Bootstrap replication.

{pstd}
{p_end}
{synopt:{opt *}}  specifies any additional {help estimation options} and {help vce_option}, (ie robust or clustered sandwich estimator of variance).{p_end}
{synopt:{opt balanced}}  show only balanced periods in plot.

{pstd}
{p_end}
{synopt:{opt graph_op(string)}}  specifies any options in {help twoway_options}, (ie title, axis, labels).

{pstd}
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:eventDD} estimates the difference in a result between the treatment and control groups for the pre and post 
 treatment period and generates the event study plot in the panel data context. The data must include the standardized
 version of time variable with missing values for the control group.

{pstd}
 The command generates the estimation results and a graph with the estimated differences between the periods and the baseline 
 with their confidence intervals. By default, the command uses as baseline period -1 and estimates for ordinary least squares (OLS).

{pstd}
 {cmd:eventDD} is very useful to validity of the parallel trends assumption in the context of difference-in-differences (DD) estimator. 
 If it is the case that the reform is truly causing the effect, we should see that any differences between treatment and control groups 
 emerge only after the reform has been implemented, and that in all years prior to the reform, differences between both groups remain constant.

{pstd}

{marker options}{...}
{title:Options}
{dlgtab:Main}
{phang}
{opt timevar(varname)}  is required. The time variable specified must be standardized, where 0 corresponds to the first year of intervention and for the control unit(s) missing values are observed.

{pstd}
{p_end}
{phang}
{opt xtitle(passthru)}  is required. Specifies the title to appear next to the time axe (x-axe in graph). They also allow you to format the title fonts (see {help axis_title_options}).

{pstd}
{p_end}
{phang}
{opt baseline(#)}  specifies the reference period which the results of the rest of the periods are compared. Normally, it is some period before the intervention. The default is -1.

{pstd}
{p_end}
{phang}
{opt accum}  allows to accumulate the observations in the periods specified in {cmd: lags()} and  {cmd: leads()}, called endpoints.

{pstd}
{p_end}
{phang}
{opt noend}   allows not show the endpoints' estimations in the graph, when specified the {cmd:accum} option.

{pstd}
{p_end}
{phang}
{opt keepbal(varname)}  specifying the panel variable, allows to keep only the balanced units' observations for the estimation and graph.

{pstd}
{p_end}
{phang}
{opt lags(#)}  allows to specify the lower period to consider for the results, if specified {cmd:accum} or {cmd:keepbal} options.

{pstd}
{p_end}
{phang}
{opt leads(#)}  allows to specify the upper period to consider for the results, if specified {cmd:accum} or {cmd:keepbal} options.

{pstd}
{p_end}
{phang}
{opt ols}   the default estimator. It uses ordinary least-squares to estimation (see {help regress}). To control by individual fixed effects is necessary to include in the regression the panel dummies variables.

{pstd}
{p_end}
{phang}
{opt fe}  it uses fixed-effects (within) to estimation (see {help xtreg}, FE_options). With the fixed-effects estimator is not necessary to include the panel dummies variables.

{pstd}
{p_end}
{phang}
{opt hdfe}   it uses a linear regression absorbing multiple levels of fixed effects (see {help reghdfe}). May not be combined with {cmd:wboot} option

{pstd}
{p_end}
{phang}
{opt absorb(passthru)}  Only required when specifying the {cmd:hdfe} estimation option. Identifies the fixed effects to be absorbed; can be variable(s), categorical variables or factor variables (see {help reghdfe}).

{pstd}
{p_end}
{phang}
{opt wboot}  allows to use Wild Bootstrap standard errors to calculate the confidence intervals. May not be combined with {cmd:reghdfe} estimation option.

{pstd}
{p_end}
{phang}
{opt seed(passthru)}  sets the {help seed} for simulation based calculations when using a {cmd:wboot} option. Setting the seed allows for confidential inetrvals to be replicated.

{pstd}
{p_end}
{phang}
{opt *}  allows for the inclusion of any estimation option and variance estimators in {help estimation option} and {help vce_option}, respectively.

{pstd}
{p_end}
{phang}
{opt balanced}  allows to graph only the balanced periods, but considered all units and periods in the estimation.

{pstd}
{p_end}
{phang}
{opt graph_op(string)}  allows for the inclusion of any graphing option in {help twoway_options} , including {help title_options}, {help added_lines_options}, {help axis_label_options}, among others.

{pstd}
{p_end}


{marker examples}{...}
{title:Examples}
{pstd}

{pstd}
Load data that replicates Stevenson and Wolfers' (2006) analysis of no-fault divorce reforms and female suicide.

{pstd}
 • {stata webuse set www.pped.org}

{pstd}
 • {stata webuse bacon_example.dta}

{pstd}
Estimate a two-way fixed effect DD model of female suicide on no-fault divorce reforms.

{pstd}
 • {stata xtreg asmrs post pcinc asmrh cases i.year, fe cluster(stfips)}

{pstd}
Generate standarized event-time variable

{pstd}
 • {stata gen timeToTreat = year - _nfd}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms with all periods.

{pstd}
 • {stata eventDD asmrs i.year, fe timevar(timeToTreat) cluster(stfips) xtitle("Time") graph_op(ytitle("Suicides per 1m Women") xlabel(-20(5)25))}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms with all periods but only showing balanced periods in plot.

{pstd}
 • {stata eventDD asmrs pcinc asmrh cases i.year i.stfips, fe timevar(timeToTreat) cluster(stfips) xtitle("Time") balanced graph_op(ytitle("Suicides per 1m Women"))}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms only using balanced observations in the specified period.

{pstd}
 • {stata eventDD asmrs i.year, fe timevar(timeToTreat) cluster(stfips) xtitle("Time") lags(21) leads(27) keepbal(stfips) graph_op(ytitle("Suicides per 1m Women") xlabel(-20(5)25))}

{pstd}

{title:Stored results}

{synoptset 15 tabbed}{...}


{title:References}
{pstd}

{pstd}
Goodman-Bacon, Andrew. 2018.  "Differences-in-differences with variation
in treatment timing".  Working paper.

{pstd}
Stevenson, Betsey and Justin Wolfers. 2006. "Bargaining in the Shadow of
the Law: Divorce Laws and Family Distress". The Quarterly Journal of
Economics 121(1):267-288.


{title:Author}
{p}

Damian Clarke, Universidad de Santiago de Chile.

Email {browse "mailto:damian.clarke@usach.cl":damian.clarke@usach.cl}

Kathya Tapia, Universidad de Santiago de Chile.

Email {browse "mailto:kathya.tapia@usach.cl":kathya.tapia@usach.cl}



{title:See Also}
Related commands:

{help regress} 
{help xtset}
{help xtreg} 
{help reghdfe} (if installed)   {stata ssc install reghdfe} (to install this command)
{help bottest} (if installed)   {stata ssc install bottest} (to install this command)
{help twoway_options}
