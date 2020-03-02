/*
 * ==========================================================================
 * Stata-Example.do
 * 
 * Distributed as an example of Alpha's Stata mode.
 * 
 * ==========================================================================
 */

/* 
 * ==========================================================================
 * Corporate Policies Analysis - Exploring 30 years of family benefits
 *
 * FILE: "cps-1-1.do"
 *                                          created: 10/11/1999 {10:39:52 pm}
 *                                      last update: 06/13/2000 {03:51:33 pm}
 * Description: 
 * 
 * Adjusting weights according to instructions in appendix Q This involves
 * eliminating some observations from the 1963 through 1975 data sets.  The
 * output file will indicate how many observations were dropped.
 * 
 * This creates and adds value labels for the variable "region" for data
 * sets mar65 through mar98.
 * 
 * At the end of this procedure, all of the cps marXX.dta files will be
 * deleted.  Best to have them backed up on a disk somewhere!
 * 
 * Author: Craig Barton Upright
 * E-mail: <cupright@alumni.princeton.edu>
 *    www: <http://www.purl.org/net/cbu>
 * 
 * Copyright (c) 1998-2000 Craig Barton Upright
 * All rights reserved.
 * 
 * ==========================================================================
 */


*** Preliminaries

#delimit ;

clear           ;
set more 1      ;
set memory 100m ;
set matsize 50  ;


*** Defining Macros ;

* Excerpt from Appendix Q:
* 
* It is important to note that the CPS files produced by the Census Bureau
* do not have decimal points in the data.  It is left to the documentation
* to inform the user how many decimals are implied.  The user must make the
* proper adjustment before using weights.  This is true for all the
* weights.  ;

* creating a little macro to recode, label, trim ;

program define macro1 ;

    /*  recoding weights */
    
    keep if wgt > 0 ;
    replace wgt = wgt * .01 ;
    
    /*  creating region variable */
    
    generate region = _state ;
    
    recode region
    
        01 = 01
        02 = 01
        03 = 02
        04 = 02
        05 = 02
        06 = 03
        07 = 03
        08 = 03
        09 = 03
        10 = 04
        11 = 05
        12 = 05
        13 = 05
        14 = 05
        15 = 06
        16 = 06
        17 = 07
        18 = 07
        19 = 08
        20 = 09
        21 = 09 ;
    
    label define cdcodes
    
        01 "01 New England           "
        02 "02 Middle Atlantic       "
        03 "03 East North Central    "
        04 "04 West North Central    "
        05 "05 South Atlantic        "
        06 "06 East South Central    "
        07 "07 West South Central    "
        08 "08 Mountain              "
        09 "09 Pacific               " ;
    
    label values region cdcodes ;
    
    label variable region "Census Bureau Division" ;
    
    /* selecting variables */
    
    keep  year wgt region _child18 sex occ ind2d ;
    
    end ;

    
* a second macro that calls "macro1" ;

program define macro2 ;

    clear ;

    ! echo "recoding state 19`1'"       ;
    ! uncompress ../data-temp/mar`1'*       ;

    use ../data-temp/mar`1'.dta             ;
    generate year = 19`1'                   ;
    macro1                                  ;
    quietly compress                        ;
    codebook                                ;
    save ../data-temp/cps`1'-1-1.dta        ;
    clear                                   ;

    ! compress ../data-temp/mar`1'.dta      ;
    ! compress ../data-temp/cps`1'-1-1.dta  ;
    
    end                                     ;
    

*** Recoding ;

! echo "recoding state for cps 65 - 69"  ;

macro2 65  ;
macro2 66  ;
macro2 67  ;
macro2 68  ;
macro2 69  ;

! echo "cps weights assigned" ;


* transforming variables in sppa-1-1.dta  ;

use ../data/sppa-1-1.dta  ;


*** Encoding missing values ;

! echo "encoding sppa missing values ..."  ;

mvdecode _all, mv(-9) ;
mvdecode _all, mv(-8) ;
mvdecode _all, mv(-7) ;
mvdecode _all, mv(-1) ;


*** Adding value labels ;

! echo "adding sppa value labels ..." ;

label   define  yearlab 

    0      " 0 1982                                 "    
    1      " 1 1992                                 "
    2      " 2 1997                                 " ;

label   define  gender          

    9      "-9 NOT ASCERTAINED                      "
    8      "-8 DON'T KNOW                           "
    7      "-7 REFUSED                              "
    2      "-2 INAPPLICABLE, SAMPLE SCREEN          "
    1      "-1 INAPPLICABLE, QUESTION SCREEN        "
    1      " 1 MALE                                 "
    2      " 2 FEMALE                               " ;

label   define  racelab  

    9      "-9 NOT ASCERTAINED                      "
    8      "-8 DON'T KNOW                           "
    7      "-7 REFUSED                              "
    2      "-2 INAPPLICABLE, SAMPLE SCREEN          "
    1      "-1 INAPPLICABLE, QUESTION SCREEN        "
    1      " 1 WHITE, BUT NOT OF HISPANIC ORIGIN    "
    2      " 2 BLACK, BUT NOT OF HISPANIC ORIGIN    "
    3      " 3 OTHER                                " ;



label   values  sppayear yearlab  ;
label   values  sex  gender   ;
label   values  race     racelab  ;


*** Quick regression ;

* model 1.1.1: linear regression of as04,
* respondents took arts courses outside of school ;

xi: regress as04
        i.sppayear i.race sex dadgrade i.cohort1b ;


* model 1.1.2: logistic regression of as04dum
* respondents took arts courses outside of school (dummy variable) ;

xi: logistic as04dum
        i.sppayear i.race sex dadgrade i.cohort1b ;
 

* model 1.1.3: linear regression of asfammus,
* parents of respondents listened classical music ;

xi: regress asfammus
        i.sppayear i.race sex dadgrade i.cohort1b ;



! echo "cps-1-1.do complete"  ; 


* at this point, we can assume that the procedure worked.
* to save disk space, the original marXX.dta will be deleted.
* (best to have them backed up on disk somewhere !!) ;

! rm -f ../data-temp/mar*.dta  ;


exit, STATA clear  ;

* .
