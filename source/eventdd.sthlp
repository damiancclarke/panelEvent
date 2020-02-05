{smcl}
{* *! version 1.0 20 Jan 2020}{...}
{vieweralsosee "" "--"}{...}
{viewerjumpto "Syntax" "eventDD##syntax"}{...}
{viewerjumpto "Description" "eventDD##description"}{...}
{viewerjumpto "Options" "eventDD##options"}{...}
{viewerjumpto "Remarks" "eventDD##remarks"}{...}
{viewerjumpto "Examples" "eventDD##examples"}{...}
{title:Title}
{phang}
{bf:eventDD} {hline 2} Estimate panel event study models and generate event study plots

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
[{help weight}]{cmd:,}
{it:timevar(varname)}
[
{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt timevar(varname)}}  Specifies the standardized time variable relative to the event of interest. This is required.
{p_end}
{synopt:{opt baseline(#)}}  Specifies the baseline period relative to the moment of the event of interest; the default is -1.
{p_end}
{synopt:{opt accum}}  Accumulates periods beyond indicated lags and leads into a final coefficient/confidence interval.
{p_end}
{synopt:{opt lags(#)}}  Specifies the number of lags which should be included. This is only required when specifying the {cmd:accum} or {cmd:keepbal} options, otherwise all possible lags will be plotted.
{p_end}
{synopt:{opt leads(#)}}  Specifies the number of leads which should be included. This is only required when specifying the {cmd:accum} or {cmd:keepbal} options, otherwise all possible lags will be plotted.
{p_end}
{synopt:{opt noend}}  Requests that end points are suppressed from graphs. This is only available if specifying the {cmd:accum} option.
{p_end}
{synopt:{opt keepbal(varname)}}  Indicates that only units which are balanced in the panel should be kept, where {it:varname} indicates the panel variable (eg state).
{p_end}
{synopt:{opt ols}}  Requests that the event study model should be estimated with Stata's {help regress} command.  This is the default.
{p_end}
{synopt:{opt fe}}  Requests that the event study model should be estimated with Stata's {help xtreg}, fe command.  The data must be {help xtset} if this option is used.
{p_end}
{synopt:{opt hdfe}}  Requests that the event study model should be estimated with the user-written {help reghdfe} command. 
{p_end}
{synopt:{opt absorb(varname)}}  Categorical variables that identify the fixed effects to be absorbed. Only required when specifying the {cmd:hdfe} option.
{p_end}
{synopt:{opt wboot}} Requests that standard errors be estimated by wild bootstrap. This requires the user-written {help boottest} command.  May not be combined with the {cmd:hdfe} option.
{p_end}
{synopt:{opt seed(#)}} Set random-number seed to #.
{p_end}
{synopt:{opt balanced}}  Requests that only balanced periods in which all units have data be shown in the plot.
{p_end}
{synopt:{opt graph_op(string)}}  specifies any options in {help twoway_options} which should be passed to the resulting event study graph, (eg title, axis, labels).
{p_end}
{synopt:{opt *}}  specifies any additional {help estimation options} and {help vce_option} which should be passed to the event study model, (ie robust or clustered sandwich estimator of variance).

{pstd}
{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}

{marker description}{...}
{title:Description}
{pstd}

{pstd}
 {cmd:eventDD} estimates a panel event study corresponding to a difference-in-difference style model where a
 series of lag and lead coefficients and confidence intervals are estimated and plotted.  These lag and lead
 coefficients are all relative to the passage of an event of interest, which can occur at different moments in
 different units of the panel.  The estimated model is of the general format:

{p 8 12 2}y_st = Alpha + {bind:Lag^K_st * BetaK} + ... + {bind:Lag^2_st * Beta2} + {bind:Lead^0_st * gamma0} + ... {bind:Lead^L_st * gammaL} + mu_s + lambda_t + u_st      (1)

{pstd}
 where {it: y_st} is an outcome of interest for state {it: s} and time {it: t}, and a series of K Leads and L Lags
 are considered relative to the event of interest.  Fixed effects for state and time are included as {mu_s} and
 {lambda_t} respectively. 
 

{pstd}
The command requires that the basic model be specified without lags and leads, and a variable should be indicated
in {opt: timevar()} which defines the standardized version of the time until the event, with missing values for
units in which the event never occurs (pure control units).
 The command generates the estimation results and a graph documenting the coefficients and confidence intervals on
 all indicated lags and leads.  By default, the command uses as a baseline time period -1 (one year prior to the event
 of interest) and estimates event study models using Stata's {help regress} command.

{pstd}
 {cmd:eventDD} provides a useful check of parallel {it: pre}-trends in the context of a difference-in-differences (DD)
 estimator.  Broader discussion of these models are provided in Angrist and Pischke (2009, section 5.2), Freyaldenhoven
 et al,. (2019), and Goodman-Bacon (2018) (among many other references).  Examples of use are given in the "Examples"
 section below.

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
 . {stata webuse set www.pped.org}

{pstd}
 . {stata webuse bacon_example.dta}

{pstd}
Estimate a two-way fixed effect DD model of female suicide on no-fault divorce reforms.

{pstd}
 . {stata xtreg asmrs post pcinc asmrh cases i.year, fe cluster(stfips)}

{pstd}
Generate standarized event-time variable

{pstd}
 . {stata gen timeToTreat = year - _nfd}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms with all periods.

{pstd}
 . {stata eventDD asmrs i.year, fe timevar(timeToTreat) cluster(stfips) xtitle("Time") graph_op(ytitle("Suicides per 1m Women") xlabel(-20(5)25))}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms with all periods but only showing balanced periods in plot.

{pstd}
 . {stata eventDD asmrs pcinc asmrh cases i.year i.stfips, fe timevar(timeToTreat) cluster(stfips) xtitle("Time") balanced graph_op(ytitle("Suicides per 1m Women"))}

{pstd}
Generate the event study plot associated to DD model of female suicide on no-fault divorce reforms only using balanced observations in the specified period.

{pstd}
 . {stata eventDD asmrs i.year, fe timevar(timeToTreat) cluster(stfips) xtitle("Time") lags(21) leads(27) keepbal(stfips) graph_op(ytitle("Suicides per 1m Women") xlabel(-20(5)25))}

{pstd}

{title:Stored results}

{synoptset 15 tabbed}{...}


{title:References}
{pstd}

{pstd}
Angrist, Joshua and Jörn-Steffen Pischke. 2009. "Mostly Harmless Econometrics: An Empiricist's Companion".
Princeton University Press.

{pstd}
Freyaldenhoven, Simon, Christian Hansen, and Jesse M. Shapiro. 2019. "Pre-event Trends in 
the Panel Event-Study Design". American Economic Review 109(9):3307-38.

{pstd}
Goodman-Bacon, Andrew. 2018. "Difference-in-Differences with Variation in Treatment Timing".
National Bureau of Economic Research Working Paper 25018.

{pstd}
Stevenson, Betsey and Justin Wolfers. 2006. "Bargaining in the Shadow of
the Law: Divorce Laws and Family Distress". The Quarterly Journal of
Economics 121(1):267-288.


{title:Author}
{p}

Damian Clarke, Universidad de Santiago de Chile.
Email {browse "mailto:damian.clarke@protonmail.com":damian.clarke@protonmail.com}

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
