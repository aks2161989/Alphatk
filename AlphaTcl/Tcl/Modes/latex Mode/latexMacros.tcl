## -*-Tcl-*- (nowrap)
 # ==========================================================================
 # LaTeX mode - an extension package for Alpha
 #
 # FILE: "latexMacros.tcl"
 #                                          created: 11/10/1992 {10:42:08 AM}
 #                                      last update: 08/09/2005 {03:11:50 PM}
 # Description:
 #
 # Support for the majority of the 'macros' items found in the TeX menu.
 #
 # See the "latex.tcl" file for license info, credits, etc.
 # ==========================================================================
 ##

# Make sure that the main TeX mode file has been loaded.
latex.tcl

proc latexMacros.tcl {} {}

namespace eval TeX {}

proc TeX::macroMenuProc {menuName itemName args} {
    
    global TeX::MacroInsertions TeXmodeVars auto_index
    
    if {[info exists TeX::MacroInsertions($itemName)]} {
        # Special user defined insertion.
	TeX::checkMathMode [join $itemName ""] 1
	set insertion1 [lindex [set TeX::MacroInsertions($itemName)] 0]
	set insertion2 [lindex [set TeX::MacroInsertions($itemName)] 1]
	regsub -all {([^¥])¥} $insertion1 "\\1¥¥" insertion1
	regsub -all {([^¥])¥} $insertion2 "\\1¥¥" insertion2
	if {![string length $insertion2]} {
	    TeX::insertObject $insertion1
	} elseif {[elec::Wrap $insertion1 $insertion2]} {
	    status::msg "Text has been wrapped in the $itemName template"
	} else {
	    status::msg "Enter text for the $itemName template."
	}
	return
    } elseif {(![info exists auto_index(::TeX::[join $itemName ""])]) \
      && [llength [info procs ::TeX::[join $itemName ""]]]} {
	# If the proc exists but isn't in our auto_path, it is defined by the
	# user in some PREFS file, so we call that now.
	::TeX::[join $itemName ""]
	return
    } 

    switch -- $menuName {

	"Arrows" {
	    TeX::checkMathMode [join $itemName ""] 1
	    TeX::insertObject "\\$itemName"
	}
	"Binary Operators" {
	    regsub "!." $itemName "" itemName
	    if {[regexp {[lr]hd$} $itemName]} {
		if {![TeX::requirePackage latexsym]} {return}
	    }
	    TeX::checkMathMode [join $itemName ""] 1
	    TeX::insertObject "\\$itemName"
	}
	"Boxes" {
	    set openWrap  "\\${itemName}\{"
	    set closeWrap "\}¥¥"
	    set message1  "$itemName set"
	    set message2  "enter text"
	    switch -- $itemName {
		"makebox" {
		    set openWrap "\\makebox\[¥width¥\]\[¥position¥\]\{"
		    set message1 "makebox set; enter the width and position"
		    set message2 "enter the width and position of the makebox, then the text"
		}
		"framebox" {
		    set openWrap "\\framebox\[¥width¥\]\[¥position¥\]\{"
		    set message1 "framebox set; enter the width and position"
		    set message2 "enter the width and position of the framebox, then the text"
		}
		"newsavebox" {
		    set message1 "newsavebox defined"
		    set message2 "enter the command name of the sbox or savebox"
		}
		"sbox" {
		    set openWrap "\\sbox{¥command¥}\{"
		    set message1 "sbox set; enter the command name"
		    set message2 "enter the command name of the sbox, then the text"
		}
		"savebox" {
		    set openWrap "\\savebox{¥command¥}\[¥width¥\]\[¥position¥\]\{"
		    set message1 "savebox set; enter the command name"
		    set message2 "enter the command name of the savebox"
		}
		"usebox" {
		    set message1 "usebox declared"
		    set message2 "enter the command name of the sbox or savebox"
		}
		"raisebox" {
		    set openWrap "\\raisebox{¥displacement¥}\[¥width¥\]\[¥position¥\]\{"
		    set message1 "raisebox set; enter the displacement"
		    set message2 "enter the displacement of the raisebox"
		}
		"parbox" {
		    set openWrap "\\parbox\[¥position¥\]\{¥width¥\}\{"
		    set message1 "parbox set; enter the position and width"
		    set message2 "enter the position \[b|c|t\] and width of the parbox, then the text"
		}
		"minipage" {
		    TeX::wrapEnvironment "minipage" "\[¥position¥\]\{¥width¥\}" ""
		    status::msg "enter the position \[b|c|t\] of the minipage, then the width"
		    return
		}
		"rule" {
		    TeX::insertObject "\\rule\[¥displacement¥\]\{¥width¥\}{¥height¥}¥¥"
		    status::msg "enter the displacement of the rule, then width and height"
		    return
		}
	    }
	    if {[elec::Wrap $openWrap $closeWrap]} {
	        status::msg $message1
	    } else {
	        status::msg $message2
	    }
	}
	"Delimiters" {
	    TeX::checkMathMode [join $itemName ""] 1
	    switch -- $itemName {
		"parentheses" {
		    TeX::delimitObject "(" ")¥¥"
		}
		"brackets" {
		    TeX::delimitObject "\[" "\]¥¥"
		}
		"braces" {
		    TeX::delimitObject "\\\{" "\\\}¥¥"
		}
		"vertical bars"  {
		    TeX::delimitObject "|" "|¥¥"
		}
		"other delims"  {
		    set delims [TeX::getDelims]
		    if {$delims != ""} {
			set leftDelim [lindex $delims 0]
			set rightDelim [lindex $delims 1]
			TeX::delimitObject "$leftDelim" "$rightDelim¥¥"
		    }
		}
		"half-open interval"  {
		    TeX::delimitObject "(" "\]¥¥"
		}
		"half-closed interval"  {
		    TeX::delimitObject "\[" ")¥¥"
		}
		"big parentheses"  {
		    TeX::insertBigDelims "\\left(" "\\right)¥¥" 0
		}
		"multi-line big parentheses"  {
		    TeX::insertBigDelims "\\left(" "\\right)¥¥" 1
		}
		"big brackets"  {
		    TeX::insertBigDelims "\\left\[" "\\right\]¥¥" 0
		}
		"multi-line big brackets"  {
		    TeX::insertBigDelims "\\left\[" "\\right\]¥¥" 1
		}
		"big braces"  {
		    TeX::insertBigDelims "\\left\\\{" "\\right\\\}¥¥" 0
		}
		"multi-line big braces"  {
		    TeX::insertBigDelims "\\left\\\{" "\\right\\\}¥¥" 1
		}
		"big vertical bars"  {
		    TeX::insertBigDelims "\\left|" "\\right|¥¥" 0
		}
		"multi-line big vertical bars"  {
		    TeX::insertBigDelims "\\left|" "\\right|¥¥" 1
		}
		"other big delims"  {
		    TeX::doOtherBigDelims "otherBigDelims" 0
		}
		"other multi-line big delims"  {
		    TeX::doOtherBigDelims "otherMultiBigDelims" 1
		}
		"big left brace"  {
		    TeX::insertBigDelims "\\left\\\{" "\\right.¥¥" 0
		}
		"multi-line big left brace"  {
		    TeX::insertBigDelims "\\left\\\{" "\\right.¥¥" 1
		}
		"other mixed big delims"  {
		    TeX::doOtherMixedBigDelims "otherMixedBigDelims" 0
		}
		"other multi-line mixed big delims"  {
		    TeX::doOtherMixedBigDelims "otherMultiMixedBigDelims" 1
		}
	    }
	}
	"Dots" - "Functions" - "Symbols" {
	    # workaround alpha menu bug
	    regsub "!." $itemName "" itemName
	    TeX::checkMathMode [join $itemName ""] 1
	    if {[lsearch -exact "mho Box Diamond" $itemName] != -1} {
		if {![TeX::requirePackage latexsym]} {return}
	    }
	    switch -- $itemName {
		"lim" - "inf" - "liminf" - "limsup" - "max" - "min" - "sup" {
		    if {[elec::Wrap "\\${itemName}_{" "}¥¥"]} {
			status::msg "limit set"
		    } else {
			status::msg "enter limit"
		    }
		}
		"pmod" {
		    if {[elec::Wrap "\\pmod{" "}¥¥"]} {
			status::msg "parenthesized mod set"
		    } else {
			status::msg "enter formula"
		    }
		}
		default {
		    TeX::insertObject "\\$itemName"
		}
	    }
	}
	"Environments" {
	    # Most of these are defined in "latexEnvironments"
	    switch -- $itemName {
		"Add Item"              {TeX::addItem}
		"Choose Environment"    {TeX::chooseEnvironment}
		"Add New Environment"   {TeX::addNewEnvironment}
		default                 {TeX::$itemName}
	    }
	}
	"Formulas" {
	    set openWrap  "\\${itemName}\{"
	    set closeWrap "\}¥¥"
	    set message1  "$itemName set"
	    set message2  "enter $itemName"
	    switch -- $itemName {
		"subscript" {
		    set openWrap "_\{"
		}
		"superscript" {
		    set openWrap "^\{"
		}
		"frac" {
		    TeX::checkMathMode "fraction" 1
		    set currentPos [getPos]
		    if {[isSelection]} {
			set selection [getSelect]
			set args [split $selection /]
			set len [llength $args]
			deleteText $currentPos [selEnd]
			if {$len == 1} {
			    TeX::insertObject "\\frac{$selection}{¥denominator¥}¥¥"
			    status::msg "enter denominator"
			} else {
			    set firstArg [lindex $args 0]
			    set restArgs [lrange $args 1 [expr $len-1]]
			    TeX::insertObject "\\frac{$firstArg}{[join $restArgs /]}"
			    if {$len > 2} {status::msg "beware of multiple /"}
			}
		    } else {
			TeX::insertObject "\\frac{¥numerator¥}{¥denominator¥}¥¥"
			status::msg "enter numerator"
		    }
		    return
		}
		"sqrt" {
		    set message1 "square root set"
		    set message2 "enter formula"
		}
		"nth root" {
		    set openWrap "\\sqrt\[¥root¥\]\{"
		    set message1 "enter root"
		    set message2 "enter root, then formula"
		}
		"one parameter" {
		    set openWrap "\\¥command name¥\{"
		    set message1 "enter command name"
		    set message2 "enter command name, press <Tab>, enter argument"
		}
		"two parameters" {
		    set openWrap  "\\¥command name¥\{"
		    set closeWrap "\}\{¥arguments¥\}¥¥"
		    set message1  "enter command name"
		    set message2  "enter command name, press <Tab>, enter argument, etc."
		}
	    }
	    if {[elec::Wrap $openWrap $closeWrap]} {
		status::msg $message1
	    } else {
		status::msg $message2
	    }
	}
	"Greek" {
	    TeX::checkMathMode [join $itemName ""] 1
	    TeX::insertObject "\\$itemName"
	}
	"Grouping" {
	    TeX::checkMathMode [join $itemName ""] 1
	    set openWrap  "\\${itemName}\{"
	    set closeWrap "\}¥¥"
	    set message1  "selection ${itemName}d"
	    set message2  "enter text"
	    switch -- $itemName {
		"overrightarrow" {
		    set message1 "selection overrightarrowed"
		}
		"overleftarrow" {
		    set message1 "selection overleftarrowed"
		}
		"stackrel" {
		    TeX::checkMathMode "stackrel" 1
		    set currentPos [getPos]
		    if {[TeX::insertObject "\\stackrel{¥argument¥}{¥¥}¥¥"]} {
			status::msg "1st arg scriptstyle"
		    }
		    return
		}
	    }
	    if {[elec::Wrap $openWrap $closeWrap]} {
		status::msg $message1
	    } else {
		status::msg $message2
	    }
	}
	"International" {
	    switch -- $itemName {
		""  {TeX::insertObject "\\c\{c\}"}
		"‚"  {TeX::insertObject "\\c\{C\}"}
		"Ï"  {TeX::insertObject "\\oe"}
		"Î"  {TeX::insertObject "\\OE"}
		"¾"  {TeX::insertObject "\\ae"}
		"®"  {TeX::insertObject "\\AE"}
		"Œ"  {TeX::insertObject "\\aa"}
		""  {TeX::insertObject "\\AA"}
		"¿"  {TeX::insertObject "\\o"}
		"¯"  {TeX::insertObject "\\O"}
		"ss" {TeX::insertObject "\\ss"}
		"SS" {TeX::insertObject "\\SS"}
		"À"  {TeX::insertObject "?`"}
		"Á"  {TeX::insertObject "!`"}
		"˜" - "—" - "™" - "š" - "›" {
		    set msg "enter single character"
		    switch -- $itemName {
			"˜" {set openWrap "\\`\{"}
			"—" {set openWrap "\\'\{"}
			"™" {set openWrap "\\^\{"}
			"š" {set openWrap "\\\"\{"}
			"›" {set openWrap "\\~\{"}
		    }
		    if {[elec::Wrap $openWrap "\}¥¥"]}  {
			status::msg "accent set"
		    } else {
			status::msg "enter single character"
		    }
		}
	    }
	}
	"Large Operators" {
	    TeX::checkMathMode [join $itemName ""] 1
	    TeX::insertObject  "\\$itemName\_{¥¥}^{¥¥}¥¥"
	}
	"Math Accents" {
	    TeX::checkMathMode [join $itemName ""] 1
	    switch -- $itemName {
		"widehat" - "widetilde" {
		    if {[string length [getSelect]] > 3} {
			alertnote "Warning: only a few characters may be accented!"
		    }
		    set msg "enter a few characters"
		}
		default {
		    if {[string length [getSelect]] > 1} {
			alertnote "Warning: only a single character may be accented!"
		    }
		    set msg "enter one character"
		}
	    }
	    if {[elec::Wrap "\\${itemName}\{" "\}¥¥"]} {
		status::msg "accent set"
	    } else {
		status::msg $msg
	    }

	}
	"Math Environments" {
	    switch -- $itemName {
		"displaymath" - "equation*" - "math" - "subequations" {
		    TeX::${itemName}
		}
		"Add Item"              {TeX::addItem}
		"Choose Environment"    {TeX::chooseEnvironment}
		"Add New Environment"   {TeX::addNewEnvironment}
		"equation"              {TeX::mathEnvironment $itemName}
		default                 {TeX::TeXmathenv $itemName}
	    }
	}
	"Math Modes" {
	    TeX::checkMathMode [join $itemName ""] 0
	    switch -- $itemName {
		"TeX math" {
		    if {[elec::Wrap "$" "$¥¥"]} {
			status::msg "formula set"
		    } else {
			status::msg "enter formula"
		    }
		}
		"TeX displaymath" {
		    if {[elec::Wrap "$$" "$$¥¥"]} {
			status::msg "displayed formula set"
		    } else {
			status::msg "enter displayed formula"
		    }
		}
		"LaTeX math" {
		    if {[elec::Wrap "\\( " " \\)¥¥"]} {
			status::msg "formula set"
		    } else {
			status::msg "enter formula"
		    }
		}
		"LaTeX displaymath" {
		    if {[elec::Wrap "\\\[ " " \\\]¥¥"]} {
			status::msg "displayed formula set"
		    } else {
			status::msg "enter displayed formula"
		    }
		}
	    }
	}
	"Math Style" {
	    set upper 0
	    regsub {^text}  $itemName "text "  description
	    regsub {style$} $itemName " style" description
	    switch -- $itemName {
		"mathbb"   {set description "math blackboard bold" ; set upper 1}
		"mathfrak" {set description "math fraktur"}
		"mathit"   {set description "math italic"}
		"mathrm"   {set description "math roman"}
		"mathbf"   {set description "math bold"}
		"mathsf"   {set description "math sans serif"}
		"mathtt"   {set description "math typewriter"}
		"mathcal"  {set description "math calligraphic"  ; set upper 1}
	    }
	    if {$upper} {
	        TeX::doUppercaseMathStyle $itemName $description
	    } else {
	        TeX::doMathStyle $itemName $description
	    }
	}
	"Miscellaneous" {
	    switch -- $itemName {
		"verb" {
		    if {[elec::Wrap "\\verb|" "|¥¥"]} {
			status::msg "verbatim text set"
		    } else {
			status::msg "enter verbatim text"
		    }
		}
		"footnote" {
		    if {[elec::Wrap "\\footnote{" "}¥¥"]} {
			status::msg "footnote set"
		    } else {
			status::msg "enter footnote"
		    }
		}
		"marginal note"  {
		    if {[elec::Wrap "\\marginpar{" "}¥¥"]} {
			status::msg "marginal note set"
		    } else {
			status::msg "enter marginal note"
		    }
		}
		"label" {
		    if {[elec::Wrap "\\label{" "}¥¥"]} {
			status::msg "label defined"
		    } else {
			status::msg "enter label"
		    }
		}
		"ref" {
		    TeX::checkMathMode [join $itemName ""] 1
		    if {[elec::Wrap "\\ref{" "}¥¥" 1]} {
			status::msg "reference made"
		    } else {
			status::msg "enter reference label"
		    }
		}
		"eqref" {
		    if {[elec::Wrap "\\eqref\{[TeX::labelPrefix eq]" "\}¥¥" 1]} {
			status::msg "reference made"
		    } else {
			status::msg "enter reference label"
		    }
		}
		"pageref" {
		    if {[elec::Wrap "\\pageref{" "}¥¥" 1]} {
			status::msg "page reference made"
		    } else {
			status::msg "enter page reference label"
		    }
		}
		"cite" {
		    if {[elec::Wrap "\\cite{" "}¥¥" 1]} {
			status::msg "citation made"
		    } else {
			status::msg "enter citation key"
		    }
		}
		"nocite" {
		    if {[elec::Wrap "\\nocite{" "}¥¥"]} {
			status::msg "citation added to the list"
		    } else {
			status::msg "enter citation key"
		    }
		}
		"item" {
		    # Now routed through "TeX::addItem"
		    return [TeX::addItem]
		    # This was the older version.
		    set TeXocr  [TeX::openingCarriageReturn]
		    set TeXccr  [TeX::closingCarriageReturn]
		    set command [eval getText [TeX::searchEnvironment]]
		    set environment [TeX::extractCommandArg $command]
		    switch $environment {
			"itemize"         {set text "\\item ¥¥"}
			"enumerate"       {set text "\\item ¥¥"}
			"description"     {set text "\\item\[¥¥\] ¥¥"}
			"thebibliography" {set text "\\bibitem{¥¥} ¥¥"}
			"document" - ""   {
			    status::msg "Could not find any surrounding\
			      environment in which to insert an item."
			    return
			}
			default {
			    status::msg "'Add Item' doesn't work in $environment\
			      environments"
			    return
			}
		    }
		    set pos [getPos]
		    # Indentation should mirror that of an existing \item
		    # (if it exists)
		    elec::Insertion ${TeXocr}${text}
		}
		"quotes" {
		    if {[elec::Wrap "`" "'¥¥"]} {
			status::msg "text quoted"
		    } else {
			status::msg "enter text"
		    }
		}
		"double quotes" {
		    if {[elec::Wrap "``" "''¥¥"]} {
			status::msg "text double quoted"
		    } else {
			status::msg "enter text"
		    }
		}
                "TeX logo"       {TeX::insertObject "\\TeX"}
                "LaTeX logo"     {TeX::insertObject "\\LaTeX"}
                "LaTeX2e logo"   {TeX::insertObject "\\LaTeXe"}
                "date"           {TeX::insertObject "\\today"}
                "dag"            {TeX::insertObject "\\dag"}
                "ddag"           {TeX::insertObject "\\ddag"}
                "section mark"   {TeX::insertObject "\\S"}
                "paragraph mark" {TeX::insertObject "\\P"}
                "copyright"      {TeX::insertObject "\\copyright"}
                "pounds"         {TeX::insertObject "\\pounds"}
                default          {TeX::$itemName}
            }
	}
	"Page Layout" {
	    set TeXocr [TeX::openingCarriageReturn]
	    set TeXccr [TeX::closingCarriageReturn]
	    switch -- $itemName {
		"maketitle" {
		    set searchString {\\document(class|style)(\[.*\])?\{.*\}}
		    set searchResult [search -s -n -f 1 -m 0 -i 1 -r 1 $searchString [minPos]]
		    if {[llength $searchResult] == 0} {
			status::msg "can\'t find \\documentclass or \\documentstyle"
		    } else {
			set searchPos [lindex $searchResult 1]
			set searchString {\\begin\{document\}}
			set searchResult [search -s -n -f 1 -m 0 -i 1 -r 1 $searchString $searchPos]
			if {[llength $searchResult] == 0} {
			    status::msg "can\'t find \\begin\{document\}"
			} else {
			    goto [lindex $searchResult 1]
			    set currentPos [getPos]
			    set txt "\r\r% Definition of title page:"
			    append txt "\r\\title\{"
			    append txt "\r\t¥title¥\r\}"
			    append txt "\r\\author\{"
			    append txt "\r\t¥¥\t% insert author(s) here"
			    append txt "\r\}"
			    append txt "\r\\date\{¥¥\}\t% optional"
			    append txt "\r\r\\maketitle"
			    elec::Insertion $txt
			}
		    }
		}
		"abstract" - "titlepage" {TeX::doWrapEnvironment $itemName}
		"pagestyle" - "thispagestyle" {
		    set styles [list "plain" "empty" "headings" "myheadings"]
		    set p {"Choose a pagestyle:"}
		    if {[catch {eval prompt $p "plain" "options:" $styles} pagestyleName]} {
			error "cancel"
		    }
		    TeX::insertObject "${TeXocr}\\${itemName}\{$pagestyleName\}${TeXccr}"
		}
		"pagenumbering" {
		    set styles [list "arabic" "roman" "Roman" "alph" "Alph"]
		    set p {"Choose a pagenumbering style:"}
		    if {[catch {eval prompt $p "arabic" "options:" $styles} pagenumberingStyle]} {
			error "cancel"
		    }
		    TeX::insertObject "${TeXocr}\\pagenumbering\{$pagenumberingStyle\}${TeXccr}"
		}
		"twocolumn" - "onecolumn" {
		    TeX::insertObject "${TeXocr}\\${itemName}${TeXccr}"
		}
	    }
	}
	"Relations" {
	    # workaround alpha menu bug
	    regsub "!." $itemName "" itemName
	    if {[lsearch -exact "join sqsubset sqsupset" $itemName] != -1} {
		if {![TeX::requirePackage latexsym]} {
		    return
		}
	    }
	    TeX::checkMathMode [join $itemName ""] 1
	    TeX::insertObject "\\$itemName"
	}
	"Sectioning" {
	    set TeXocr [TeX::openingCarriageReturn]
	    set TeXccr [TeX::closingCarriageReturn]
	    if {$itemName == "appendix"} {
		TeX::insertObject "${TeXocr}\\appendix${TeXccr}"
		return
	    } 
	    if {[regexp {([a-zA-Z]+) with label$} $itemName allofit secName]} {
		# We put quite a few template stops in here so that the user
		# can easily delete '%' or carriage returns or the default
		# label prefix etc ...  If there is (negative) user feedback
		# about this we could easily remove some of them.
	        regsub {(ter|tion|agraph)?$} $secName {} secLabel
		set secLabel [TeX::labelPrefix $secLabel]
		set openWrap  "${TeXocr}\\${secName}\{"
		set closeWrap "\}¥¥%\r¥¥\\label\{${secLabel}¥label¥\}¥¥${TeXccr}"
		set message1  "press <tab>, and the modify the label"
		set message2  "enter the $secName name, then press <tab> to enter the label"
	    } else {
		set openWrap  "${TeXocr}\\${itemName}\{"
		set closeWrap "\}\r¥¥${TeXccr}"
		set message1  "sectioning done"
		set message2  "enter the $itemName"
	    }
	    if [elec::Wrap $openWrap $closeWrap] {
		status::msg $message1
	    } else {
		status::msg $message2
	    }
	}
	"Spacing" {
	    TeX::checkMathMode "$itemName" 1
	    switch -- $itemName {
		"neg thin" {TeX::insertObject "\\!"}
		"thin"     {TeX::insertObject "\\,"}
		"medium"   {TeX::insertObject "\\:"}
		"thick"    {TeX::insertObject "\\;"}
		"hspace" {
		    if {[elec::Wrap "\\hspace{" "}¥¥"]} {
			status::msg "spacing set"
		    } else {
			status::msg "enter the desired horizontal spacing"
		    }
		}
		"vspace" {
		    if {[elec::Wrap "\\vspace{" "}¥¥"]} {
			status::msg "spacing set"
		    } else {
			status::msg "enter the desired horizontal spacing"
		    }
		}
		default {TeX::insertObject "\\$itemName"}
	    }
	}
	"Text Commands" {
	    switch -- $itemName {
		"textsuperscript" {
		    if {[elec::Wrap "\\textsuperscript{" "}¥¥"]} {
			status::msg "text superscripted"
		    } else {
			status::msg "enter superscripted text"
		    }
		}
		"textcircled" {
		    if {[elec::Wrap "\\textcircled{" "}¥¥"]} {
			status::msg "text circled"
		    } else {
			status::msg "enter circled text"
		    }
		}
		default {TeX::insertObject "\\$itemName"}
	    }
	}
	"Text Style"    {
	    switch -- $itemName {
		"emph" {
		    if {[elec::Wrap "\\emph{" "}¥¥"]} {
			status::msg "selected text has been emphasized"
		    } else {
			status::msg "enter text to be emphasized"
		    }
		}
		"underline" {
		    checkMathMode "underline" 1
		    if {[elec::Wrap "\\underline{" "}¥¥"]} {
			status::msg "selection underlined"
		    } else {
			status::msg "enter text"
		    }
		}
		"textup" {
		    if {[elec::Wrap "\\textup{" "}¥¥"]} {
			status::msg "selected text has upright shape"
		    } else {
			status::msg "enter text to have upright shape"
		    }
		}
		"textit" {
		    if {[elec::Wrap "\\textit{" "}¥¥"]} {
			status::msg "selected text has italic shape"
		    } else {
			status::msg "enter text to have italic shape"
		    }
		}
		"textsl" {
		    if {[elec::Wrap "\\textsl{" "}¥¥"]} {
			status::msg "selected text has slanted shape"
		    } else {
			status::msg "enter text to have slanted shape"
		    }
		}
		"textsc" {
		    if {[elec::Wrap "\\textsc{" "}¥¥"]} {
			status::msg "selected text has small caps shape"
		    } else {
			status::msg "enter text to have small caps shape"
		    }
		}
		"textmd" {
		    if {[elec::Wrap "\\textmd{" "}¥¥"]} {
			status::msg "selected text has been set in medium series"
		    } else {
			status::msg "enter text to be set in medium series"
		    }
		}
		"textbf" {
		    if {[elec::Wrap "\\textbf{" "}¥¥"]} {
			status::msg "selected text has been set in bold series"
		    } else {
			status::msg "enter text to be set in bold series"
		    }
		}
		"textrm" {
		    if {[elec::Wrap "\\textrm{" "}¥¥"]} {
			status::msg "selected text has been set with roman family"
		    } else {
			status::msg "enter text to be set using roman family"
		    }
		}
		"textsf" {
		    if {[elec::Wrap "\\textsf{" "}¥¥"]} {
			status::msg "selected text has been set with sans serif family"
		    } else {
			status::msg "enter text to be set using sans serif family"
		    }
		}
		"texttt" {
		    if {[elec::Wrap "\\texttt{" "}¥¥"]} {
			status::msg "selected text has been set with typewriter family"
		    } else {
			status::msg "enter text to be set using typewriter family"
		    }
		}
		"textnormal" {
		    if {[elec::Wrap "\\textnormal{" "}¥¥"]} {
			status::msg "selected text has been set with normal style"
		    } else {
			status::msg "enter text to be set using normal style"
		    }
		}
		"em" {
		    if {[elec::Wrap "{\\em " "}¥¥"]} {
			status::msg "emphasized text set"
		    } else {
			status::msg "enter text to be emphasized"
		    }
		}
		"upshape" {
		    if {[elec::Wrap "{\\upshape " "}¥¥"]} {
			status::msg "text set in upright shape"
		    } else {
			status::msg "enter text to be set in upright shape"
		    }
		}
		"itshape" {
		    if {[elec::Wrap "{\\itshape " "}¥¥"]} {
			status::msg "text set in italics shape"
		    } else {
			status::msg "enter text to be set in italics shape"
		    }
		}
		"slshape" {
		    if {[elec::Wrap "{\\slshape " "}¥¥"]} {
			status::msg "text set in slanted shape"
		    } else {
			status::msg "enter text to be set in slanted shape"
		    }
		}
		"scshape" {
		    if {[elec::Wrap "{\\scshape " "}¥¥"]} {
			status::msg "text set in small caps shape"
		    } else {
			status::msg "enter text to be set in small caps shape"
		    }
		}
		"mdseries" {
		    if {[elec::Wrap "{\\mdseries " "}¥¥"]} {
			status::msg "text set in medium series"
		    } else {
			status::msg "enter text to be set in medium series"
		    }
		}
		"bfseries" {
		    if {[elec::Wrap "{\\bfseries " "}¥¥"]} {
			status::msg "text set in bold series"
		    } else {
			status::msg "enter text to be set in bold series"
		    }
		}
		"rmfamily" {
		    if {[elec::Wrap "{\\rmfamily " "}¥¥"]} {
			status::msg "text set in roman family"
		    } else {
			status::msg "enter text to be set in roman family"
		    }
		}
		"sffamily" {
		    if {[elec::Wrap "{\\sffamily " "}¥¥"]} {
			status::msg "text set in sans serif family"
		    } else {
			status::msg "enter text to be set in sans serif family"
		    }
		}
		"ttfamily" {
		    if {[elec::Wrap "{\\ttfamily " "}¥¥"]} {
			status::msg "text set in typewriter family"
		    } else {
			status::msg "enter text to be set in typewriter family"
		    }
		}
		"normalfont" {
		    if {[elec::Wrap "{\\normalfont " "}¥¥"]} {
			status::msg "text set in normal style"
		    } else {
			status::msg "enter text to be set in normal style"
		    }
		}
	    }
	}
	"Text Size" {
	    if {[elec::Wrap "{\\$itemName " "}¥¥"]} {
		status::msg "$itemName text set"
	    } else {
		status::msg "enter $itemName text"
	    }
	}
	"Theorem" {
	    if {$itemName == "proofof"} {
		if {[TeX::wrapStructure "\\begin\{proofof\}\{¥¥\}" "" \
		  "\\end\{proofof\}\r¥¥"]} {
		    set msgText "selection wrapped, enter ref of proofof environment"
		} else {
		    set msgText "enter ref of proofof environment, press <tab>, enter the body of proofof environment"
		}
	    } else {
		switch -- $itemName {
		    "definition with label"  {
			set envName "definition"
			set envLabel [TeX::labelPrefix def]
		    }
		    "remark with label"  {
			set envName "remark"
			set envLabel [TeX::labelPrefix rem]
		    }
		    "lemma with label"  {
			set envName "lemma"
			set envLabel [TeX::labelPrefix lem]
		    }
		    "proposition with label"  {
			set envName "proposition"
			set envLabel [TeX::labelPrefix prop]
		    }
		    "theorem with label"  {
			set envName "theorem"
			set envLabel [TeX::labelPrefix thm]
		    }
		    "corollary with label"  {
			set envName "corollary"
			set envLabel [TeX::labelPrefix cor]
		    }
		    "claimno with label"  {
			set envName "claimno"
			set envLabel [TeX::labelPrefix claim]
		    }
		    default {
			set envName  $itemName
			set envLabel ""
		    }
		}
		if {$envLabel == ""} {
		    append begStruct "\\begin\{" $envName "\}"
		    append endStruct "\\end\{" $envName "\}\r¥¥"
		    if {[TeX::wrapStructure $begStruct "" $endStruct]} {
			set msgText "selection wrapped"
		    } else {
			set msgText "enter the body of $envName environment"
		    }
		} else {
		    append begStruct "\\begin\{" $envName "\}\\label\{" $envLabel "¥¥\}"
		    append endStruct "\\end\{" $envName "\}\r¥¥"
		    if {[TeX::wrapStructure $begStruct "" $endStruct]} {
			set msgText "selection wrapped, enter the label"
		    } else {
			set msgText "enter the label, press <tab>, enter the body of $envName environment"
		    }
		}
	    }
	    status::msg $msgText
	}
	default {error "Cancelled -- unknown menu name: $menuName"}
    }
}

#############################################################################
#
# Basic Commands
#
#############################################################################
# ×××× label returners ×××× #

proc TeX::labelPrefix {type} {
    global TeXmodeVars
    if {!$TeXmodeVars(useLabelPrefixes)} {
	return ""
    } else {
	return "${type}$TeXmodeVars(standardTeXLabelDelimiter)"
    }
}

proc TeX::labelString {type} {
    global TeXmodeVars
    if {$TeXmodeVars(useLabelPrefixes)} {
	return "\\label\{${type}$TeXmodeVars(standardTeXLabelDelimiter)¥¥\}"
    } else {
	return "\\label\{¥¥\}"
    }
}

#--------------------------------------------------------------------------
# ×××× Utilities: ××××
#--------------------------------------------------------------------------
#
# A keyboard-bound method of accessing menu commands.  Takes a list of menu
# items (i.e., the tail of a 'menu' command), the menu name (the argument
# of the '-n' switch) , and the name of a menu filter (the argument of the
# '-p' switch) as input, and displays these items in a list box.  If the
# chosen item is a menu command (as opposed to a submenu), it is passed to
# the menu filter; otherwise, 'TeX::chooseCommand' recursively calls itself
# until a menu command is chosen or the cancel button is pressed.
#

proc TeX::chooseCommand {menuItems {menuName ""} {menuFilterProc ""} {level 1}} {

    if {![string length $menuItems]} {return}
    watchCursor
    # Preprocess the list of menu items:
    foreach item $menuItems {
	regsub -all {[<!/].} $item {} item
	regsub -all {É}	$item {} item
	lappend	menOut $item
	if {[string match "menu*" $item]} {
	    if {[set ind [lsearch $item {-n}]] >= 0} {
		lappend	top "[lindex $item [incr ind]]:"
	    }
	} elseif {![string match "(*" $item]} {
	    lappend top $item
	}
    }
    # Present the menu items to the user:
    set res [listpick -p "Choose menu command (level $level):" $top]
    # Either execute a command or recurse on a submenu:
    if {[lsearch $menOut $res] >= 0}  {
	# Execute the command via the menu filter, if necessary:
	if {$menuFilterProc == ""} {
	    $res
	} else {
	    $menuFilterProc $menuName $res
	}
    } else {
	set res [string trimright $res {:}]
	foreach	item $menOut {
	    if {[lsearch $item $res] >= 0} {
		set menuItems [lindex $item end]
		# Determine the name of this submenu:
		if {[set ind [lsearch $item {-n}]] >= 0} {
		    set menuName [lindex $item [incr ind]]
		} else {
		    set menuName ""
		}
		# Determine the name of the menu filter for this submenu:
		if {[set ind [lsearch $item {-p}]] >= 0} {
		    set menuFilterProc [lindex $item [incr ind]]
		} else {
		    set menuFilterProc ""
		}
		return [TeX::chooseCommand $menuItems $menuName $menuFilterProc [incr level]]
	    }
	}
    }
}

# Contributed by Dominique 

proc TeX::chooseEnvironment {} {

    set environment [TeX::getEnvironment]
    switch -- $environment {
	"description" - "displaymath" - "enumerate" - "equation*" - 
	"figure" - "itemize" - "math" - "subequations" - 
	"table" - "tabular" - "thebibliography" {
	    TeX::$environment
	}
	"equation" {
	    TeX::mathEnvironment $environment
	}
	"align" - "align*" - "alignat" - "alignat*" - "aligned" - 
	"alignedat" - "array" - "bmatrix" - "Bmatrix" - "cases" - 
	"eqnarray" - "eqnarray*" - "flalign" - "flalign*" - "gather" -
	"gather*" - "gathered" - "matrix" - "multline" - "multline*" - 
	"pmatrix" - "smallmatrix" - "split" - "subarray" - "vmatrix" - 
	"Vmatrix" {
	    TeX::TeXmathenv $environment
	}
	"claim" - "claimno" - "claimno with label" - "corollary" - 
	"corollary with label" - "definition" - "definition with label" - 
	"lemma" - "lemma with label" - "proof" - "proofof" - 
	"proposition" - "proposition with label" - "remark" - 
	"remark with label" - "theorem" - "theorem with label" {
	    TeX::macroMenuProc Theorem $environment ""
	}
	"framebox" - "makebox" - "minipage" - "newsavebox" - "parbox" - 
	"raisebox" - "rule" - "savebox" - "sbox" - "usebox" {
	    # framebox, makebox, newsavebox, parbox, raisebox, rule, savebox,
	    # sbox, and usebox aren't really environments but, just in case,
	    # we can do better than default
	    TeX::macroMenuProc Boxes $environment ""
	}
	"Add Item" {
	    # if boxes can be here then why not Add Item? (sigh)
	    TeX::addItem
	}
	default {
	    # The environments covered here include: abstract, center,
	    # document, filecontents, flushleft, flushright, note, overlay,
	    # quote, quotation, slide, titlepage, verbatim, verse, and any
	    # otherwise unknown environment.
	    TeX::doWrapEnvironment $environment
	}
    }
    return
}

proc TeX::getEnvironment {} {

    global TeXmodeVars

    if {$TeXmodeVars(useAMSLaTeX)} {
	set environments [list \
	  "abstract" \
	  "align" \
	  "align*" \
	  "alignat" \
	  "aligned" \
	  "array" \
	  "bmatrix" \
	  "Bmatrix" \
	  "cases" \
	  "center" \
	  "claim" \
	  "claimno" \
	  "claimno with label" \
	  "corollary" \
	  "corollary with label" \
	  "definition" \
	  "definition with label" \
	  "description" \
	  "displaymath" \
	  "document" \
	  "enumerate" \
	  "eqnarray" \
	  "eqnarray*" \
	  "equation" \
	  "equation*" \
	  "figure" \
	  "filecontents" \
	  "flalign" \
	  "flalign*" \
	  "flushleft" \
	  "flushright" \
	  "gather" \
	  "gather*" \
	  "gathered" \
	  "itemize" \
	  "lemma" \
	  "lemma with label" \
	  "matrix" \
	  "math" \
	  "minipage" \
	  "multline" \
	  "multline*" \
	  "note" \
	  "overlay" \
	  "pmatrix" \
	  "proof" \
	  "proofof" \
	  "proposition" \
	  "proposition with label" \
	  "quotation" \
	  "quote" \
	  "remark" \
	  "remark with label" \
	  "slide" \
	  "smallmatrix" \
	  "split" \
	  "subarray" \
	  "subequations" \
	  "table" \
	  "tabular" \
	  "thebibliography" \
	  "theorem" \
	  "theorem with label" \
	  "titlepage" \
	  "verbatim" \
	  "verse" \
	  "vmatrix" \
	  "Vmatrix" ]
    } else {
	set environments [list \
	  "abstract" \
	  "array" \
	  "center" \
	  "description" \
	  "displaymath" \
	  "document" \
	  "enumerate" \
	  "eqnarray" \
	  "equation" \
	  "eqnarray*" \
	  "figure" \
	  "filecontents" \
	  "flushleft" \
	  "flushright" \
	  "itemize" \
	  "math" \
	  "minipage" \
	  "note" \
	  "overlay" \
	  "quotation" \
	  "quote" \
	  "slide" \
	  "table" \
	  "tabular" \
	  "thebibliography" \
	  "titlepage" \
	  "verbatim" \
	  "verse" ]
    }
    set p "Enter an environment, or choose an option below:"
    set environment [eval [list prompt $p abstract "options:"] $environments]
    if {![string length [string trim $environment]]} {
        alertnote "The \"environment\" cannot be an empty string!"
	return [TeX::getEnvironment]
    } else {
        return $environment
    }
}

# ×××× -------- ×××× #

#--------------------------------------------------------------------------
# ×××× Documents Support: ××××
#--------------------------------------------------------------------------

proc TeX::newLaTeXDocument {} {

    set classes [list "article" "report" "book" "letter" "slides"]
    set p {"Choose a documentclass:"}
    if {![catch {eval prompt $p "article" "classes:" $classes} documentType]} {
	new -m TeX
	if {[catch {TeX::${documentType}Documentclass}]} {
	    TeX::wrapDocument "$documentType"
	}
	set optionTypes [list "size" "paper" "landscape" "final" \
	  "side" "open" "column" "title" "leqno" "fleqn"]
	array set optionItems [list \
	  "size"        [list "10pt" "11pt" "12pt"] \
	  "paper"       [list "letterpaper" "legalpaper" "executivepaper" \
	  "a4paper" "a5paper" "b5paper"] \
	  "landscape"   [list "landscape"] \
	  "final"       [list "final" "draft"] \
	  "side"        [list "oneside" "twoside"] \
	  "open"        [list "openright" "openany"] \
	  "column"      [list "onecolumn" "twocolumn"] \
	  "title"       [list "notitlepage" "titlepage" "openbib"] \
	  "leqno"       [list "leqno"] \
	  "fleqn"       [list "fleqn"] \
	  ]
	set p "Choose an option, or press Cancel to complete."
	while {1} {
	    set options [list]
	    status::msg "Enter option (or leave blank)"
	    foreach optionType $optionTypes {
		eval [list lappend options] $optionItems($optionType) [list "\(-"]
	    }
	    set options [lrange $options 0 end-1]
	    set script [list "prompt" $p \
	      [lindex $options 0] \
	      "options:" \
	      ]
	    if {[catch {eval $script $options} option] \
	      || ![string length $option]} {
		break
	    }
	    TeX::insertOption $option
	    for {set idx 0} {($idx < [llength $optionTypes])} {incr idx} {
	        set optionType [lindex $optionTypes $idx]
		if {([lsearch $optionItems($optionType) $option] > -1)} {
		    set optionTypes [lreplace $optionTypes $idx $idx]
		    break
		} 
	    }
	    if {![llength $optionTypes]} {
	        break
	    } 
	    set p "Choose another option, or press Cancel to complete."
	}
    }
    status::msg "Finished."
    return
}

proc TeX::letterDocumentclass {} {

    set    preamble "\r\\address\{%\r"
    append preamble "	¥name¥	\\\\	¥¥% insert your name here\r"
    append preamble "	¥address¥	\\\\	¥¥% insert your address here\r"
    append preamble "	¥more address¥	\\\\	¥¥% insert more address here\r"
    append preamble "	¥city-state-zip¥	  	¥¥% insert city-state-zip here\r"
    append preamble "\}\r\r"
    append preamble "\\date\{¥¥\}  % optional\r"
    append preamble "\\signature\{¥¥\}\r\r"
    set    body     "\r\\begin\{letter\}\{%\r"
    append body     "	¥addressee's name¥	\\\\	¥¥% insert addressee's name here\r"
    append body     "	¥addressee's address¥	\\\\	¥¥% insert addressee's address here\r"
    append body     "	¥more addressee's address¥	\\\\	¥¥% insert more address here\r"
    append body     "	¥addressee's city-state-zip¥	  	¥¥% insert addressee's city-state-zip here\r"
    append body     "\}\r\r"
    append body     "\\opening\{Dear ¥addressee¥,\}\r\r"
    if {[TeX::isEmptyFile]} {
	append body "% BODY OF LETTER\r"
	append body "¥body of letter¥\r\r"
    } elseif {[TeX::isSelectionAll]} {
	set text [getSelect]
	# deleteText [minPos] [maxPos]
	append body "$text\r"
    } else {
	alertnote "nonempty file:  delete text or \'Select All\'\
	  from the Edit menu"
	return
    }
    append body "\\closing\{Sincerely,\}\r\r"
    append body "\\encl\{¥enclosure¥\}\r"
    append body "\\cc\{¥cc¥\}\r\r"
    append body "\\end\{letter\}\r\r"
    TeX::insertDocument "letter" $preamble $body
    status::msg "enter option (or leave blank)"
}

proc TeX::articleDocumentclass {} {

    if {[TeX::wrapDocument "article"]} {
	status::msg "enter option (or leave blank)"
    }
}
proc TeX::reportDocumentclass {} {

    if {[TeX::wrapDocument "report"]} {
	status::msg "enter option (or leave blank)"
    }
}
proc TeX::bookDocumentclass {} {

    if {[TeX::wrapDocument "book"]} {
	status::msg "enter option (or leave blank)"
    }
}
proc TeX::slidesDocumentclass {} {

    if {[TeX::wrapDocument "slides"]} {
	status::msg "enter option (or leave blank)"
    }
}
proc TeX::otherDocumentclass {} {

    catch {prompt "What documentclass?" "article"} documentType
    if {$documentType != "cancel"} {
	if {[TeX::wrapDocument "$documentType"]} {
	    status::msg "enter option (or leave blank)"
	}
    }
}

# ===========================================================================
# 
# CODE TAGGED FOR REMOVAL
# 
# These are now obsolete, retained for back compatibility until confirmed
# that they aren't called from anywhere.

# If an option is inserted, return true; otherwise, return false.

proc TeX::options {} {

    set option [TeX::getOption]
    if {$option != "" && $option != "cancel"} {
	TeX::insertOption $option
	return 1
    }
    return 0
}

proc TeX::getOption {} {

    set options [list \
      "10pt" "11pt" "12pt" "(-" \
      "letterpaper" "legalpaper" "executivepaper" "a4paper" "a5paper" \
      "b5paper" "(-" "landscape" "(-" "final" "draft" "(-" \
      "oneside" "twoside" "(-" "openright" "openany" "(-" \
      "onecolumn" "twocolumn" "(-" "notitlepage" "titlepage" \
      "openbib" "(-" "leqno" "(-" "fleqn"]
    set p {"Choose an option:"}
    if {![catch {eval prompt $p "11pt" options: $options} option]} {
	return $option
    } else {
	return ""
    }
}

# 
# END OF CODE TAGGED FOR REMOVAL
# 
# ===========================================================================

proc TeX::insertOption {option} {

    global TeXmodeVars

    set searchString {\\documentclass}
    set searchResult [search -s -n -f 1 -m 0 -i 1 -r 1 $searchString [minPos]]
    if {[llength $searchResult] == 0} {
	status::msg "can\'t find \\documentclass"
    } else {
	set nextCharPos [lindex $searchResult 1]
	goto $nextCharPos
	set nextChar [lookAt $nextCharPos]
	if {$nextChar == "\["} {
	    forwardChar
	    insertText $option
	    if {[lookAt [getPos]] != "\]"} {
		insertText ","
	    }
	} elseif {$nextChar == "\{"} {
	    insertText "\[$option\]"
	} else {
	    alertnote "unrecognizable \\documentclass statement"
	}
    }
}

proc TeX::insertPackage {package} {

    global TeXmodeVars

    # Check to see if $package is already loaded:
    if {$package != ""} {
	append searchString {^[^%]*\\usepackage\{.*} $package {.*\}}
	set searchResult [search -s -n -f 1 -m 0 -i 1 -r 1 $searchString [minPos]]
	if {[llength $searchResult] != 0} {
	    status::msg "$package package already loaded"
	    return
	}
    }
    # Newlines are allowed in the arguments of \documentclass:
    set searchString {\\documentclass(\[[^][]*\])?{[^{}]*}}
    # Search for \documentclass command:
    set searchResult [search -s -n -f 1 -m 0 -i 1 -r 1 $searchString [minPos]]
    if {[llength $searchResult] == 0} {
	status::msg "can't find \\documentclass"
    } else {
	placeBookmark
	goto [lindex $searchResult 1]
	set txt "\r\\usepackage\{$package\}"
	insertText $txt
	backwardChar
	status::msg "Press <Ctl .> to return to previous position"
    }
}

proc TeX::filecontents {} {

    set searchString {\\documentclass}
    set searchResult [search -s -n -f 1 -m 0 -i 1 -r 1 $searchString [minPos]]
    if {[llength $searchResult] == 0} {
	status::msg "can\'t find \\documentclass"
	return
    } else {
	set prompt "File to be included:"
	if {[catch {getfile $prompt} path]} {
	    return
	} else {
	    replaceText [minPos] [minPos] [TeX::buildFilecontents $path]
	    goto [minPos]
	    status::msg "file included"
	}
    }
}

proc TeX::filecontentsAll {} {

    watchCursor
    status::msg "locating all input filesÉ"
    set currentWin [win::Current]
    # Is the current window part of TeX fileset?
    set fset [isWindowInFileset $currentWin "tex"]
    if {$fset == ""} {
	set searchString {\\documentclass}
	set searchResult [search -s -n -f 1 -m 0 -i 1 -r 1 $searchString [minPos]]
	if {[llength $searchResult] == 0} {
	    status::msg "can\'t find \\documentclass"
	    return
	} else {
	    set text [getText [minPos] [maxPos]]
	}
    } else {
	# Will not handle a base file that is open and dirty:
	set text [TeX::buildFilecontents [texFilesetBaseName $fset]]
    }
    set currentDir [file dirname $currentWin]
    set newText [TeX::resolveAll $text $currentDir]
    if {[string length $text] == [string length $newText]} {
	beep
	status::msg "no files to include"
    } else {
	replaceText [minPos] [maxPos] $newText
	goto [minPos]
	status::msg "all files included"
    }
}
# Takes a LaTeX document string and a path as input, and returns a modified
# document string with all filecontents environments prepended.

proc TeX::resolveAll {latexDoc currentDir} {

    global TeXmodeVars

    set pairs [list \
      {{\\documentclass} {.cls}} {{\\LoadClass} {.cls}} \
      {{\\include} {.tex}} \
      {{\\usepackage} {.sty}} {{\\RequirePackage} {.sty}} \
      {{\\input} {}} \
      {{\\bibliography} {.bib}} {{\\bibliographystyle} {.bst}} \
      ]
    foreach macro $TeXmodeVars(boxMacroNames) {
	regsub {\*} $macro {\\*} macro
	lappend pairs [list \\\\$macro {}]
    }
    foreach pair $pairs {
	set cmd [lindex $pair 0]
	set ext [lindex $pair 1]
	set searchString $cmd
	append searchString {(\[[^][]*\])?{([^{}]*)}}
	set searchText $latexDoc
	while {[regexp -indices -- $searchString $searchText mtch dummy theArgs]} {
	    set begPos [lindex $theArgs 0]
	    set endPos [lindex $theArgs 1]
	    set args [string range $searchText $begPos $endPos]
	    foreach arg [split $args ,] {
		if {$cmd == {\\input} && ![string length [file extension $arg]]} {
		    set ext {.tex}
		}
		set files [glob -nocomplain -path [file join $currentDir $arg] *]
		set filename [file join $currentDir $arg$ext]
		if {[lsearch -exact $files $filename] > -1} {
		    set tempDoc $latexDoc
		    set latexDoc [TeX::buildFilecontents $filename]
		    append latexDoc $tempDoc
		}
	    }
	    set searchText [string range $searchText [expr $endPos + 2] end]
	}
    }
    return $latexDoc
}
# Takes a filename as input and returns a filecontents environment based on
# the contents of that file.  If a second argument is given, use that as
# the argument of the filecontents environment instead of the original
# filename.

proc TeX::buildFilecontents {filename {newFilename {}}} {

    set text [file::readAll $filename]
    # Fix end-of-line characters:
    regsub -all "\xa" $text "\xd" text
    set envName "filecontents"
    if {$newFilename == {}} {
	set envArg "{[file tail $filename]}"
    } else {
	set envArg "{$newFilename}"
    }
    return [TeX::buildEnvironment $envName $envArg "$text\r" "\r\r"]
}

#--------------------------------------------------------------------------
# ×××× Math Style Support ××××
#--------------------------------------------------------------------------

proc TeX::doMathStyle {mathStyle description} {

    TeX::checkMathMode "$mathStyle" 1
    if {[elec::Wrap "\\$mathStyle{" "}¥¥"]} {
	status::msg "selected text is $description"
    } else {
	status::msg "enter text to be $description"
    }
}

proc TeX::doUppercaseMathStyle {mathStyle description} {

    TeX::checkMathMode "$mathStyle" 1
    # Allow upper-case alphabetic arguments only:
    if {[isSelection] && (![TeX::isUppercase] || ![TeX::isAlphabetic])} {
	beep
	alertnote "argument to \\$mathStyle must be UPPERCASE alphabetic"
	return
    }
    if {[elec::Wrap "\\$mathStyle{" "}¥¥"]} {
	status::msg "selected text is $description"
    } else {
	status::msg "enter text to be $description (UPPERCASE letters only)"
    }
}

#--------------------------------------------------------------------------
# ×××× Delimiters Support ××××
#--------------------------------------------------------------------------

proc TeX::delimitObject {leftDelim rightDelim} {

    if {[elec::Wrap $leftDelim $rightDelim]} {
	status::msg "formula delimited"
    } else {
	status::msg "enter formula"
    }
}

proc TeX::getDelims     {} {

    catch {prompt "Choose delimiters:" "parentheses" "" "parentheses" \
      "brackets" "braces" "angle brackets" "vertical bars" \
      "double bars" "ceiling" "floor"} delimType
    if {$delimType != "cancel"} {
	switch $delimType {
	    "parentheses" {
		set leftDelim  "("
		set rightDelim ")"
	    }
	    "brackets" {
		set leftDelim  "\["
		set rightDelim "\]"
	    }
	    "braces" {
		set leftDelim  "\\\{"
		set rightDelim "\\\}"
	    }
	    "vertical bars" {
		set leftDelim  "|"
		set rightDelim "|"
	    }
	    "double bars" {
		set leftDelim  "\\|"
		set rightDelim "\\|"
	    }
	    "angle brackets" {
		set leftDelim  "\\langle"
		set rightDelim "\\rangle"
	    }
	    "ceiling" {
		set leftDelim  "\\lceil"
		set rightDelim "\\rceil"
	    }
	    "floor" {
		set leftDelim  "\\lfloor"
		set rightDelim "\\rfloor"
	    }
	    default {
		alertnote "\"$delimType\" not recognized"
		return ""
	    }
	}
	return [list $leftDelim $rightDelim]
    } else {
	return ""
    }
}

proc TeX::insertBigDelims {leftDelim rightDelim isMultiline} {

    TeX::checkMathMode "insertBigDelims" 1
    if {$isMultiline} {
	TeX::doWrapStructure $leftDelim "" $rightDelim
    } else {
	if {[elec::Wrap $leftDelim $rightDelim]} {
	    status::msg "formula delimited"
	} else {
	    status::msg "enter formula"
	}
    }
}

proc TeX::doOtherBigDelims {name isMultiline} {

    TeX::checkMathMode $name 1
    set delims [TeX::getDelims]
    if {$delims != ""} {
	append leftDelim "\\left" [lindex $delims 0]
	append rightDelim "\\right" [lindex $delims 1]
	TeX::insertBigDelims "$leftDelim" "$rightDelim¥¥" $isMultiline
    }
}

proc TeX::doOtherMixedBigDelims {name isMultiline} {

    TeX::checkMathMode $name 1
    catch {prompt "Choose LEFT delimiter:" "parenthesis" "" "parenthesis" \
      "bracket" "brace" "vertical bar" "double bar" \
      "angle bracket" "ceiling" "floor" "slash" "backslash" \
      "none"} delimType
    if {$delimType != "cancel"} {
        switch $delimType {
            "parenthesis"       {set leftDelim "("}
            "bracket"           {set leftDelim "\["}
            "brace"             {set leftDelim "\\\{"}
            "vertical bar"      {set leftDelim "|"}
            "double bar"        {set leftDelim "\\|"}
            "angle bracket"     {set leftDelim "\\langle"}
            "ceiling"           {set leftDelim "\\lceil"}
            "floor"             {set leftDelim "\\lfloor"}
            "slash"             {set leftDelim "/"}
            "backslash"         {set leftDelim "\\backslash"}
            "none"              {set leftDelim "."}
            default {
                alertnote "\"$delimType\" not recognized"
                return
            }
        }
        catch {prompt "Choose RIGHT delimiter:" "parenthesis" "" "parenthesis" \
          "bracket" "brace" "vertical bar" "double bar" \
          "angle bracket" "ceiling" "floor" "slash" "backslash" \
          "none"} delimType
        if {$delimType != "cancel"} {
            switch $delimType {
                "parenthesis"   {set rightDelim ")"}
                "bracket"       {set rightDelim "\]"}
                "brace"         {set rightDelim "\\\}"}
                "vertical bar"  {set rightDelim "|"}
                "double bar"    {set rightDelim "\\|"}
                "angle bracket" {set rightDelim "\\rangle"}
                "ceiling"       {set rightDelim "\\rceil"}
                "floor"         {set rightDelim "\\rfloor"}
                "slash"         {set rightDelim "/"}
                "backslash"     {set rightDelim "\\backslash"}
                "none"          {set rightDelim "."}
                default {
                    alertnote "\"$delimType\" not recognized"
                    return
                }
            }
            TeX::insertBigDelims "\\left$leftDelim" "\\right$rightDelim¥¥" $isMultiline
        }
    }
}

# ==========================================================================
#
# .