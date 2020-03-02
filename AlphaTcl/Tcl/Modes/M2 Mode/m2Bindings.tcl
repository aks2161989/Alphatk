# to autoload this file (tabsize:4)
proc m2Bindings.tcl {} {}

#===========================================================================
# ×××× M2 KEY BINDINGS ×××× #
#===========================================================================
# <s> stands for Shift   (<U see menu)
# <z> stands for Control (<B see menu)
# <o> stands for Option  (<I see menu)
# <c> stands for Command (<O see menu)
# <e> stands for ESC
# Use menu Utils > Ascii Etc > Key Code to learn the coding of a particular key
 
# Global, basic M2 bindings needed at all times to open work object and launching
# Need to be active even if no file with M2 specific extensions is currently open!
# --------------------------------------------------------------------------------


namespace eval M2 {}



# --------------------------------------------------------------------------------
# ×××× M2 Global KEY BINDINGS ×××× #
# --------------------------------------------------------------------------------

if {![info exists M2firstInitForBindings] && !$M2modeVars(globalM2Bindings)} {
	if {[alpha::package exists globalM2Bindings]} {
		# ask this only once after a virgin installation of Alpha (or discard of
		# Alpha-v7 or Alpha-v8 preferences)
		set M2firstInitForBindings 1
		prefs::modified M2firstInitForBindings
		# The first time that M2 is ever used, we ask if we want to make
		# the bindings global the next time Alpha is restarted.
		if {[askyesno "Would you like to activate the related global feature \
		  'Global M2 Bindings' for opening M2 files and launching shells?"] == "yes"} {
			# actually the following only turns on the M2 internal preference 
			# not yet the global feature, which should be used to really control
			# global bindings
			set M2modeVars(globalM2Bindings) "1"
			prefs::modified M2modeVars(globalM2Bindings)
			if {[alpha::package exists "globalM2Bindings"]} {
				# alertnote "package exists"
				# This turns the global feature on
				if {![package::active "globalM2Bindings"]} {
					package::makeOnOrOff "globalM2Bindings" "basic-on" "global"
				}
			}
		}
    }
} 




# Make sure the code of M2::setGlobalBindings is consistent with what's done in
# m2Mode.tcl for the basic mode activation script (see alpha::mode M2 ...  )
proc M2::setGlobalBindings {} {
	global M2modeVars
	# alertnote "in M2::setGlobalBindings"
	if {[info exists M2modeVars(globalM2Bindings)]} {
		if {$M2modeVars(globalM2Bindings)} {
			# define them now globally. You get here typically by global feature
			# globalM2bindings (see globalM2bindings.tcl) which is installed
			# as an independent package.
			# 
			# Open current set of Modula-2 working files, the ones latest compiled 
			# in case the compiler errors detected errors. Otherwise open just the last compiled. 
			# (Ctrl^0)
			Bind '0'  <z> M2::openWorkFiles
			# Launch the Modula-2 shell as configured (M2modeVars(m2_shellName) or M2ShellName)
			# Plus send it a high level event to launch a simulation (recognized by Mini RAMSES Shell)
			Bind '1'  <z> M2::launchShellAndSimulate
			# Launch the Modula-2 shell as configured (M2modeVars(m2_shellName) or M2ShellName) without sending any events
			Bind '2'  <z> M2::launchShell
		} else {
			# at least define these bindings for M2 mode:
			Bind '0'  <z> M2::openWorkFiles 			"M2"
			Bind '1'  <z> M2::launchShellAndSimulate 	"M2"
			Bind '2'  <z> M2::launchShell 				"M2"
		}
	}
	# else case not needed, since active mode provides by menu these
	# commands plus the bindings 
}


proc M2::unsetGlobalBindings {} {
	global M2modeVars
	# alertnote "in M2::unsetGlobalBindings"
	if {[info exists M2modeVars(globalM2Bindings)] && !$M2modeVars(globalM2Bindings)} {
		# alertnote "in M2::unsetGlobalBindings: Unbinding global bindings"
		unBind '0'  <z> M2::openWorkFiles
		unBind '1'  <z> M2::launchShellAndSimulate
		unBind '2'  <z> M2::launchShell
		# - but leave them defined in M2 mode:
		Bind '0'  <z> M2::openWorkFiles 			"M2"
		Bind '1'  <z> M2::launchShellAndSimulate 	"M2"
		Bind '2'  <z> M2::launchShell 				"M2"
	}
}


# Now make sure the mode at least has the so-called global bindings when
M2::setGlobalBindings


# --------------------------------------------------------------------------------
# ×××× M2 Mode specific  bindings ×××× #
# --------------------------------------------------------------------------------
# Search next temporary mark which points at the location where the compiler detected an error 
Bind 'e' <z> M2::findNextError        "M2"
# Give help
Bind  Help    M2::m2Help              "M2"
# Open corresponding module if it is a definition or implementation module (Ctrl^Option^o)
Bind 'o' <oz> M2::openOtherLibModule  "M2"


# Break line and indent remainder  (RET) 
# Don't bind plain Return key, thus rename 
# proc breakLineAndIndent to M2::carriageReturn
# Old binding was:
# bind 0x24     breakLineAndIndent "M2"
    
# ×××× RET key bindings ×××× #
# 
# Break line (Ctrl^Shift^RET)
Bind 0x24 <sz> M2::breakTheLine        	 "M2"
# Jump out of current line, return, and indent (Shift^RET)
Bind 0x24 <s> M2::jumpOutOfLnAndReturn   "M2"
# Jump out of current line and return WITHOUT indent (Cmd^RET) (see also Shift^RET)
Bind 0x24 <c> M2::jumpOutOfLnAndRet      "M2"
# Jump out of line and open a new line above current (Cmd^Shift^RET)
Bind 0x24 <sc> M2::openNewAbove          "M2"  
# Jump out of line, skip next and open a new line after it (Cmd^Shift^Ctrl^RET)
Bind 0x24 <szc> M2::skipLnReturn         "M2"  
# Jump out of line, skip previous and make a new line above it (not in use)
	# bind 0x24 <szc> M2::skipPrevLnOpenNew    "M2"  
# Move cursor to next autostop (like TAB) or jump out of current line, return, and indent (Shift^RET)  (not in use)
	# bind 0x24 <s> M2::tabOrJumpOutOfLnAndReturn "M2"
# Jump back to position before last jump, e.g. by M2::jumpOutOfLnAndReturn  (Ctrl^RET)
Bind 0x24 <z> M2::resumeBeforeCarRet     "M2"
# New line and move one line down  (Opt^RET)
Bind 0x24 <o> M2::newLnAtSameCol         "M2"

# ×××× TAB key bindings ×××× #
# 
# Indent current line or jump to next bullet (Tab)
Bind 0x30       M2::tabKey              "M2"
# Force the insertion of an indentation even if there are still some bullets further down (Opt^Tab)
Bind 0x30   <o> M2::modulaTab          	 "M2"
# Unindent current line (Shift^Tab)
Bind 0x30   <s> M2::unIndent            "M2"
# Indent current line like closest non-white line above (Ctrl^Shift^Tab)
Bind 0x30  <sz> M2::adjCurLnToIndentAbove "M2"
# Indent current line like closest non-white line below (Opt^Shift^Tab)
Bind 0x30  <so> M2::adjCurLnToIndentBelow "M2"
# Insert an actual TAB - refrain from using this in M2 Mode (Ctrl^Opt^Cmd^Tab)
Bind 0x30 <coz> insertActualTab    "M2"

# ×××× Triggering completions ×××× #
# 
# M2::expandSpace does first some M2 mode specific expansion (see M2 Tutorial.M2 and
# m2Completions.tcl) and if none is available resorts to Alpha's standard electric 
# completions (see Alpha manual for details)
# 
# Trigger M2 completion (good old fashioned Cmd^TAB, works in OS9, but fails in OSX)
Bind 0x30 <c> M2::expandSpace         "M2"
# Trigger M2 completion (Ctrl^TAB - new Alpha standard, needed in OSX)
Bind 0x30 <z> M2::expandSpace         "M2"
# Trigger M2 completion (F1 - new Alpha standard,
# check possible conflicting use by some Control Panel such as Keyboard or Program Switcher)
Bind 0x7a     M2::expandSpace         "M2"
# Trigger M2 completion (ESC - convenient single stroke)
Bind 0x35     M2::expandSpace         "M2"
# Trigger M2 completion (ESC_^_space bar - only here for compatibility with earlier M2 versions)
Bind 0x31 <e> M2::expandSpace         "M2"
# Trigger M2 completion (Num keypad 1 - convenient on PowerBooks (type fn^J, fn = function key))
Bind Kpad1    M2::expandSpace         "M2"
# Allow for use of Kpad1 regardless of NLCK settings (useful in AlphaX >= 8.0b14)
# Bind 0x53     M2::expandSpace         "M2"
# use preference electricNumKeypad_1 to control this behavior
proc M2::activateElectricNumKeypad1 {} {
	Bind Kpad1 M2::expandSpace         "M2"
	# Allow for use of Kpad1 regardless of NLCK settings (useful in AlphaX >= 8.0b14)
	# Bind 0x53  M2::expandSpace         "M2"
}
proc M2::deactivateElectricNumKeypad1 {} {
	unBind Kpad1 M2::expandSpace         "M2"
	# Allow for use of Kpad1 regardless of NLCK settings (useful in AlphaX >= 8.0b14)
	# unBind 0x53  M2::expandSpace         "M2"
}

# Trigger default font settings (Num keypad 2, on PowerBooks type fn^K, fn = function key)
Bind Kpad2     M2::SetDfltFont         "M2"

# Complete previous word (Cmd^Opt^TAB - only here for compatibility with earlier M2 versions)
Bind 0x30 <oc> M2::completePrevWord   "M2"
# Complete previous word (Ctrl^Opt^TAB - more convenient to type and logical in OSX)
Bind 0x30 <oz> M2::completePrevWord   "M2"

# Space bar expansion (triggers templates if preceeding word matches a reserved word)
# These templates are programmed within m2Templates.tcl and are NOT the same as the
# ones in m2Completions.tcl (the mode offered templates before Alpha offered the
# electric completion mechanism in the current more general manner)
# Trigger template for preceeding reserved word or enter blank (space bar context dependent)
Bind 0x31     M2::modulaSpace         "M2" 
# preference spaceBarExpansion controls above binding via following two procedures
proc M2::activateSpaceBarExpansion {} {
    Bind 0x31     M2::modulaSpace         "M2"
}
proc M2::deactivateSpaceBarExpansion {} {
    unBind 0x31     M2::modulaSpace         "M2" 
}


# ×××× Backspace and Delete key bindings ×××× #
# 
# Delete entire line (Ctrl^BS) 
Bind 0x33 <z> M2::killWholeLine       "M2"
# Clear line from cursor till end (Opt^BS)
Bind 0x33 <o> killLine            "M2"
# Delete next char 
Bind  Del     deleteChar          "M2"

# ×××× Cursor key bindings ×××× #
# 
# Select entire line in which cursor is in
Bind Down <sz> M2::selectLine         "M2"
# Home
Bind Home <z> beginningOfBuffer   "M2"
# end
Bind End  <z> endOfBuffer         "M2"
# Cursor Right
Bind Right <z> forwardWord        "M2"
# Cursor Left
Bind Left <z> backwardWord        "M2"

# ×××× Structural marks ×××× #
# 
# Generate a structural mark from current selection, rest of line discarded (Ctrl^3)
Bind 0x14 <z> M2::insertDivider   "M2"
# Generate a section mark from current selection, rest of line discarded (Ctrl^4)
Bind 0x15 <z> M2::insertSubDivider   "M2"

# ×××× Alphanumerical & special char key bindings ×××× #
# 
# Join current line with next and reduce all white space to a single space (Ctrl^j)
Bind 0x26  <z> M2::JoinToOneSpace	  "M2"
# Reverse of join, i.e. it splits line at current cursor position and indents (Ctrl^Shift^j)
Bind 0x26 <sz> M2::SplitLineAt        "M2"
# Reduce white space surrounding current position to a single space (Ctrl^m)
Bind 'm'  <z> oneSpace            "M2"
# Go to next M2 place holder of form (*.  .*)
Bind 'g'  <z> M2::nextPlaceholder     "M2"
# Go to previous M2 place holder of form (*.  .*)
Bind 'g' <sz> M2::prevPlaceholder     "M2"
Bind 'g' <oz> M2::prevPlaceholder     "M2"
# Indent by m2_indentAmount of spaces (configurable)
Bind '\]' <o> M2::doM2ShiftRight	  "M2"
Bind 'r'  <z> M2::doM2ShiftRight      "M2"
# Unindent by m2_indentAmount of spaces (configurable)
Bind '\[' <o> M2::doM2ShiftLeft	      "M2"
Bind 'l'  <z> M2::doM2ShiftLeft	      "M2"
# Select comment (if present) surrounding position
Bind 's' <sz> M2::selectM2Comment     "M2"
# Enclose (comment) selected text with prefix and suffix strings
Bind 'c'  <z> M2::encloseSelection    "M2"
# Unenclose (uncomment) selected text from prefix and suffix strings
Bind 'c' <sz> M2::unencloseSelection  "M2"
Bind 'c' <oz> M2::unencloseSelection  "M2"
# Comment selected text to form (*. .*), a M2 place holder results
Bind 'k'  <z> M2::commentSelection    "M2"
# Uncomment selected text of form (*. .*)
Bind 'k' <sz> M2::uncommentSelection  "M2"
Bind 'k' <oz> M2::uncommentSelection  "M2"
# Wrap text: left margin given by top line and with right margin at m2_fillRightMargin (configurable)
Bind 'a' <sz> M2::wrapText            "M2"
# Wrap entire Modula-2 comment surrounding selection
Bind 'a' <z>  M2::wrapComment         "M2"
# Enclose selection with " "
Bind '2' <co> {return [M2::myWrapObject "\"" "\""]}     "M2"
# Enclose selection with ' '
Bind '2' <cos> {return [M2::myWrapObject "'" "'"]}      "M2"
# List directory content in new window
Bind 'f' <osz> M2::listDirContent     "M2"
# Auto edit conditional compilation flags for a target platform (Mac, Sun, IBM PC)
Bind 'f' <sc> M2::autoEditCompilerFlags    "M2"


# Bindings of general use, but made available only for M2 mode
# ------------------------------------------------------------
# Show full path and name of currently active window in status bar (Cmd^Opt^N)
Bind 'n' <co> M2::showFullName "M2"


# Overrule proc uncommentLine from textManip.tcl, since it does not call
# removeSuffix as is necessary in Modula-2 (bug in Alpha <= 7.1b2)
# (Cmd^Opt^D, as shown in menu)
Bind 'd' <co> M2::uncommentLine   "M2"





# Reporting that end of this script has been reached
status::msg "m2Bindings.tcl for Programing in Modula-2 loaded"
if {[info exists M2::installDebugFlag] && [set M2::installDebugFlag]} {
	alertnote "m2Bindings.tcl for Programing in Modula-2 loaded"
}
