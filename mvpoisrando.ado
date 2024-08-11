capture program drop mvpoisrando
program define mvpoisrando
    version 18.0
    st_is 2 analysis
    
    syntax varlist(min=1), site(string) RANDOmopt(string) [poisopt(string) temp(string) DECimals(integer 1) PDECimals(integer 2) output(string)]
    
    // Check if site is specified
    if "`site'" == "" {
        error 198
        di as error "A SPN tumour site must be specified in the site option."
    }

    // Check if random effect is specified
    if "`randomopt'" == "" {
        error 198
        di as error "Random effect must be specified in the randomopt option."
    }

    // Set default values if not provided
    if "`temp'" == "" {
        local temp "$temp"
    }
    
    // Set output file path
    if "`output'" == "" {
        local outputfile "`temp'/x-mvpcsf-randomeffect_`site'.xls"
    }
    else {
        local outputfile "`output'"
    }

    // Check if random effect is specified as a covariate
    foreach var of local randomopt {
        if strpos(" `varlist' ", " `var' ") > 0 {
            error 198
            di as error "The random effect variable (`var') cannot be included in the varlist."
        }
    }

    // Check for required variables
    foreach var in _st _t _t0 _d {
        capture confirm variable `var'
        if _rc {
            error 198
            di as error "Required variable `var' not found. Please ensure you have run stset before using this program."
        }
    }

    // Check for other required variables
    foreach var in rate_`site' {
        capture confirm variable `var'
        if _rc {
            error 198
            di as error "Required variable `var' not found in the dataset."
        }
    }

    // Check if data is in memory
    quietly count
    if r(N) == 0 {
        error 2000
        di as error "No observations in memory. Please ensure your dataset is not empty."
    }

    preserve
    
    // Create temporary variables
    tempvar E pyrs y
    gen double `E' = (_t - _t0)*rate_`site'
    gen double `pyrs' = (_t-_t0)
    gen double `y' = `pyrs'/10000
    
    //collapse data
    collapse (sum) _d `E' `y', by(`varlist' `randomopt')
	
    *-------------------------------------------------------------------------------------
    * CHECK FOR OVERDISPERSION
    *-------------------------------------------------------------------------------------	
	local options exposure(`E') eform link(log) || `randomopt': 
	
	//run Poisson model first 
	meglm _d i.(`varlist')  if `E'!=0 , `options', family(poisson)
	scalar lrpois =  e(ll)
	
	// Fit negative binomial model
    meglm _d i.(`varlist')  if `E'!=0 , `options', family(nbinomial)
	scalar lrnbreg =  e(ll)
	
	scalar lr = -2*(lrpois-lrnbreg) 
	di chiprob(1,lr)/2		
	cap: assert (chiprob(1,lr)/2) < 0.05 //if true, then NB
	 
	if !_rc {
		di "NEGATIVE BINOMIAL"
		local family nbinomial 
		}

	else {
		di "POISSON"
		local family poisson
		}


    *-------------------------------------------------------------------------------------
    * LOOP OVER COLLAPSED VARIABLES 
    *-------------------------------------------------------------------------------------
    local append replace
	local i = 0
    foreach depvar of local varlist { 

        *---------------------------------------------------------------------------
        * MODELS
        *---------------------------------------------------------------------------
        local omit`depvar' : subinstr local varlist "`depvar'" ""  //remove local
          
        // Multivariable model
        _eststo m1: meglm _d i.(`omit`depvar'') i.(`depvar')  if `E'!=0 , `options' , family(`family')
        
        //p-hetero
        _eststo m0: meglm _d i.(`omit`depvar'')               if `E'!=0 & !mi(`depvar'), `options' , family(`family')
        lrtest m0 m1
        estadd scalar p_het = r(p) : m1 //save p-value in scalar    

        //p-trend
        _eststo m2: meglm _d i.(`omit`depvar'') `depvar'      if `E'!=0 , `options' , family(`family')
        lrtest m2 m0
        estadd scalar p_trend = r(p) : m1 //save p-value in scalar   
        estimates drop m2 m0
        
        *---------------------------------------------------------------------------
        * DEFINE ESTOUT
        *---------------------------------------------------------------------------
        local estout estout m1                                                    ///
        using "`outputfile'" ,                                                    ///                        
            cells("b(fmt(%9.`decimals'f)) & ci(par( ( - ) ) fmt(%9.`decimals'f))") eform  ///
            label collabels(, none) eqlabels(none) mlabel(, none)  labcol2(`depvar')      ///
            stats(p_trend p_het , fmt(%9.`pdecimals'f))                ///
            refcat(`depvar'_2  ,  label(1.0 (ref.))) substitute("0.0 (0.0-.)" "-")   ///
			
        
        *-------------------------------------------------------------------------------
        * ESTOUT
        *-------------------------------------------------------------------------------
        if `i'==0 `estout' keep(*`depvar'*) title(`family')  replace
		if `i'>0 `estout' keep(*`depvar'*)  append
		local i =1
        estimates clear
    }
    
    di as text "Results saved to: `outputfile'"
    restore //restore to original dataset
end













