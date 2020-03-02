** 
 * ==========================================================================
 * SPSS-Example.sps
 * 
 * Distributed as an example of Alpha's SPSS mode.
 * 
 * ==========================================================================
 **

** 
 * ==========================================================================
 * Correlates of War Analysis - Exploring global trends over two centuries
 *
 * FILE: "correlates-1-1.sps"
 *                                          created: 12/01/1999 {10:39:52 pm}
 *                                      last update: 06/13/2000 {03:51:17 pm}
 * Description: 
 * 
 * source file that creates a frequency file "correlates-1-1.freq"
 * for civil wars, performs minor recodes
 * 
 * Author: Craig Barton Upright
 * E-mail: <cupright@alumni.princeton.edu>
 *    www: <http://www.purl.org/net/cbu>
 * 
 * Copyright (c) 1999-2000 Craig Barton Upright
 * All rights reserved.
 * 
 * ==========================================================================
 **


*** Preliminaries

set width = 80.


* Importing portable data files, running frequencies.

import file = "../data/sp9905cw.export".

display dictionary.

freq all.

execute.


*** Creating new variables

compute yrbeg1 = yrbeg1 + 1000.
compute yrbeg2 = yrbeg2 + 1000.
compute yrbeg3 = yrbeg3 + 1000.

compute yrend1 = yrend1 + 1000.
compute yrend2 = yrend2 + 1000.
compute yrend3 = yrend3 + 1000.


* here's how we could make sure that wars with
* multiple stops / starts have the last ending year:

* compute yrend1 = yrend2 if (yrend2 > yrend1).
* compute yrend1 = yrend3 if (yrend3 > yrend1).


* creating civil / international dummies

compute civil = 1.
compute intl  = 0.

formats civil    (F8.0).
formats intl     (F8.0).

add value labels civil intl

    0 "international war     "
    1 "civil war             ".


* creating 19th, 20th century dummies

compute year = yrbeg1.

recode  year

    (1800 thru 1899 = 19)
    (1900 thru 1999 = 20)

    into century.

recode  century

    (19 = 1) (20 = 0)

    into ninetnth.

recode  century

    (19 = 0) (20 = 1)

    into twntieth.

add value labels ninetnth twntieth

    0 "0 nineteenth century  "
    1 "1 twentieth century   ".


formats year     (F8.0).
formats century  (F8.0).
formats ninetnth (F8.0).
formats twntieth (F8.0).


* changing the case of the value labels in the variable warname.

compute warnumb = warnum.

recode  warnumb

    (601 = "Spain (1821-1823)"                                 )
    (602 = "Two Sicilies (1820-1821) I "                       )
    (603 = "Sardinia (1821) I "                                )
    (604 = "Turkey/Ottoman Empire (1826)"                      )
    (607 = "Portugal (1829-1834) I "                           )
    (610 = "France (1830)"                                     )
    (613 = "Mexico (1832)"                                     )
    (616 = "Spain (1834-1840) I "                              )
    (619 = "Colombia (1840-1842)"                              )
    (622 = "Argentina (1841-1851) I "                          )
    (625 = "Spain (1847-1849)"                                 )
    (626 = "Mexico [Caste War] (1847-1855)"                    )
    (628 = "Two Sicilies (1848-1849)"                          )
    (631 = "France (1848)"                                     )
    (634 = "Austria-Hungary (1848)"                            )
    (636 = "France [Royalists] (1851)"                         )

    into warname.


* creating wwI, wwII, worldwar dummy variables

recode  warnumb

    (106 = 1) (else = 0)

    into wwI.

recode  warnumb

    (139 = 1) (else = 0)

    into wwII.

recode  warnumb

    (106, 139 = 1) (else = 0)

    into worldwar.

formats wwI      (F8.0).
formats wwII     (F8.0).
formats worldwar (F8.0).

variable labels wwI      "World War One dummy variable   ".
variable labels wwII     "World War Two dummy variable   ".
variable labels worldwar "World War either dummy variable".


*** Recoding countries into regions

recode ccode

    /* South America and Mexico */

    ( 70, 100, 101, 110, 115, 130, 135, 140, 
     145, 150, 155, 160, 165,                = 1)

    /* Central America and Caribbean */

    ( 31,  40,  41,  42,  51,  52,  53,  54,
      55,  56,  57,  58,  60,  80,  90,  91,  
      92,  93,  94,  95,                     = 2)

    /* South America and Mexico */

    (  2,  20, 200, 205, 210, 211, 212, 220,
     223, 225, 230, 235, 240, 245, 255, 260,
     265, 267, 269, 271, 273, 275, 280, 290,
     300, 305, 310, 315, 325, 327, 329, 331,
     332, 335, 337, 338, 339, 344, 345, 346,
     349, 350, 352, 355, 359, 360, 365, 366,
     367, 368, 369, 370, 371, 372, 373, 375,
     380, 385, 390, 395,                     = 3)

    /*  North America and Europe */

    (600, 615, 616, 620, 625, 630, 640, 645,
     651, 652, 660, 663, 666, 670, 678, 679,
     680, 690, 692, 694, 696, 698,           = 4)

    /*  Middle East / North Africa */

    (402, 403, 404, 411, 420, 432, 433, 434, 
     435, 436, 437, 438, 439, 450, 451, 452, 
     461, 471, 475, 481, 482, 483, 484, 490,
     500, 501, 510, 511, 516, 517, 520, 522,
     522, 530, 540, 541, 551, 552, 553, 560,
     565, 570, 571, 572, 580, 581, 590, 591, = 5)

    /* Africa */

    (700, 701, 702, 703, 704, 705, 710, 712,
     713, 730, 731, 732, 740, 750, 760, 770,
     771, 775, 780, 781, 790, 800, 811, 812,
     816, 817, 820, 830, 835, 840, 850, 900,
     910, 920, 935, 940, 950, 983, 987,      = 6)

    into region.

add value labels region

    1 "1 South America and Mexico      "
    2 "2 Central America and Caribbean "
    3 "3 North America and Europe      "
    4 "4 Middle East and North Africa  "
    5 "5 Africa                        "
    6 "6 Asia                          ".

string regname (A32).

recode region

    (1 = "South America and Mexico       ")
    (2 = "Central America and Caribbean  ")
    (3 = "North America and Europe       ")
    (4 = "Middle East and North Africa   ")
    (5 = "Africa                         ")
    (6 = "Asia                           ")

    into regname.


formats region   (F8.0).

variable labels region   "region name                    ".

execute.


*** Renaming variables
* 
* note: even thought the codebook says that the name of the variable
* for population is POP, it is actually TOTPOP.
*

rename variables 

    (duration = durmnth  )
    (battdea  = dead     )
    (numarmy  = military )
    (totpop   = populatn ).


* note: 10 cases have durations of zero, which does not make sense.
* I'm changing them to have at least a one-month duration.

recode  durmnth  (0 = 1).

* creating duration by year variable

compute duryear = durmnth / 12.


* creating a second duryear variable that will only be attached to the
* starting year of the war

compute duryear1 = duryear.


* changing scale of population measures

compute  dead     = dead     * 1    .
compute  military = military * 1000 .
compute  populatn = populatn * 1000 .


* creating a second population, military variable that will only be attached
* to the starting year of the war

compute popnorig = populatn.
compute miltary2 = military.

formats  populatn (F8.0).
formats  popnorig (F8.0).
formats  military (F8.0).
formats  miltary2 (F8.0).

variable labels durmnth  "Duration of Involvement (months)".
variable labels duryear  "Duration of Involvement (years) ".
variable labels duryear1 "Duration of Involvement (years) ".
variable labels dead     "Battle Related Fatalities Sustained (actual number)".
variable labels military "Pre-war Regular Armed Forces (actual number)".
variable labels miltary2 "Pre-war Regular Armed Forces (actual number)".
variable labels populatn "Pre-war Total Population (actual number)".
variable labels popnorig "Pre-war Total Population (actual number)".


execute.


*** Finishing up

* sorting cases

sort cases by region natname year warnumb.


* saving, re-ordering variables

save   outfile = "../data/correlates-1-1.sav"

    /keep   year     region   regname  ccode    natname  abbrev
            warnumb  warname  wwI      wwII     worldwar 
            century  civil    ninetnth twntieth intl     
            durmnth  duryear  duryear1 dead     military miltary2
            populatn popnorig ALL                                    

    /drop   warnum
            mobeg1   dybeg1    moend1   dyend1   
            mobeg2   dybeg2    moend2   dyend2   
            mobeg3   dybeg3    moend3   dyend3 
            wartype  censyst   major    winner
            western  europe    african  mideast
            asian    oceanic   intersta interven  .

export outfile = "../data/correlates-1-1.por"

    /keep   year     region   regname  ccode    natname  abbrev
            warnumb  warname  wwI      wwII     worldwar
            century  civil    ninetnth twntieth intl
            durmnth  duryear  duryear1 dead     military miltary2
            populatn popnorig ALL 

    /drop   warnum
            mobeg1   dybeg1    moend1   dyend1   
            mobeg2   dybeg2    moend2   dyend2   
            mobeg3   dybeg3    moend3   dyend3 
            wartype  censyst   major    winner
            western  europe    african  mideast
            asian    oceanic   intersta interven  .


execute.

* .
