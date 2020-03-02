## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "AlphaTclCompletions.tcl"
 #                                          created: 07/31/1997 {03:01:54 pm}
 #                                      last update: 04/18/2006 {12:02:13 PM}
 # Description:
 # 
 # Provides additional electric completion support in Tcl mode for core
 # Alpha* commands, as well as many AlphaTcl procs that take "args" as a
 # single argument but actually require a specific syntax.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 # 
 # Copyright (c) 2003-2006 Craig Barton Upright
 # All rights reserved.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # ==========================================================================
 ##

proc AlphaTclCompletions.tcl {} {
    alphadev::defineAlphaCoreElectrics
    alphadev::defineAlphaTclElectrics
}

namespace eval alphadev {}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::defineAlphaCoreElectrics"  --
 # 
 # Define electric completions for core Alpha* commands.
 # 
 # The completions for [alert], [dialog], [edit] and [new] are rather
 # cumbersome, due to the wealth of optional arguments.  For this very
 # reason, however, it is really handy to have them listed with the
 # betterTemplates package activated.  Also, [edit] and [new] might need to
 # be updated frequently when additional options are added.
 # 
 # --------------------------------------------------------------------------
 ## 

proc alphadev::defineAlphaCoreElectrics {} {
    
    global Tclelectrics

    array set Tclelectrics {
	abbreviateText          " ¥font¥ ¥string¥ ¥width¥"
	addAlphaChars           " ¥chars¥"
	addHelpMenu             " ¥item¥"
	addMenuItem             " ¥?-m?¥ ¥?-l meta-characters?¥ ¥menu-name¥\
	  ¥item-name¥"
	alert                   " ¥?-t stop|caution|note|plain?¥ ¥?-k okText?¥\
	  ¥?-c cancelText?¥ ¥?-o otherText?¥  ¥?-h?¥ ¥?-K ok|cancel|other|help?¥\
	  ¥?-C ok|cancel|other|help|none?¥ ¥error_string¥ ¥?explanation_string?¥"
	alertnote               " ¥message¥"
	ascii                   " ¥ascii-char¥ <¥?modifier?¥>\
	  \{¥script¥\} ¥?mode?¥"
	askyesno                " ¥?-c?¥ ¥prompt¥"
	beep                    " ¥?-volume num?¥ ¥?-list | sndName?¥?"
	Bind                    " '¥char¥' <¥?modifier?¥>\
	  \{¥script¥\} ¥?mode?¥"
	blink                   " ¥pos¥"
	breakIntoLines          " ¥string¥"
	bringToFront            " ¥winName¥"
	buttonAlert             " ¥prompt¥ ¥button¥ ¥?button? ...¥"
	colorTriple             " ¥?prompt?¥ ¥?red green blue?¥"
	createTMark             " ¥?-w window?¥ ¥name¥ ¥pos¥"
	deleteMenuItem          " ¥?-m?¥ ¥menu-name¥ ¥item-name¥"
	deleteModeBindings      " ¥mode¥"
	deleteText              " ¥?-w window?¥ ¥pos1¥ ¥pos2¥"
	dialog                  " ¥?-w width?¥ ¥?-h height?¥\
	  ¥?-b title l t r b?¥ ¥?-c title val l t r b?¥\
	  ¥?-t text l t r b?¥ ¥?-e text l t r b?¥\
	  ¥?-r text val l t r b?¥ ¥?-p l t r b?¥"
	display                 " ¥?-w window?¥ ¥pos¥"
	displayMode             " ¥mode¥"
	echo                    " ¥string¥"
	edit                    " ¥?-r?¥ ¥?-c?¥ ¥?-w?¥ ¥?-mode val?¥\
	  ¥?-encoding val?¥ ¥?-tabsize val?¥  ¥?-g l t w h?¥ ¥?--?¥ ¥name¥"
	enableMenuItem          " ¥?-m?¥ ¥menuName¥ ¥item-text¥ ¥on|off¥"
	findFile                " ¥?path?¥"
	float                   " -m ¥menu¥ ¥?<-h|-w|-l|-t|-M> val?¥\
	  ¥?-n winname?¥ ¥?-z tag?¥ -"
	floatShowHide           " ¥on|off¥ ¥tag¥"
	getControlInfo          " ¥dialogItemId¥ ¥attribute¥"
	getControlValue         " ¥dialogItemId¥"
	getGeometry             " ¥?win?¥"
	getNamedMarks           " ¥?-w window?¥ ¥?-n?¥"
	getPos                  " ¥?-w window?¥"
	getText                 " ¥?-w window?¥ ¥pos1¥ ¥pos2¥"
	getWinInfo              " ¥?-w window?¥ ¥arr¥"
	get_directory           " ¥?-p prompt?¥ ¥?default?¥"
	getfile                 " ¥?prompt?¥ ¥?path?¥"
	getline                 " ¥prompt¥ ¥default¥"
	goto                    " ¥?-w window?¥ ¥pos¥"
	gotoMark                " ¥?-w window?¥ ¥name¥"
	gotoTMark               " ¥?-w window?¥ ¥name¥"
	icGetPref               " ¥?<-t type?¥ ¥pref-name¥"
	icon                    " ¥?-f winName?¥ ¥?-c|-o|-t|-q?¥ ¥?-g h v?¥"
	insertMenu              " ¥name¥"
	insertText              " ¥?-w window?¥ ¥text*¥"
	launch                  " -f ¥name¥"
	lineStart               " ¥?-w window?¥ ¥pos¥"
	listpick                " ¥?-p prompt?¥ ¥?-l?¥ ¥?-L def-list?¥ ¥list¥"
	lookAt                  " ¥?-w window?¥  ¥pos¥"
	markMenuItem            " ¥?-m?¥ ¥menuName¥ ¥item-text¥ ¥on|off¥\
	  ¥?mark-char?¥"
	matchIt                 " ¥?-w window?¥ ¥brace-char¥ ¥pos¥ ¥?limit?¥"
	maxPos                  " ¥?-w window?¥"
	Menu                    " ¥?-i <num?¥ ¥?-m?¥ ¥?-M mode?¥\
	  ¥?-n <name|num>?¥ ¥?-p procname?¥ ¥?-s?¥ ¥list¥"
	moveInsertionHere       " ¥?-w window?¥ ¥?-last?¥"
	moveWin                 " ¥?window?¥ ¥left¥ ¥top¥"
	nameFromAppl            " '¥app-sig¥'"
	new                     " ¥?-g l t w h?¥ ¥?-tabsize val?¥\
	  ¥?-mode val?¥ ¥?-dirty val?¥ ¥?-shell val?¥ ¥?-info val?¥ ¥?-n name?¥"
	nextLineStart           " ¥?-w window?¥ ¥pos¥"
	prompt                  " ¥prompt¥ ¥default¥ ¥?name? ?menu-item?¥"
	putScrap                " ¥string¥ ¥?string string...?¥"
	putfile                 " ¥prompt¥ ¥original¥"
	regModeKeywords         " ¥?options?¥ ¥mode¥ ¥keyword-list¥"
	removeMenu              " ¥name¥"
	removeNamedMark         " ¥?-w window?¥ ¥?-n name?¥"
	removeTMark             " ¥?-w window?¥ ¥name¥"
	replaceString           " ¥?str?¥"
	replaceText             " ¥?-w window?¥ ¥pos1¥ ¥pos2¥ ¥?text?+¥"
	revert                  " ¥?-w window?¥"
	saveAs                  " ¥?-f?¥ ¥?def name?¥"
	search                  " ¥?-w window?¥ ¥?options ...?¥ ¥pattern¥ ¥pos¥"
	searchString            " ¥?str?¥"
	selEnd                  " ¥?-w window?¥"
	select                  " ¥?-w window?¥ ¥pos1¥ ¥pos2¥"
	setControlInfo          " ¥dialogItemId¥ ¥attribute¥ ¥value¥"
	setControlValue         " ¥dialogItemId¥ ¥value¥"
	setNamedMark            " ¥?-w window?¥ ¥?name disp pos end?¥"
	setPin                  " ¥?-w window?¥ ¥?pos¥"
	setWinInfo              " ¥?-w window?¥ ¥field¥ ¥arg¥"
	sizeWin                 " ¥?window?¥ ¥width¥ ¥height¥"
	toggleSplitWindow       " ¥?-w window?¥ ¥?percent?¥"
	status::msg             " ¥string¥"
	statusPrompt            " ¥prompt¥ ¥?func?¥"
	switchTo                " ¥appName¥"
	unBind                  " '¥char¥' <¥?modifier?¥>\
	  \{¥script¥\} ¥?mode?¥"
	unascii                 " ¥ascii-char¥ <¥?modifier?¥>\
	  \{¥script¥\} ¥?mode?¥"
	unfloat                 " ¥float-num¥"
	wc                      " ¥file ?file ...?¥"
	winNames                " ¥?-f?¥"
    }
    # These all take a single optional ?-w window? argument.
    set wOptionCommands {
	backSpace backwardChar backwardCharSelect backwardDeleteWord
	backwardWord backwardWordSelect balance beginningBufferSelect
	beginningLineSelect beginningOfBuffer beginningOfLine
	capitalizeRegion capitalizeWord clear copy cut deleteChar
	deleteSelection deleteWord downcaseWord
	endBufferSelect endLineSelect endOfBuffer endOfLine
	exchangePointAndPin forwardChar forwardCharSelect forwardWord
	forwardWordSelect getPin getPos getSelect hiliteToPin insertToTop
	killLine killWindow lineStart maxPos minPos nextLine nextLineSelect
	nextLineStart oneSpace openLine pageBack pageForward
	paste prevLineSelect previousLine
	rectangularHiliteToPin scrollDownLine scrollLeftCol scrollRightCol
	scrollUpLine toggleSplitWindow tab upcaseWord 
	yank zapNonPrintables
    }
    foreach command $wOptionCommands {
	set Tclelectrics($command) " ¥?-w window?¥"
    }
    # Add global namespace electrics.
    foreach command $::alphaKeyWords {
	if {[info exists Tclelectrics($command)]} {
	    set Tclelectrics(::$command) $Tclelectrics($command)
	}
    }
}

## 
 # --------------------------------------------------------------------------
 # 
 # "alphadev::defineAlphaTclElectrics"  --
 # 
 # Define electric completions for AlphaTcl core procs.
 # 
 # There are many AlphaTcl procedures which accept a single 'args' arg, but
 # actually require a very specific syntax.  Many of these procs parse the
 # args through [win::parseArgs].  This procedure will define more useful
 # electric completions for Tcl mode, and will probably have to be updated
 # with some frequency.
 # 
 # --------------------------------------------------------------------------
 ## 

proc alphadev::defineAlphaTclElectrics {} {
    
    global Tclelectrics alphaObsProcs alphaObsCommands
    
    # Some handy shortcuts.
    array set shortcuts {
	WN {¥?-w window?¥}
	GP {¥?pos? ([getPos] is default)¥}
	SE {¥?pos? ([selEnd] is default)¥}
	P0 {¥?pos0? ([getPos] is default)¥}
	P1 {¥?pos1? ([selEnd] is default)¥}
    }
    
    # ×××× "positions.tcl" ×××× #
    array set posElectrics {
	"pos::min"                      " ¥WN¥"
	"pos::max"                      " ¥WN¥"
	"pos::lineStart"                " ¥WN¥ ¥GP¥"
	"pos::nextLineStart"            " ¥WN¥ ¥SE¥"
	"pos::prevLineStart"            " ¥WN¥ ¥GP¥"
	"pos::lineEnd"                  " ¥WN¥ ¥SE¥"
	"pos::nextLineEnd"              " ¥WN¥ ¥SE¥"
	"pos::prevLineEnd"              " ¥WN¥ ¥GP¥"
	"pos::nextChar"                 " ¥WN¥ ¥SE¥"
	"pos::prevChar"                 " ¥WN¥ ¥GP¥"
	"pos::nextLine"                 " ¥WN¥ ¥SE¥"
	"pos::prevLine"                 " ¥WN¥ ¥GP¥"
    }
    
    # ×××× Obsolete Procs/Commands ×××× #
    foreach procName $alphaObsProcs {
	set procName [string trimleft $procName ":"]
	set msg    "'$procName' is an obsolete proc.  Press F6 for details."
	set script "backwardWordSelect ; alertnote \"$msg\" ; error cancel"
	set electric "×\[$script\]"
	set obsProcElectrics($procName) $electric
    } 
    foreach command $alphaObsCommands {
	set command [string trimleft $command ":"]
	set msg    "'$command' is an obsolete command.  Press F6 for details."
	set script "backwardWordSelect ; alertnote \"$msg\" ; error cancel"
	set electric "×\[$script\]"
	set obsCommandElectrics($command) $electric
    }

    # Now we clean up and define the electrics.
    foreach arrayName [info locals *Electrics] {
	foreach item [array names $arrayName] {
	    set electric [set [set arrayName]($item)]
	    foreach shortcut [array names shortcuts] {
		set elecArg $shortcuts($shortcut)
		regsub -- "¥${shortcut}¥" $electric $elecArg electric
	    }
	    set Tclelectrics($item)   $electric
	    set Tclelectrics(::$item) $electric
	}
    }
}

# ===========================================================================
# 
# .