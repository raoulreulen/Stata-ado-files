program define cumincattage
    version 18.0
	 st_is 2 analysis
  
 	// Check if stcompet is installed
    capture which stcompet
    if _rc {
        display as error "The stcompet command is required but not installed."
        exit 199
		}	 
   
    // Check if stexpect is installed
    capture which stexpect
    if _rc {
        display as error "The stexpect command is required but not installed."
        exit 199
		}
		  
    syntax [if] [in], site(string) [tstart(real 20) tend(real 60) yticks(real 1) ymax(real 10) xticks(real 5) scheme(string)]

    marksample touse

    local tstart = `tstart'
    local tend = `tend'
    local yticks = `yticks'
    local ymax = `ymax'
    local xticks = `xticks'
    local site `site'


    // STSCOMPET
    stcompet CumInc = ci hilim = hi lowlim = lo , compet1(2) 

    gen cispn   = CumInc*100    if _d==1
    gen cispnul = hilim*100     if _d==1 
    gen cispnll = lowlim*100    if _d==1

    keep _t cispn*

    // cuminc starts at zero:
    sort _t
    replace cispn   = 0 if _n==1 
    replace cispnul = 0 if _n==1
    replace cispnll = 0 if _n==1
    drop if cispn==.

    // Add last point on graph
    set obs `=_N+1'
    replace _t = `tend' if mi(_t) 
    sort _t cispn
    carryforward cispn, carryalong(cispnll cispnul) replace
	
/*	
	preserve
	
	// Expected Incidence
    use "$temp/x-cuminc-prep2-afterstsplit_`site'" , clear
    stexpect conditional if `touse', ratevar(rate_`site') ///
    out($temp/x-pcsf-expected`site', replace) method(2) at(`tstart'(1)`tend') 
	
	restore
*/	

    // Expected Incidence
    append using "$temp/x-pcsf-expected`site'" 
    gen expected = 100*(1- conditional)

    keep cispn* _t t_exp expected 
    sum cispnul if _t<=`tend'
    local maxinc = ceil(r(max))

    // Locals for text options in graph
    sum cispn if _t<=`tend'
    local ciat  = trim("`: display %10.1f r(max)'")

    sum expected if t_exp<=`tend'
    local ciexp = trim("`: display %10.1f r(max)'")
     
    local ciexpmin = `ciexp' 
    local ciatmin  = `ciat'  

    local ytimeplus =`tend'

    forvalues i = 40(10)60 {
        sum cispn if _t<=`i' 
        local ci`i' = trim("`: display %10.2f r(max)'")

        sum expected if t_exp<=`i'
        local exp`i' = trim("`: display %10.2f r(max)'")
    }

    // Graph
	
	if "`scheme'" == "" {
		local scheme = "stcolor"
		}
	
	
    twoway ///
        (line cispn* _t if (_t>=`tstart' & _t<=`tend'), sort connect(J J J) ///
            clp(solid dash dash) clw(medthick med med) clc(black gs7 gs7)) ///
        (lowess expected t_exp if (t_exp>=`tstart' & t_exp<=`tend'), ///
            sort bw(0.3) clp(l) clc(cyan) clw(med) clp(shortdash)) ///
        , ///
        scheme(`scheme') ///
		xlabel(`tstart'(`xticks')`tend') xtick(`tstart'(1)`tend') ///
        xtitle("attained age, years", size(small)) ///
        ylabel(0(`yticks')`ymax') ytick(0(1)`ymax') ///
        ytitle("Cumulative incidence, %", size(small)) ///
        legend(on) ///
        legend(order(1 "Observed" 2 "95%CI" 4 "Expected") ///
            pos(11) ring(0) size(vsmall) rowgap(0.1) cols(1)) ///
        text(`ciatmin' `ytimeplus' "`ciat'%" " ", place(n) color(black) size(vsmall)) ///
        saving("$temp/x-pcsf-`site'-byattage", replace)

    display "Graph saved as $temp/x-pcsf-`site'-byattage.gph"
end
