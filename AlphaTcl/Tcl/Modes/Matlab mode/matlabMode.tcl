################################################################################
#
# Matlab package, version 2.0
#
# This is a set of TCL proc's that allow the shareware Macintosh text editor 
# Alpha to act as a front end for MATLAB for Macintosh version 5.0 or 
# higher.  Requires Alpha 7.0 or higher.  See file "Matlab Help" for more 
# information.
#
################################################################################

alpha::mode [list MATL MATLAB] 2.0.8 dummyMATL {*.m *.M} {
    MATLMenu
} {
    # Script to execute at Alpha startup
    addMenu MATLMenu "¥405" MATL
    set unixMode(matlab) MATL
} uninstall {
    this-directory
} maintainer {
    "Stephen M. Merkowitz" <Stephen.Merkowitz@lnf.infn.it>
} description {
    Supports the editing of MATLAB programming files
} help {
    file "Matlab Help"
}


#################################################################################
# Autoload procedures
################################################################################

proc dummyMATL {} {}
proc MATLMenu  {} {}


#################################################################################
# Hooks
################################################################################

namespace eval MATL {}
hook::register saveHook MATL::saveHook MATL

################################################################################
# Flags and variables
################################################################################

newPref v prefixString     {% }     MATL
newPref v wordBreak        {[_\w]+} MATL
newPref var lineWrap         {0}      MATL

newPref v tabSize  {3} MATL
newPref v funcExpr {^[ \t]*(function|FUNCTION).*\(.*$} MATL
# To automatically perform context relevant formatting after typing a
# semicolon, turn this item on||To have the semicolon key produce a
# semicolon without additional formatting, turn this item off
newPref flag electricSemicolon 1 MATL
# To automatically indent the new line produced by pressing <return>, turn
# this item on.  The indentation amount is determined by the context||To
# have the <return> key produce a new line without indentation, turn this
# item off
newPref flag indentOnReturn    1 MATL

# remove obsolete
catch {unset MATLmodeVars(elecReturn)}
catch {unset MATLmodeVars(electricSemi)}

newPref f DblClickEdits  0 MATL
newPref f clearOnSave    0 MATL
newPref f webHelp        0 MATL

newPref v CmdWinName     {*Matlab Commands*} MATL
newPref v CmdHistWinName {*Command History*} MATL

newPref v MatlabHelpFolder "" MATL

newPref f queEventsQuietly  0 MATL


set MATL::commentCharacters(General) "% "
set MATL::commentCharacters(Paragraph) [list "% " "% " "% "]
set MATL::commentCharacters(Box) [list "%" 1 "%" 1 "%" 3]


################################################################################
# Colorization
################################################################################

newPref color keywordColor      blue    MATL
newPref color keyVariablesColor green   MATL
newPref color punctuationColor  magenta MATL
newPref color stringColor       red     MATL                    
newPref color commentColor      green   MATL

set matKeywords { 
	break else elseif end for if return while function switch case otherwise
	global eval feval nargchk pause menu keyboard input ...
}

set matKeyVariables { 
	ans computer eps flops inf NaN pi realmax realmin 
	nargin nargout varargout varargin
}

regModeKeywords -C MATL {}
regModeKeywords -a -e {%} -c $MATLmodeVars(commentColor) \
  -k $MATLmodeVars(keywordColor) MATL $matKeywords
regModeKeywords -a -i {[} -i {]} -i {(} -i {)} -i {,} -i {;} \
  -I $MATLmodeVars(punctuationColor)  MATL {}
regModeKeywords -a -k $MATLmodeVars(keyVariablesColor) MATL $matKeyVariables

if {${alpha::platform} == "tk"} {
    regModeKeywords -a -s $MATLmodeVars(stringColor) -q ' ' -q \" \" MATL {}
}

unset matKeywords
unset matKeyVariables


################################################################################
#  global variables
################################################################################

set Matl_commandHistory [list]
set Matl_commandNum 0
set lastMatlabResult ""
set matlabBusy 0
set MATLeventQue [list]


################################################################################
#  Bind some keys
################################################################################

Bind '\r' <z>  matlabDoLine              "MATL"
Bind up        matlabUp                  "MATL"
Bind down      matlabDown                "MATL"
Bind 'u'  <z>  matlabCancelLine          "MATL"
Bind '\;' <o>  MATL::electricSemiJump    "MATL"


################################################################################
#  Load the rest of the matlab package
################################################################################

foreach f {Comm Engine Macros Menu Windows Doc HTML} {
	 if [catch [set f "matlab${f}.tcl"]] {
		  alertnote "Loading of $f failed!"
	 }
}
unset f
