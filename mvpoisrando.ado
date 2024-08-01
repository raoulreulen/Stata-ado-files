program define mvpoisrando
    syntax, site(string) randomopt(string) [poisopt(string) temp(string) covars(string asis) decimals(integer 1) pdecimals(integer 2)]
    
    // Check if site is specified
    if "`site'" == "" {
        di as error "Error: A SPN tumour site must be specified in the site option."
        exit 198
    }

    // Check if random effect is specified
    if "`randomopt'" == "" {
        di as error "Error: Random effect must be specified in the randomopt option."
        exit 198
    }

    // Set default values if not provided
    if "`temp'" == "" {
        local temp "$temp"
    }
    if "`covars'" == "" {
        di as error "Error: At least one covariate must be specified in the covars option."
        exit 198
    }

    // Check if random effect is specified as a covariate
    foreach var of local randomopt {
        if strpos(" `covars' ", " `var' ") > 0 {
            di as error "Error: The random effect variable (`var') cannot be included as a covariate."
            exit 198
        }
    }

    // Check for required variables
    foreach var in _st _t _t0 _d {
        capture confirm variable `var'
        if _rc {
            di as error "Required variable `var' not found. Please ensure you have run stset before using this program."
            exit 198
        }
    }

    // Check for other required variables
    foreach var in rate_`site' {
        capture confirm variable `var'
        if _rc {
            di as error "Required variable `var' not found in the dataset."
            exit 198
        }
    }

    // Check for specified covariables
    foreach var of local covars {
        capture confirm variable `var'
        if _rc {
            di as error "Specified covariate `var' not found in the dataset."
            exit 198
        }
    }

    // Check if data is in memory
    quietly count
    if r(N) == 0 {
        di as error "No observations in memory. Please ensure your dataset is not empty."
        exit 2000
    }

    preserve
    
    // Create temporary variables
    tempvar E pyrs y
    gen double `E' = (_t - _t0)*rate_`site'
    gen double `pyrs' = (_t-_t0)
    gen double `y' = `pyrs'/10000
    
    //collapse data
    collapse (sum) _d `E' `y', by(`covars' `randomopt')

    *-----------------------------------------------------------------------------------------
    * LOOP OVER COLLAPSED VARIABLES 
    *-----------------------------------------------------------------------------------------
    local append replace
    foreach depvar of local covars { 

        *---------------------------------------------------------------------------
        * CREATE DUMMY VARIABLES FOR VARIABLE OF INTEREST
        *---------------------------------------------------------------------------
        local omit`depvar' : subinstr local covars "`depvar'" ""  //remove local
        
        local options exposure(`E') eform link(log) || `randomopt': ,family(poisson)
        
        // Multivariable model
        _eststo m1: meglm _d i.(`omit`depvar'') i.(`depvar')  if `E'!=0 , `options'
        
        //p-hetero
        _eststo m0: meglm _d i.(`omit`depvar'')               if `E'!=0 & !mi(`depvar'), `options'
        lrtest m0 m1
        estadd scalar p_het = r(p) : m1 //save p-value in scalar    

        //p-trend
        _eststo m2: meglm _d i.(`omit`depvar'') `depvar'      if `E'!=0 , `options'
        lrtest m2 m0
        estadd scalar p_trend = r(p) : m1 //save p-value in scalar   
        estimates drop m2 m0
		
        *---------------------------------------------------------------------------
        * DEFINE ESTOUT
        *---------------------------------------------------------------------------
        local estout estout m1                                                    ///
        using "$temp/x-mvpcsf-randomeffect_`site'.xls" ,                          ///                        
            cells("b(fmt(%9.`decimals'f)) & ci(par( ( - ) ) fmt(%9.`decimals'f))") eform  ///
            label collabels(, none) eqlabels(none) mlabel(, none)  labcol2(`depvar')      ///
            stats(p_trend p_het , fmt(%9.`pdecimals'f))                ///
            refcat(`depvar'_2  ,  label(1.0 (ref.))) substitute("0.0 (0.0-.)" "-")    
        
        *-------------------------------------------------------------------------------
        * ESTOUT
        *-------------------------------------------------------------------------------
        `estout' keep(*`depvar'*)  `append' 
        local append  append
        estimates clear
    }
    
    restore //restore to original dataset
end
