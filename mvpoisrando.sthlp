{smcl}
{* *! version 1.0  <current_date>}{...}
{viewerjumpto "Syntax" "mvpoisrando##syntax"}{...}
{viewerjumpto "Description" "mvpoisrando##description"}{...}
{viewerjumpto "Options" "mvpoisrando##options"}{...}
{title:Title}

{phang}
{bf:mvpoisrando} {hline 2} Multivar Poisson Random Effects Analysis - for PCSF SPN cohort

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:mvpoisrando}, site(string) randomopt(string) [poisopt(string) temp(string) covars(string) decimals(integer 1) pdecimals(integer 2)]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt site(string)}}specify the SPN tumour site{p_end}
{synopt:{opt randomopt(string)}}specify the random effect variable{p_end}
{synopt:{opt poisopt(string)}}specify additional Poisson options{p_end}
{synopt:{opt temp(string)}}specify the temporary directory{p_end}
{synopt:{opt covars(string)}}specify covariates{p_end}
{synopt:{opt decimals(integer)}}specify number of decimal places for coefficients and CIs{p_end}
{synopt:{opt pdecimals(integer)}}specify number of decimal places for p-values{p_end}
{synoptline}
{p2colreset}{...}

{marker description}{...}
{title:Description}

{pstd}
{cmd:mvpoisrando} performs a multivariable Poisson random effects analysis.

{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt site(string)} specifies the SPN tumour site. This option is required.

{phang}
{opt randomopt(string)} specifies the random effect variable. This option is required.

{phang}
{opt poisopt(string)} specifies additional Poisson options.

{phang}
{opt temp(string)} specifies the temporary directory.

{phang}
{opt covars(string)} specifies covariates to be included in the analysis.

{phang}
{opt decimals(integer)} specifies the number of decimal places for coefficients and confidence intervals. Default is 1.

{phang}
{opt pdecimals(integer)} specifies the number of decimal places for p-values. Default is 2.
