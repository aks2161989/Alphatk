## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # Statistical Modes - an extension package for Alpha
 #
 # FILE: "SttaCompletions.tcl"
 #                                         created: 05/14/2000 {01:48:41 pm}
 #                                     last update: 02/23/2006 {03:59:25 PM}
 # Description: 
 #
 # This file will be sourced automatically, immediately after the _first_
 # time stataMode.tcl is sourced.  This file declare completions items and
 # procedures for Stta mode.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2000-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc SttaCompletions.tcl {} {}

# Setting the order of precedence for completions.

set completions(Stta) [list \
  contraction completion::cmd Command Option Dated completion::electric \
  completion::word]

namespace eval Stta {}

proc Stta::defineElectrics {} {
    
    global Sttaelectrics
    
    variable commandElectrics
    variable keywordLists
    variable syntaxMessages
    
    # =======================================================================
    # 
    # ×××× Stta Command Electrics  ×××× #
    # 
    # These are distinguished from "Sttaelectrics" because we want them to
    # take place after [Stta::Completions::Command] takes place, not before.
    # 
    # Each completion will already have $lastword and a space, "$lastword ",
    # and will end with (optional semi)\r¥¥"
    # 

    # ××××   Specific completions ×××× #

    array set commandElectrics {
	
	alpha           "¥varlist¥"
	anova           "¥¥ ¥¥"
	append          "using ¥filename¥"
	areg            "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	bitest          "¥varname¥ = ¥\#p¥"
	bitesti         "¥\#N¥ ¥\#succ¥ ¥\#p¥"
	blogit          "¥pos_var¥ ¥pop_var¥ ¥¥"
	bprobit         "¥pos_var¥ ¥pop_var¥ ¥¥"
	bs              "\"¥command¥\" \"¥exp_list¥\""
	bsskew0         "¥newvar¥ = ¥exp¥"
	bsqreg          "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	canon           "¥varlist1¥ ¥varlist2¥"
	cc              "¥varcase¥ ¥varexposed¥"
	cchart          "¥defect_var¥ ¥unit_var¥"
	cci             "¥a¥ ¥b¥ ¥c¥ ¥d¥"
	cf              "¥varlist¥ using ¥filename¥"
	clear           ""
	clogit          "¥depvar¥ ¥\[indepvars\]¥ ¥¥, strata(¥¥)¥¥"
	cnreg           "¥depvar¥ ¥\[indepvars\]¥ ¥¥, censored(¥¥)"
	cnsreg          "¥depvar¥ ¥\[indepvars\]¥ ¥¥, constraints(¥¥)¥¥"
	coleq           "¥¥"
	collapse        "¥clist¥"
	colnames        "¥¥"
	compare         "¥var1¥ ¥var2¥"
	cross           "using  ¥¥"
	cs              "¥varcase¥ ¥varexposed¥"
	csi             "¥a¥ ¥b¥ c¥ ¥d¥"
	cusum           "¥yvar¥ ¥xvar¥"
	decode          "¥var¥, gen(¥¥)"
	define          "¥progName¥"
	dydx            "¥yvar¥ ¥xvar¥, generate(¥¥)"
	egen            "¥newvar¥ == ¥fcn(stuff)¥"
	eivreg          "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	else            "¥command¥ \{\r\t¥¥\r\}"
	encode          "¥varname¥, gen(¥newvar¥)¥¥"
	ereg            "¥depvar¥ ¥\[varlist\]¥ ¥¥"
	foreach         "¥lname¥ ¥in|of¥ ¥list-type¥ \{\r\t¥commands¥\r\}"
	format          "¥varlist¥  %¥fmt¥"
	global          "¥macroName¥ \"¥¥\""
	generate        "¥newvar\[:lblname\]¥ = ¥exp¥"
	glogit          "¥pos_var¥ ¥pop_var¥ ¥¥"
	gnbreg          "¥eqname1¥ ¥eqname2¥"
	gprobit         "¥pos_var¥ ¥pop_var¥ ¥¥"
	graph           "using  ¥filename¥"
	hadimvo         "¥varlist¥, gen(¥newvar¥)¥¥"
	heckman         "¥eqname1¥ ¥eqname2¥"
	hilite          "¥yvar¥ ¥xvar¥, hilite(¥exp2¥)¥¥"
	if              "¥exp¥ \{\r\t¥¥\r\}"
	impute          "¥depvar¥ ¥varlist¥ ¥¥"
	integ           "¥yvar¥ ¥xvar¥, generate(¥¥)"
	intreg          "¥depvar1¥ ¥depvar2¥ ¥\[indepvars\]¥"
	ipolate         "¥xvar¥ ¥yvar¥, gen(¥newvar¥)¥¥"
	iqreg           "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	ir              "¥varcase¥ ¥varexposed¥ ¥vartime¥"
	iri             "¥a¥ ¥b¥ ¥n1¥ ¥n2¥"
	kap             "¥varname1¥ ¥varname2¥"
	ksm             "¥xvar¥ ¥yvar¥"
	ktau            "¥varname1¥ ¥varname2¥"
	level           "¥\#¥"
	lnskew0         "¥newvar¥ = ¥exp¥"
	local           "¥macroName¥ \"¥¥\""
	logistic        "¥depvar¥ ¥varlist¥ ¥¥"
	logit           "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	loneway         "¥response-var¥ ¥group-var¥"
	mcc             "¥varexposed-case¥ ¥varexposed-control¥"
	mcci            "¥a¥ ¥b¥ ¥c¥ ¥d¥"
	merge           "¥\[varlist\]¥ using ¥filename¥"
	mlogit          "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	mvdecode        "¥varlist¥, mv(¥\#¥)"
	mvencode        "¥varlist¥, mv(¥\#¥)"
	mvreg           "¥depvarlist¥ = ¥varlist¥ ¥¥"
	nbreg           "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	ologit          "¥depvar¥ ¥\[varlist\]¥ ¥¥"
	oneway          "¥response-var¥ ¥factor-var¥"
	oprobit         "¥depvar¥ ¥\[varlist\]¥ ¥¥"
	outfile         "¥\[varlist\]¥ using ¥filename¥"
	outsheet        "¥\[varlist\]¥ using ¥filename¥"
	pchart          "¥reject_var¥ ¥unit_var¥ ¥ssize_var¥ ¥¥"
	pcorr           "¥varname1¥ ¥varlist¥"
	plot            "¥yvar¥ ¥xvar¥"
	poisson         "¥depvar¥ ¥\[varlist\]¥ ¥¥"
	probit          "¥depvar¥ ¥\[varlist\]¥ ¥¥"
	qqplot          "¥varname1¥ ¥varname2¥"
	qreg            "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	_qreg           "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	range           "¥varname¥ ¥min¥ ¥max¥"
	recast          "¥type¥ ¥varlist¥"
	recode          "¥varname¥ ¥rule¥ = ¥¥"
	regress         "¥depvar¥ ¥\[varlist\]¥ ¥¥"
	rename          "¥old_varname¥ ¥new_varname¥"
	renpfix         "¥old_stub¥ ¥\[new_stub\]¥"
	replace         "¥oldvar¥ = ¥exp¥"
	rreg            "¥depvar¥ ¥\[varlist\]¥ ¥¥"
	search          "¥word¥ ¥¥"
	serrbar         "¥meanvar¥ ¥sdvar¥ ¥xvar¥"
	signrank        "¥varname¥ = ¥exp¥"
	signtest        "¥varname¥ = ¥exp¥"
	smooth          "¥smoother¥, ¥varname¥ gen(¥newvar¥)"
	spearman        "¥varname1¥ ¥varname2¥"
	sqreg           "¥depvar¥ ¥\[indepvars\]¥ ¥¥"
	stack           "¥varlist¥, into(¥newvars¥)¥¥"
	tab1            "¥var1¥ ¥var2¥ ¥var3¥, plot"
	tab2            "¥var1¥ ¥var2¥ ¥var3¥, chi2"
	tabulate        "¥varname¥, "
	tobit           "¥depvar¥ ¥\[indepvars\]¥ ¥¥, ll¥¥ ul¥¥"
	ttesti          "¥\#obs¥ ¥\#mean¥ ¥\#sd¥ ¥\#val¥ ¥¥"
	weibull         "¥depvar¥ ¥\[varlist\]¥ ¥¥"
	while           "¥exp¥ \{\r\t¥commands¥\r\}"
	xpose           ", clear ¥\[varname\]¥"
    }

    # ===========================================================================
    # 
    # ×××× Prefix Completions ×××× #
    # 
    foreach prefix $keywordLists(prefixes) {
	set Sttaelectrics($prefix) " ¥¥"
    }

    # =======================================================================
    # 
    # ×××× Parameter Completions ×××× #
    # 
    foreach parameter $keywordLists(parameters) {
	set commandElectrics($parameter) " ¥¥"
    }

    # =======================================================================
    # 
    # ×××× Function Completions ×××× #
    # 
    foreach function $keywordLists(functions) {
	set Sttaelectrics($function) "(¥¥)¥¥"
    }

    # =======================================================================
    # 
    # ×××× Option Completions ×××× #
    # 
    # These are distinguished from "Sttaelectrics" because we want them to take
    # place after the Stta::Completions::Option takes place, not before.
    # 
    # Each completion will already have $lastword and a space, "$lastword ", and
    # will end with "¥¥"
    # 
    set Sttaelectrics(values)      "¥value¥ \"¥label¥\""
    set Sttaelectrics(variables)   "¥varname¥ \"¥label¥\""

    # =======================================================================
    # 
    # ×××× Contractions ×××× #
    # 
    array set Sttaelectrics {
	
	l'd         "×kill0label define ¥label¥"
	l'vl        "×kill0label values ¥var¥ \"¥varlabel¥\" ¥¥"
	l'vr        "×kill0label variable ¥varname¥ \"¥label¥\" ¥¥"
    }

    # =======================================================================
    # 
    # ××××   Syntax messages ×××× #
    # 
    # Make sure that [,],{,},#, and " have preceding backslashes.
    # 

    # Dated command message 
    foreach dated $keywordLists(dated) {
	set    syntaxMessages($dated) "\"$dated\" is an out-dated command. "
	append syntaxMessages($dated) "Press F6 for more information."
    }

    # Specific message for select commands
    array set syntaxMessages {
	
	_qreg          "_qreg  depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] level(\#) quantile(\#) iterate(\#) trace accuracy(\#)\]"            
	_robust        "_robust varlist \[weight\] \[if exp\] \[in range\] variance(matname) minus(\#) strata(varname) psu(varname) cluster(varname) fpc(varname) subpop(varname) vsrs(varname) srssubpop zeroweight \]"
	accum          "matrix accum A = varlist \[weight\] \[if exp\] \[in range\] deviations means(M) noconstant \]"
	acprplot       "acprplot indepvar \[, bwidth(\#) graph_options \]"
	adopath        "adopath +  pathname_or_codeword"
	adosize        "set adosize \#    10  < = \#  < = 500"
	alpha          "alpha varlist \[if exp\] \[in range\] \[, asis casewise detail generate(newvar) item label min(\#) reverse(varlist) std \]"
	anova          "\[by varlist:\]  anova \[varname \[term \[/\] \[term \[/\] ...\]\]\] \[weight\] \[if exp\] \[in range\] \[, \[no\]anova category(varlist) class(varlist) noconstant continuous(varlist) repeated(varlist) bse(term) bseunit(grouping(varname) detail partial sequential regress\]"
	aorder         "aorder \[varlist\]"
	append         "append using filename \[, nolabel \]"
	areg           "areg depvar \[indepvars\] \[weight\] \[if exp\] \[in range\], absorb(varname) \[ robust cluster(varname) level(\#) \]"
	assert         "\[by varlist:\]  assert exp \[if exp\] \[in range\] \[, rc0 \]"
	avplot         "avplot indepvar \[, graph_options\]"
	avplots        "avplots \[, graph_options\]"
	bcskew0        "bcskew0 newvar = exp \[in range\] \[if exp\] \[, level(\#) delta(\#) zero(\#) \]"
	beep           "set beep \{ on | off \}"
	bitest         "bitest varname = \#p \[weight\] \[if exp\] \[in range\] \[, detail\]"
	bitesti        "bitesti \#N \#succ \#p \[, detail\]"
	blogit         "blogit  pos_var pop_var \[rhsvars\] \[if exp\] \[in range\] \[, level(\#) or logit_options \]"
	bmemsize       "memsize and bmemsize are anachronisms."
	boxcox         "boxcox \[depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] \] \[, nolog generate(newvar) mean median graph saving(filename\[,replace\]) level(\#) grvars lstart(\#) iterate(\#) delta(\#) zero(\#) \]"
	bprobit        "bprobit pos_var pop_var \[rhsvars\] \[if exp\] \[in range\] \[, level(\#) probit_options \]"
	brier          "brier outcome forecast \[if exp\] \[in range\] \[, group(\#) \]"
	bs             "bs \"command\" \"exp_list\" \[, bstrap_options\]"
	bsample        "bsample \[exp\] \[, cluster(varnames) idcluster(newvarname) \]"
	bsqreg         "bsqreg depvar \[indepvars\] \[if exp\] \[in range\] level(\#) quantile(\#) reps(\#)\]"
	bsqreg         "bsqreg depvar \[indepvars\] \[if exp\] \[in range\] level(\#) quantile(\#) reps(\#)\]"
	bstat          "bstat varlist \[, stat(\#) level(\#) \]"
	bstrap         "bstrap progname \[, reps(\#) size(\#) dots args(...) level(\#) cluster(varnames) idcluster(newvarname) saving(filename) double every(\#) replace noisily \]"
	canon          "canon (varlist1) (varlist2) \[weight\] \[if exp\] \[in range\] \[, lc(\#) noconstant level(\#) \]"
	cc             "cc case_var ex_var \[weight\] \[if exp\] \[in range\] \[, level(\#) exact tb woolf by(varname) nocrude bd pool nohom estandard istandard standard(varname) binomial(varname) \]"
	cchart         "cchart defect_var unit_var \[, graph_options \]"
	cci            "cci \#a \#b \#c \#d \[, level(\#) exact tb woolf \]"
	cd             "cd :drive_name:folder_name"
	centile        "centile \[varlist\] \[if exp\] \[in range\] \[, centile(numlist) cci normal meansd level(\#) \]"
	cf             "cf varlist using filename \[, verbose \]"
	ci             "ci \[varlist\] \[weight\] \[if exp\] \[in range\] \[, level(\#) binomial poisson exposure(varname) by(varlist2) total \]"
	cii            "Confidence intervals for means, proportions, and counts ; several variations"
	clear          "Eliminate variables or observations"
	clogit         "\[by varlist:\] clogit depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] ,"
	cnreg          "cnreg depvar \[indepvars\] \[weight\] \[if exp\] \[in range\], censored(varname) \["
	cnsreg         "cnsreg depvar varlist \[weight\] \[if exp\] \[in range\], constraints(clist) \[ level(\#) \]"
	codebook       "codebook \[varlist\] \[, all header notes mv tabulate(\#)\]"
	coleq          "matrix coleq A = name \[name \[...\]\]"
	collapse       "collapse clist \[weight\] \[if exp\] \[in range\] \[, by(varlist) cw fast\]"
	colnames       "matrix colnames A = name \[name \[...\]\]"
	compare        "compare varname1 varname2 \[if exp\] \[in range\]"
	compress       "compress \[varlist\]"
	confirm         "confirm verifies that the arguments following are of the claimed type"
	convert         "http://www.stata.com/support/faqs/data/convert.html"
	correlate       "\[by varlist:\]  correlate \[varlist\] \[weight\] \[if exp\] \[in range\] \[, means noformat covariance _coef wrap \]"
	count           "\[by varlist:\] count \[if exp\] \[in range\]"
	cox          "\[by varlist:\]  cox timevar \[varlist\] \[weight\] \[if exp\] \[in range\] \[, hr dead(failvar) t0(varname) strata(varnames) robust cluster(varname) noadjust offset(varname) basehazard(newvar) basechazard(newvar) basesurv(newvar)  mgale(newvar) esr(newvars) schoefeld(newvars) scaledsch(newvars) \{ breslow | efron | exactm | exactp \} nocoef noheader level(\#) maximize_options \]"
	cprplot         "cprplot indepvar \[, bwidth(\#) graph_options \]"
	cross           "cross using filename"
	cs              "cs case_var ex_var \[weight\] \[if exp\] \[in range\] \[, level(\#) exact tb woolf by(varlist) nocrude pool nohom or estandard istandard standard(varname) rd binomial(varname) \]"
	csi             "csi \#a \#b \#c \#d \[, level(\#) exact or tb woolf \]"
	cumul           "cumul varname \[weight\] \[if exp\] \[in range\] , gen(newvar) \[ freq by(varlist) \]"
	cusum           "cusum yvar xvar \[if exp\] \[in range\] yfit(fitvar) nograph nocalc gen(newvar) graph_options \]"
	decode          "decode varname \[if exp\] \[in range\], generate(newvar) \[maxlength(\#)\]"
	define          "see help for contraints, label, macro, matrix, maximize, program, scalar, xwindow."
	delimit         "\#delimit \{ cr | ; \}"
	describe        "describe \[varlist | using filename\] \[, short detail \]"
	dfbeta          "dfbeta \[indepvar \[indepvar \[...\]\]\]"
	dir             "\{ dir | ls \} \[\"\]\[filespec\]\[\"\] \[, wide\]"
	discard         "discard drops all automatically loaded programs"
	dispCns         "matrix dispCns"
	display         "display displays strings and values of scalar expressions."
	do              "do filename \[arguments\] \[, nostop\]"
	dprobit         "dprobit  \[ depvar indepvars \[weight\] \[if exp\] \[in range\] \] at(matname) classic probit_options \]"
	drop            "drop varlist -OR- \[by varlist:\]  drop if exp -OR- drop in range \[if exp\]"
	ds              "ds \[varlist\]"
	dydx            "dydx yvar xvar \[if exp\] \[in range\], generate(newvar) \[ replace by(varlist) \]"
	egen            "egen \[type\] newvar = fcn(stuff) \[if exp\] \[in range\] \[, options\]"
	eivreg          "eivreg depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] \[, r(indepvar \# \[indepvar \# ...\]) level(\#) \]"
	else            "if exp \{ commands \} else command "
	encode          "encode varname \[if exp\] \[in range\], generate(newvar) \[label(name)\]"
	end             "see (help exit) -- Exit Stata ; Exit from a program or do-file"
	erase           "\{ erase | rm \} filename"
	ereg            "\{ weibull | ereg \} depvar \[varlist\] \[weight\] \[if exp\] \[in range\] \[, hazard hr tr dead(varname) t0(varname) robust cluster(varname) score(newvars) noconstant level(\#) nocoef noheader maximize_options \]"
	error           "Display generic error message and exit programming command"
	existence       "confirm existence \[string\]"
	exit            "exit \[\[=\]exp\] \[, clear STATA \]"
	expand          "expand \[=\]exp \[if exp\] \[in range\]"
	factor          "\[by varlist:\] factor \[varlist\] \[weight\] \[if exp\] \[in range\] \[, \{ pc | pcf | pf | ipf | ml \} factors(\#) mineigen(\#) covariance means protect(\#) random maximize_options \]"
	fillin          "fillin varlist -- fillin adds observations with missing data"
	for             "for listtype list :  stata_cmd_containing_X"
	format          "format varlist %fmt"
	fsl             "fsl is not a Stata command but a separate program that you execute"
	function        "Functions are used in expressions"
	generate        "\[by varlist:\]  generate \[type\] newvar\[:lblname\] = exp \[if exp\] \[in range\]"
	gladder         "gladder varname \[if exp\] \[in range\] \[, bin(\#) graph_options \]"
	global          "global mname \[=exp | :extended_fcn | \[`\]\"\[string\]\"\['\] \]"
	glogit          "glogit  pos_var pop_var \[rhsvars\] \[if exp\] \[in range\] \[, level(\#) or \]"
	glsaccum        "matrix glsaccum A = varlist \[weight\] \[if exp\] \[in range\], group(groupvar) glsmat(\{W|stringvar\}) row(rowvar) noconstant\]"
	gnbreg          "gnbreg depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] \[, lnalpha(varlist) irr exposure(varname) offset(varname) robust cluster(varname) score(newvarnames) level(\#) noconstant nolrtest maximize_options \]"
	gphdot          "\{ gphdot | gphpen \} \[-option -option ...\] filename"
	gphpen          "\{ gphdot | gphpen \} \[-option -option ...\] filename"
	gprobit         "gprobit pos_var pop_var \[rhsvars\] \[if exp\] \[in range\] \[, level(\#) \]"
	graph           "\[by varlist:\]  graph \[varlist\] ... ; graph using filename"
	graphics        "set graphics \{ on | off \}"
	greigen         "greigen \[, graph_options \]"
	grmeanby        "grmeanby varlist \[weight\] \[if exp\] \[in range\], summarize(varname) \["
	hadimvo         "hadimvo varlist \[if exp\] \[in range\], generate(newvar1 \[newvar2\]) \[p(\#)\]"
	heckman         "heckman depvar \[varlist\], <then several variations>"
	help            "help any_stata_command"
	hilite          "hilite yvar xvar \[if exp\] \[in range\], hilite(exp2) \[graph_options \]"
	hold            "estimates hold holdname"
	hotel           "hotel varlist \[weight\] \[if exp\] \[in range\] \[, by(varname) notable\]"
	if              "if exp \{ commands \} else command "
	impute          "impute depvar varlist \[weight\] \[if exp\] \[in range\] , generate(newvar1) "
	infile          "Read non-Stata data into memory"
	input           "input \[varlist\] \[, automatic label \]"
	inspect         "\[by varlist:\] inspect \[varlist\] \[if exp\] \[in range\]"
	integ           "integ yvar xvar \[if exp\] \[in range\] \[, generate(newvar) replace by(varlist) trapezoid initial(\#) \]"
	intreg          "intreg  depvar1 depvar2 \[indepvars\] \[weight\] \[if exp\] \[in range\] \[, noconstant robust cluster(varname) score(newvar1 newvar2) level(\#) offset(varname) maximize_options \]"
	ipolate         "ipolate yvar xvar, generate(newvar) \[by(varnames) epolate\]"
	iqreg           "iqreg  depvar \[indepvars\] \[if exp\] \[in range\] level(\#) quantiles(\# \#) reps(\#) nolog\]"
	ir              "ir case_var ex_var time_var \[weight\] \[if exp\] \[in range\] \[, level(\#) tb by(varname) nocrude pool nohom estandard istandard standard(varname) ird \]"
	iri             "iri \#a \#b \#N1 \#N2 \[, level(\#) tb \]"
	kap             "Interrater agreement ; several variations"
	kappa           "Interrater agreement ; several variations"
	kapwgt          "Interrater agreement ; several variations"
	keep            "keep varlist -OR- \[by varlist:\]  keep if exp -OR- keep in range \[if exp\]"
	ksm             "ksm yvar xvar \[if exp\] \[in range\] \[, line weight lowess bwidth(\#) logit adjust gen(newvar) nograph graph_options \]"
	ksmirnov        "ksmirnov performs one- and two-sample Kolmogorov-Smirnov tests; several variations"
	ktau            "ktau varname1 varname2 \[if exp\] \[in range\]"
	kwallis         "kwallis varname \[if exp\] \[in range\], by(groupvar)"
	ladder          "ladder varname \[if exp\] \[in range\] \[, generate(newvar) noadjust \]"
	level           "set level \#  ; \# must be an integer between 10 and 99."
	lfit            "lfit \[depvar\] \[weight\] \[if exp\] \[in range\] \[, group(\#) table outsample all beta(matname) \]"
	linktest        "linktest \[if exp\] \[in range\] \[, estimation_cmd_options \]"
	list            "\[by varlist:\]  list \[varlist\] \[if exp\] \[in range\] \[, \[no\]display nolabel noobs \]"
	lnskew0         "lnskew0 newvar = exp \[in range\] \[if exp\] \[, level(\#) delta(\#) zero(\#) \]"
	local           "local lclname \[=exp | :extended_fcn | \[`\]\"\[string\]\"\['\] \]"
	log             "Echo copy of session to file or device ; several variations"
	logistic        "logistic depvar varlist \[weight\] \[if exp\] \[in range\] \[, level(\#) robust cluster(varname) score(newvarname) asis offset(varname) coef maximize_options \]"
	logit           "\[by varlist:\]  logit  depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] \[, level(\#) nocoef noconstant or robust cluster(varname) score(newvar) offset(varname) asis maximize_options \]"
	loneway         "loneway response_var group_var \[weight\] \[if exp\] \[in range\] \[, mean median exact level(\#) \]"
	lookfor         "lookfor  string \[string \[...\]\]"
	lroc            "lroc \[depvar\] \[weight\] \[if exp\] \[in range\] \[, nograph graph_options all beta(matname) \]"
	lrtest          "lrtest \[, saving(name) using(name) model(name) df(\#) \]"
	ls              "\{ dir | ls \} \[\"\]\[filespec\]\[\"\] \[, wide\]"
	lstat           "lstat \[depvar\] \[weight\] \[if exp\] \[in range\] \[, cutoff(\#) all beta(matname) \]"
	ltable          "ltable timevar \[deadvar\] \[weight\] \[if exp\] \[in range\]  \[, by(groupvar) level(\#) survival failure hazard intervals(interval) test tvid(varname) noadjust notab graph graph_options noconf \]"
	lv              "lv \[varlist\] \[if exp\] \[in range\] \[, generate tail(\#) \]"
	lvr2plot        "lvr2plot \[, graph_options \]"
	makeCns         "matrix makeCns \[clist\]"
	matcproc        "matcproc T a C"
	maximize        "mle_cmd ...  \[, \[no\]log trace gradient hessian showstep iterate(\#) tolerance(\#) ltolerance(\#) gtolerance(\#) difficult from(init_specs) \]"
	mcc             "mcc ex_case_var ex_cntl_var \[weight\] \[if exp\] \[in range\] \[, level(\#) tb \]"
	mcci            "mcci \#a \#b \#c \#d \[, level(\#) tb \]"
	means           "means \[varlist\] \[if exp\] \[in range\] \[, add(\#) only level(\#) \]"
	memsize         "memsize and bmemsize are anachronisms."
	menu            "The window commands allow Stata programmers to create menus and dialogs.  See \[R\] window for an explanation of these commands"
	merge           "merge \[varlist\] using filename \[, nolabel update replace nokeep _merge(varname) \]"
	mhodds          "mhodds  case_var expvar \[adj_var\] \[weight\] \[if exp\] \[in range\] \[, level(\#) binomial(varname) by(varlist) compare(val1,val2) \]"
	mlogit          "\[by varlist:\] mlogit \[depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] \] \[, basecategory(\#) constraints(clist) robust cluster(varname) score(newvarlist) level(\#) rrr noconstant maximize_options \]"
	move            "move varname1 varname2"
	mvdecode        "mvdecode varlist \[if exp\] \[in range\], mv(\#)"
	mvencode        "mvencode varlist \[if exp\] \[in range\], mv(\#) \[override \]"
	mvreg           "mvreg depvarlist = varlist \[weight\] \[if exp\] \[in range\] \[, noconstant corr noheader notable level(\#) \]"
	nbreg           "nbreg depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] \[, dispersion(mean|constant) irr exposure(varname) offset(varname) robust cluster(varname) score(newvarnames) noconstant nolrtest level(\#) maximize_options \]"
	nl              "nl fcn depvar \[varlist\] \[weight\] \[if exp\] \[in range\] \[, level(\#) init(...) lnlsq(\#) leave eps(\#) nolog trace iterate(\#) delta(\#) fcn_options \]"
	nlinit          "nlinit \# parameter_list"
	nptrend         "nptrend varname \[if exp\] \[in range\], by(groupvar) \[nodetail score(scorevar)\]"
	ologit          "\[by varlist:\]  ologit depvar \[varlist\] \[weight\] \[if exp\] \[in range\] \[, table robust cluster(varname) score(newvarlist) level(\#) offset(varname) maximize_options \]"
	oprobit         "by varlist:\]  oprobit depvar \[varlist\] \[weight\] \[if exp\] \[in range\]\[, table robust cluster(varname) score(newvarlist) level(\#) offset(varname) maximize_options \]"
	order           "order  varlist"
	outfile         "outfile \[varlist\] using filename \[if exp\] \[in range\] \[, comma dictionary nolabel noquote replace wide \]"
	outsheet        "outsheet \[varlist\] using filename \[if exp\] \[in range\] \[, nonames nolabel noquote comma replace \]"
	pause           "pause \{ on | off | \[message\] \}"
	pchart          "pchart reject_var unit_var ssize_var \[, stabilized graph_options \]"
	pchi            "pchi varname \[if exp\] \[in range\] \[, df(\#) grid graph_options \]"
	pcorr           "pcorr varname1 varlist \[weight\] \[if exp\] \[in range\]"
	pd              "Pipeline drivers (pds) are used with Stata for Unix to process graphical output; see \[GSU\] stata"
	pd.ix           "Pipeline drivers (pds) are used with Stata for Unix to process graphical output; see \[GSU\] stata"
	pd.sunview      "Pipeline drivers (pds) are used with Stata for Unix to process graphical output; see \[GSU\] stata"
	pd.X            "Pipeline drivers (pds) are used with Stata for Unix to process graphical output; see \[GSU\] stata"
	plot            "\[by varlist:\]  plot yvar1 \[yvar2 \[yvar3\]\] xvar \[if exp\] \[in range\] columns(\#) encode hlines(\#) lines(\#) vlines(\#) \]"
	pnorm           "pnorm varname \[if exp\] \[in range\] \[, grid graph_options \]"
	poisson         "poisson depvar \[varlist\] \[weight\] \[if exp\] \[in range\] irr level(\#) exposure(varname) offset(varname) robust cluster(varname) score(newvarname) noconstant maximize_options \]"
	post            "post postname exp exp ... exp"
	postclose       "postclose postname"
	postfile        "postfile  postname varlist using filename \[, double every(\#) replace \]"
	predict         "Obtain predictions, residuals, etc., after estimation ; several variations"
	preserve        "preserve \[, changed\]"
	probit          "\[by varlist:\]  probit depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] level(\#) nocoef noconstant robust cluster(varname) score(newvar) asis offset(varname) maximize_options \]"
	program         "Define and manipulate programs"
	pwcorr          "pwcorr \[varlist\] \[weight\] \[if exp\] \[in range\] obs sig print(\#) star(\#) bonferroni sidak \]"
	pwd             "pwd displays the path of the current working directory."
	qchi            "qchi varname \[if exp\] \[in range\] \[, df(\#) grid graph_options \]"
	qnorm           "qnorm varname \[if exp\] \[in range\] \[, grid graph_options \]"
	qqplot          "qqplot varname1 varname2 \[if exp\] \[in range\] \[, graph_options \]"
	qreg            "qreg depvar \[indepvars\] \[weight\] \[if exp\] \[in range\] level(\#) quantile(\#) nolog iterate(\#) wlsiter(\#) trace\]"
	quantile        "quantile varname \[if exp\] \[in range\] \[, graph_options \]"
	query           "Display and set system parameters"
	range           "range varname \#first \#last \[\#obs\]"
	ranksum         "ranksum varname \[if exp\] \[in range\], by(groupvar)"
	rchart          "rchart varlist \[if exp\] \[in range\] \[, std(\#) graph_options \]"
	recast          "recast type varlist \[, force \]"
	recode          "recode varname rule \[rule ...\] \[*=el\] \[if exp\] \[in range\]"
	regress         "\[by varlist:\]  regress depvar \[varlist\] \[weight\] \[if exp\] \[in range\] level(\#) beta robust cluster(varname) hc2 hc3 hascons noconstant tsscons noheader eform(string) depname(varname) mse1\]"
	rename          "rename old_varname new_varname"
	renpfix         "renpfix old_stub \[new_stub\]"
	replace         "\[by varlist:\]  replace oldvar = exp \[if exp\] \[in range\] \[, nopromote \]"
	restore         "restore \[, not preserve\]"
	review          "\#review \[ \#1 \[\#2\] \]"
	rm              "\{ erase | rm \} filename"
	rotate          "rotate \[, \{ varimax | promax\[(\#)\] \} horst factors(\#) \]"
	roweq           "matrix roweq A = name \[name \[...\]\]"
	rownames        "matrix rownames A = name \[name \[...\]\]"
	rreg            "rreg depvar \[varlist\] \[if exp\] \[in range\] \[, level(\#) nolog graph tolerance(\#) tune(\#) genwt(newvar) iterate(\#) \]"
	run             "run filename \[arguments\] \[, nostop\]"
	runtest         "runtest varname \[in range\] \[, continuity drop split mean threshold(\#)\]"
	rvfplot         "rvfplot \[, graph_options\]"
	rvpplot         "rvpplot indepvar \[, graph_options\]"
	sample          "sample \# \[if exp\] \[in range\] \[, by(groupvars) \]"
	save            "save \[filename\] \[, nolabel old replace all \]"
	score           "score newvarlist \[if exp\] \[in range\] \[, bartlett norotate \]"
	sdtest          "Variance comparison tests ; several variations"
	sdtesti         "Variance comparison tests ; several variations"
	search          "search any_word_or_phrase"
	seed            "set seed \#"
	serrbar         "serrbar mvar svar xvar \[if exp\] \[in range\] \[, scale(\#) graph_options \]"
	sfrancia        "sfrancia varlist \[if exp\] \[in range\]"
	shell           "\{ shell | ! \} \[operating_system_command\]"
	shewhart        "shewhart varlist \[if exp\] \[in range\] \[, mean(\#) std(\#) graph_options \]"
	signrank        "signrank varname = exp \[if exp\] \[in range\]"
	signtest        "signtest varname = exp \[if exp\] \[in range\]"
	sktest          "sktest varlist \[weight\] \[if exp\] \[in range\] \[, noadjust \]"
	smooth          "smooth smoother\[,twice\] varname \[if exp\] \[in range\], generate(newvar)"
	sort            "sort varlist \[in range\]"
	spearman        "spearman varname1 varname2 \[if exp\] \[in range\]"
	sqreg           "sqreg  depvar \[indepvars\] \[if exp\] \[in range\] level(\#) quantiles(\# \[\# \[\# ...\]\]) reps(\#) nolog\]"
	stack           "stack varlist \[if exp\] \[in range\], \{ into(newvars) | group(\#) \} clear wide \]"
	stem            "stem varname \[if exp\] \[in range\] \[, digits(\#) \{ lines(\#) | width(\#) \} round(\#) prune \]"
	swilk           "swilk varlist \[if exp\] \[in range\] \[, lnnormal noties generate(newvar) \]"
	symplot         "symplot varname \[if exp\] \[in range\] \[, graph_options \]"
	sysdir          "sysdir set codeword \[\"\]path\[\"\]"
	tab1            "tab1 varlist \[weight\] \[if exp\] \[in range\] \[, missing nolabel plot \]"
	tab2            "tab2 varlist \[weight\] \[if exp\] \[in range\] \[, tabulate_options \]"
	tabi            "tabi displays the r x c table using the values specified ; several variations"
	tabodds         "tabodds case_var \[expvar\] \[weight\] \[if exp\] \[in range\] \[, level(\#) tb woolf cornfield binomial(varname) base(\#) adjust(varlist) or ciplot graph graph_options \]"
	tabulate        "One- and two-way tables of frequencies ; several variations"
	tempfile        "tempfile lclname \[lclname ...\]"
	tempname        "tempname lclname \[lclname ...\]"
	tempvar         "tempvar lclname \[lclname ...\]"
	testparm        "testparm varlist \[, equal \]"
	tobit           "tobit depvar \[indepvars\] \[weight\] \[if exp\] \[in range\], ll\[(\#)\] ul\[(\#)\] \["
	touch           "touch \[\"\]filename1\[\"\], like(\[\"\]filename2\[\"\])"
	ttest           "Mean comparison tests ; several variations"
	ttesti          "Mean comparison tests ; several variations"
	type            "set type \{ byte | int | long | float | double | str\# \}"
	unhold          "estimates unhold holdname"
	use             "use loads a Stata-format dataset previously saved by save into memory ; several variations"
	vecaccum        "matrix vecaccum a = varlist \[weight\] \[if exp\] \[in range\] \[, noconstant\]"
	version         "version \[\#\]"
	weibull         "\{ weibull | ereg \} depvar \[varlist\] \[weight\] \[if exp\] \[in range\] \[, hazard hr tr dead(varname) t0(varname) robust cluster(varname) score(newvars) noconstant level(\#) nocoef noheader maximize_options \]"
	which           "which command_name \[, all \]"
	while           "while exp \{ commands \} "
	window          "The window commands allow Stata programmers to create menus and dialogs.  See \[R\] window for an explanation of these commands"
	xchart          "xchart varlist \[if exp\] \[in range\] \[, mean(\#) std(\#) lower(\#) upper(\#)\] graph_options \]"
	xpose           "xpose, clear \[varname\]"
    }
    return
}

# Call this now.
Stta::defineElectrics

# ===========================================================================
# 
# ×××× -------- ×××× #
# 

namespace eval Stta::Completion {
    
    variable prefixAbbrevs
    array set prefixAbbrevs {

	a   ""
	b   ""
	c   "capture"
	d   ""
	e   "eq"
	f   ""
	g   ""
	h   ""
	I   ""
	j   ""
	k   ""
	l   "label"
	m   "matrix"
	n   "noisily"
	o   ""
	p   "program"
	q   "quietly"
	r   "reshape"
	s   "set"
	t   ""
	u   ""
	v   ""
	w   ""
	x   "xi:"
	y   ""
	z   ""
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::Completion::Command" --
 # 
 # (1)  The lists of commands and prefixes have already been created.
 # (2)  Check to see if the command is preceded by a ',
 #      if not then complete with any available template info.
 # (2)  Otherwise, check to see if the command is preceded by <space>',
 #      which indicates that only the command name should be completed.
 # (3)  Otherwise, check to see if the command is preceded by <anyletter>', 
 #      which indicates a command prefix.
 # (4)  If command-prefix is defined, insert "<command-prefix> <command>"
 # (5)  Othewise, insert "<anyletter>¥¥ <command>"
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::Completion::Command {} {
    
    global Sttacmds SttamodeVars Stta::commandElectrics Stta::syntaxMessages
    
    variable prefixAbbrevs
    
    set lastword [completion::lastWord where]
    if {[lsearch -exact $Sttacmds $lastword] == -1} {
        return 0
    }
    set oneBack     [pos::math $where - 1]
    set twoBack     [pos::math $where - 2]

    set oneBackChar [lookAt $oneBack]
    set twoBackChar [lookAt $twoBack]
    
    # Do we have a defined completion?
    if {[info exists Stta::commandElectrics($lastword)]} {
        set complete $Stta::commandElectrics($lastword)
    } else {
        set complete " ¥¥"
    } 
    # Do we need to add a semi delimiter?
    if {$SttamodeVars(semiDelimiter)} {
        append complete  " ;\r¥¥"
    } else {
        append complete "\r¥¥"
    } 
    # Do we have a message to put in the status bar?
    if {[info exists Stta::syntaxMessages($lastword)]} {
        set sm $Stta::syntaxMessages($lastword)
    } else {
        set sm ""
    } 
    # Now create the electric insertion.
    if {$oneBackChar != "'"} {
        # No preceding ' mark, so just complete with extra template.
        set commandInsertion " $complete"
    } else {
        if {$twoBackChar == " " || $twoBackChar == "\t"} {
            # Is this a <space>'<command> or a <tab>'<command> completion?
            # Insert $lastword with no extras.
            deleteText $oneBack [getPos]
            set commandInsertion "$lastword ¥¥"
            set sm ""
        } elseif {[llength $prefixAbbrevs($twoBackChar)]} {
            # Is the prefix abbreviation recognized?
            # Insert the prefix, then the command, then extra template.
            set twoBackPrefix $prefixAbbrevs($twoBackChar)
            deleteText $twoBack [getPos]
            set commandInsertion "$twoBackPrefix $lastword $complete"
        } else {
            # The prefix abbreviation wasn't recognized.
            # Keep the letter, place the cursor behind it.
            deleteText $twoBack [getPos]
            set commandInsertion "$twoBackChar¥¥ $lastword $complete"
        }
    }
    elec::Insertion $commandInsertion
    # Putting a message in the status bar with syntax information
    status::msg "$sm"
    return 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::Completion::Option" --
 # 
 # (1)  The lists of options has already been created.
 # (2)  Check to see if the command is preceded by <'>, which indicates 
 #      the user only wants the option name and no extra templates.
 # (3)  Complete the insertion as defined by the variable 
 #      Stta::commandElectrics($lastword)
 #      
 # This proc is necessary because the user might not know when a keyword is
 # defined in "stataMode.tcl" as a command or an option.  Without this proc,
 # completing 'notab would produce 'notable.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::Completion::Option {} {

    global Stta::keywordLists Stta::optionElectrics

    set lastword [completion::lastWord where]
    if {[lsearch -exact $Stta::keywordLists(allOptions) $lastword] == -1} {
        return 0
    }
    set oneBack   [pos::math $where - 1]

    # Do we have a defined completion?
    if {[info exists Stta::optionElectrics($lastword)]} {
        set complete $Stta::optionElectrics($lastword)
    } else {
        set complete " ¥¥"
    } 
    if {[lookAt $oneBack] == "'"} {
        # Is this a <'><option> contraction? 
        # Insert $lastword completion as defined below
        deleteText $oneBack [getPos]
        set optionInsertion "$lastword $complete"
    } else {
        # No, such just insert the option as defined below.
        set optionInsertion " $complete"
    }
    
    elec::Insertion $optionInsertion
    return 1
}

## 
 # --------------------------------------------------------------------------
 # 
 # "Stta::Completion::Dated" --
 # 
 # (1)  The lists of dated commands has already been created.
 # (2)  The keyword has already been completed -- high-light the command, 
 #      and give a message in the status bar that the command is outdated.
 # 
 # --------------------------------------------------------------------------
 ##

proc Stta::Completion::Dated {} {

    global Stta::keywordLists Stta::syntaxMessages

    set lastword [completion::lastWord where]
    if {[lsearch -exact $Stta::keywordLists(dated) $lastword] == -1} {
        return 0
    }
    goto $where
    hiliteWord
    if {[info exists Stta::syntaxMessages($lastword)]} {
	status::msg "$Stta::syntaxMessages($lastword)"
    }
    return 1
}

# ===========================================================================
# 
# .