/* -*-SAS-*- 
 * ==========================================================================
 * SAS-Example.sas
 * 
 * Distributed as an example of Alpha's SAS mode.
 * 
 * ==========================================================================
 */

/* 
 * ==========================================================================
 * SPPA Analysis - Exploring 15 year trends in Participation in the Arts
 * 
 * FILE: "sppa1982.sas"
 *                                          created: 11/14/1998 {02:34:21 pm}
 *                                      last update: 05/29/2000 {06:38:55 pm}
 * Description: 
 *
 * Reading data from the CD-ROM "SPPA" -- National Endowment of the Arts. 
 * A revision of Steven Tepper's tap82.sas
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

*** Preliminaries ;

options ls = 80 ;
LIBNAME mysas v609 "." ; 
FILENAME IN1 "../SPPA_82_97/82_85_92/SPPA1982" ;


*** Value labels ;

PROC FORMAT ;

VALUE   urbrural

    1       =  " 1 Urban                                " 
    2       =  " 2 Rural - Farm, 10 acres or larger     "
    3       =  " 3 Rural - Farm, less than 10 acres     "
    4       =  " 4 Rural - Non-Farm,10 acres or larger  "
    5       =  " 5 Rural - Non-Farm, less than 10 acres " ;

VALUE   metrange

    00      =  "00  under 200                           "
    01      =  "01       200 -     499                  "
    02      =  "02       500 -     999                  "
    03      =  "03     1,000 -   1,499                  "
    04      =  "04     1,500 -   1,999                  "
    05      =  "05     2,000 -   2,499                  "
    06      =  "06     2,500 -   4,999                  "
    07      =  "07     5,000 -   9,999                  "
    08      =  "08    10,000 -  19,999                  "
    09      =  "09    20,000 -  24,999                  "
    10      =  "10    25,000 -  49,999                  "
    11      =  "11    50,000 -  99,999                  "
    12      =  "12   100,000 - 240,999                  "
    13      =  "13   250,000 - 499,999                  "
    14      =  "14   500,000 - 999,999                  "
    15      =  "15 1,000,000 or more                    "
    99      =  "99 missing value                        " ;

 
VALUE   msa

    1       =  " 1 Central city of an SMSA only         "
    2       =  " 2 Central city of an urbnized area only"
    3       =  " 3 Central city of both SMSA, urbanized "
    4       =  " 4 Other incorporated place             "
    5       =  " 5 Unincorporated place                 "
    7       =  " 7 Not a place                          " ;
    
VALUE   quartype

    01      =  "01 House, apartment, flat               "
    02      =  "02 Housing unit in nontrnsient hotel etc"
    03      =  "03 Housing unit, permanent in transient "
    04      =  "04 Housing unit in rooming house        "
    05      =  "05 Mobile home or trailer               " 
    06      =  "06 Housing unit not specified above     "
    07      =  "07 Quarters in rooming/boarding house   "
    08      =  "08 Unit not perm in transient hotel     "
    09      =  "09 Unoccupied site for mobile home, etc "
    10      =  "10 Other unit not specified above       " ;
    
VALUE   number
        
     98     = " 98 residue                              "
     99     =  "99 missing value                        "
    998     = "998 residue                              "
    999     = "999 missing value                        " ;

VALUE   phyesno

    1       =  " 1 Phone in unit - phone intrvw accp    "
    2       =  " 2 Phone in unit - phone intrvw unaccp  "
    3       =  " 3 Phone elsewhere - phone intrvw accp  "
    4       =  " 4 Phone elsewhere - phone intrvw unaccp"
    5       =  " 5 No phone                             "
    8       =  " 5 residue                              "
    9       =  " 9 missing value                        " ;
    
VALUE   incrange

    03      =  "03 Less than  $3,000                    "
    05      =  "05 $ 3,000 to  4,999                    "
    06      =  "06 $ 5,000 to  5,999                    "
    07      =  "07 $ 6,000 to  7,499                    "
    08      =  "08 $ 7,500 to  9,999                    "
    09      =  "06 $10,000 to 11,999                    "
    10      =  "10 $12,000 to 14,999                    "
    11      =  "11 $15,000 to 19,999                    "
    12      =  "12 $20,000 to 24,999                    "
    13      =  "13 $25,000 to 49,999                    " 
    14      =  "11 $50,000 and over                     "
    98      =  "98 residue                              "
    99      =  "99 missing value                        " ;
    
    
VALUE   monthnm

    01      =  "01 January                              "
    02      =  "02 February                             "
    03      =  "03 March                                "
    04      =  "04 April                                "
    05      =  "05 May                                  "
    06      =  "06 June                                 "
    07      =  "07 July                                 "
    08      =  "08 August                               "
    09      =  "09 September                            "
    10      =  "10 Ocober                               "
    11      =  "11 November                             "
    12      =  "12 December                             " ;

VALUE   relation

    1       =  " 1 Reference person                     "
    2       =  " 2 Spouse                               "
    3       =  " 3 Own child                            "
    4       =  " 4 Other relative                       " 
    5       =  " 5 Non-relative                         "
    9       =  " 9 missing value                        " ;
    
VALUE   status

    1       =  " 1 Married                              "
    2       =  " 2 Widowed                              "
    3       =  " 3 Divorced                             "
    4       =  " 4 Separated                            "
    5       =  " 5 Never married                        "
    8       =  " 8 residue                              "
    9       =  " 9 missing value                        " ;
    
VALUE   rrace

    1       =  " 1 White                                "
    2       =  " 2 Black                                "
    3       =  " 3 Other                                " 
    9       =  " 9 missing value                        " ;
    
VALUE   mf

    1       =  " 1 Male                                 "
    2       =  " 2 Female                               "
    9       =  " 9 missing value                        " ;
    
VALUE   noyes

    0       =  " 0 No                                   "
    1       =  " 1 Yes                                  "
    8       =  " 8 residue                              "
    9       =  " 9 missing value                        " ;

VALUE   catnoyes

    0       =  " 0 No entry for this category           "
    1       =  " 1 Entry for this category              "
    8       =  " 8 NA, all categories are blank         "
    9       =  " 9 missing value                        " ;
    
RUN ;


*** Input data ;

DATA mysas.sppa1982 ;
INFILE IN1 LRECL=660 MISSOVER ;

INPUT

    /*       Characters 1 - 120 are the household section  */

    @1       sample          2.
    @3       psunumbr        3.
    @6       segnumbr        4.
    @10      checkdig        1.
    @11      sernumbr        2.
    @13      blank1          1.
    @14      hhnumbr         1.
    @15      Landuse         1.
    @16      Metsize         2.
    @18      Msatype         1.
    @19      blank2          3.
    @22      blank3          1.
    @23      hhrsnumb        2.
    @25      noninttp        1.
    @26      nonintrc        1.
    @27      nonintrs        2.
    @29      blank4          9.
    @38      hhstatus        1.
    @39      spcplace        2.
    @41      tenure          1.
    @42      blank5          1.
    @43      Lvquart         2.
    @45      blank6          1.
    @46      hhbusnss        1.
    @47      hsgunits        2.
    @49      crimrprt        2.
    
    /*       Characters 124 - 171 are the person section */
    
    @124     Refrltn         1.
    @125     Age             2.
    @127     MARSTAT         1.
    @128     RACE            1.
    @129     SEX             1.
    @130     afmemb          1.
    @131     GRADE           2.
    @133     Gradecom        1.
    @134     blank12         2.
    @136     WORKWK          2.
    @138     inttype2        1.
    @139     blank13         5.
    @144     layoff          1.
    @145     blank14         1.
    @146     nojobrsn        1.
    @147     forwhom         1.
    @148     iccode          3.
    @151     emptype         1.
    @152     occcode         3.
    @155     blank15        11.
    @166     Workwkhr        3.
    @169     Ethncity        2.
    @171     workwk2         1.
    @172     blank16         9.
    
    /*       Characters 181 - 660 are the SPPA section */
    
    @181     blank17        18.
    @199     lashhwt        12.
    @211     laspnwt        12.
    @223     hfsampcd       16.
    @239     blank18         3.
    @242     version         1.
    @243     blank19        17.
    @260     Intvtype        1.
    @261     Chszlt06        1.
    @262     Chsz0611        1.
    @263     blank20         3.
    @266     LPJAZZMO        1.
    @267     LPCLASMO        1.
    @268     LPOPERMO        1.
    @269     LPMUSIMO        1.
    @270     LPPLAYMO        1.
    @271     LPBALLMO        1.
    @272     LPGALLMO        1.
    @273     PPMUSWEL        1.
    @274     PPCLAPLA        1.
    @275     PPJAZPLA        1.
    @276     ppanypub        1.
    @277     PPPLAPUB        1.
    @278     PPMUSPUB        1.
    @279     PPOPRSNG        1.
    @280     PPBALLET        1.
    @281     LPREAD          1.
    @282     blank21         3.
    @285     unclear1        1.
    
    /*   I consider questions in characters 286 thu 292 to be   */
    /*   unreliable.  response rates of 100 or less.   -cbu     */
    
    @286     lpjazzXX        1.
    @287     lpclasXX        1.
    @288     lpoperXX        1.
    @289     lpmusiXX        1.
    @290     lpplayXX        1.
    @291     lpballXX        1.
    @292     lpgallXX        1.
    @293     blank22         1.
    @294     unclear2        1.
    @295     lpprplld        1.
    @296     lpprpln         2.
    @298     lpprpl01        1.
    @299     lpprpl02        1.
    @300     lpprpl03        1.
    @301     lpprpl04        1.
    @302     lpprpl05        1.
    @303     lpprpl06        1.
    @304     lpprpl07        1.
    @305     lpprpl08        1.
    @306     lpprpl09        1.
    @307     lpprpl10        1.
    @308     lpprpl11        1.
    @309     lpprpl12        1.
    @310     lpprefld        1.
    @311     lpprefn         1.
    @312     lppref01        1.
    @313     lppref02        1.
    @314     lppref03        1.
    @315     lppref04        1.
    @316     lppref05        1.
    @317     lppref06        1.
    @318     lppref07        1.
    @319     blank23         1. ;
    
LABEL

    /*      household section  */
        
    Landuse  =  "   -land use: rural vs urban            "
    Metsize  =  "   -place size                          " 
    Msatype  =  "   -place description                   "
    Lvquart  =  "   -type of living quarters             "
    Hhszge12 =  "   -# in household aged 12 or older     "
    Hhszlt12 =  "   -# in household aged less than 12    "
    Phonokay =  "   -is phone interview okay             "
    INCOME   =  "H26-HH INCOME-SPECIFIC CATEGORY         "
    Hhszge18 =  "   -# in household aged 18 or older     "
    
    /*      person section  */
    
    Refrltn  =  "   -relationship to reference person    "
    Age      =  "   -age at time of interview            "
    MARSTAT  =  "H7-MARITAL STATUS                       "
    RACE     =  "H2-RACE/ETHNICITY                       "
    SEX      =  "S7-RESPONDENT SEX                       "
    GRADE    =  "H9-HIGHEST GRADE/YEAR OF SCHOOL         "
    Gradecom =  "   -did you complete that grade         "
    WORKWK   =  "H15-WORKED LAST WEEK FOR PAY OR PROFIT  "
    Workwkhr =  "   -# hours worked last week            "
    Ethncity =  "   -ethnicity                           "
    workwk2  =  "   -worked last week recode             "
    
    /*      SPPA section  */
    
    Intvtype =  "   -interview type                      "
    Chszlt06 =  "   -# of respondant's children under 6  "
    Chsz0611 =  "   -# of respondant's children 6 to 11  "
    LPJAZZMO =  "A2A-# TIMES WENT LIVE JAZZ LAST MO      "
    LPCLASMO =  "A4A-# TIMES WENT LIVE CLASSCL LAST MO   "
    LPOPERMO =  "A6A-# TIMES WENT LIVE OPERA LAST MO     "
    LPMUSIMO =  "A8A-# TIMES WENT LIVE MUSICAL LAST MO   "
    LPPLAYMO =  "A10A-# TIMES WENT LIVE PLAY LAST MO     "
    LPBALLMO =  "A12A-# TIMES WENT LIVE BALLET LAST MO   "
    LPGALLMO =  "A16A-# TIMES WENT ART MUSEUM LAST MO    "
    PPMUSWEL =  "E14-CAN PERFORM FOR/WITH OTHER MUSICIANS"
    PPCLAPLA =  "E19-PLAYED CLASSICAL MUSIC LAST 12 MO   "
    PPJAZPLA =  "E17-PERFORMED JAZZ MUSIC LAST 12 MO     "
    PPPLAPUB =  "E26-ACT IN PUBLIC PERF OF PLAY LST 12 MO"
    PPMUSPUB =  "E24-SANG PUBLIC PERFORMANCE OF MUSICAL  "
    PPOPRSNG =  "E21-SANG MUSIC FROM OPERA LAST 12 MO    "
    PPBALLET =  "E27-DANCED BALLET LAST 12 MO            " ;

FORMAT

    Landuse         urbrural.
    Metsize         metrange.
    Msatype         msa.
    Lvquart         quartype.
    Hhszge12        number.
    Hhszlt12        number.
    Phonokay        phyesno.
    INCOME          incrange.
    Hhszge18        number.
    Intvmm          monthnm.
    Intvyy          number.
    Refrltn         relation.
    Age             number.
    MARSTAT         status.
    RACE            rrace.
    SEX             mf.
    GRADE           gradeyr.
    Gradecom        yesno.
    WORKWK          worksta.
    Workwkhr        number.
    Ethncity        ethncode.
    workwk2         workstb.
    Intvtype        itype.
    Chszlt06        numbera.
    Chsz0611        numbera.
    LPJAZZMO        lpfreq.
    LPCLASMO        lpfreq.
    LPOPERMO        lpfreq.
    LPMUSIMO        lpfreq.
    LPPLAYMO        lpfreq.
    LPBALLMO        lpfreq.
    LPGALLMO        lpfreq.
    PPMUSWEL        noyes.
    PPCLAPLA        noyes.
    PPJAZPLA        noyes.
    ppanypub        noyes.
    PPPLAPUB        noyes.
    PPMUSPUB        noyes.
    PPOPRSNG        noyes.
    PPBALLET        noyes.
    LPREAD          noyes. ;

RUN ;
PROC CONTENTS ;   RUN ;