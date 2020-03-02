## -*-Tcl-*-
 # ==========================================================================
 # AlphaTcl support packages
 # 
 # FILE: "f90Completions.tcl"
 #                                          created: 02/10/2005 {06:44:37 PM}
 #                                      last update: 02/23/2006 {04:48:50 PM}
 # Description:
 # 
 # Provides electric completion support in f90 mode.  This relies on the
 # procedures in the "FortCompletions.tcl" file.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # Copyright (c) 2005-2006  Craig Barton Upright
 # All rights reserved.
 # 
 # This file is distributed under a Tcl style license.
 # 
 # ==========================================================================
 ##

proc f90Completions.tcl {} {}

set ::completions(f90) [list \
  {completion::contraction} "specialElectric" \
  {completion::cmd} {completion::electric} {completion::word}]

set ::expanders(f90) [list \
  {completion::contraction} "specialElectric"]

# To use '(' as an electric completion key, turn this item on.  Typing a
# second consecutive left parenthesis add a closing right parenthesis||To
# disable the use of '(' as an electric completion key, turn this item off
newPref flag electricDblLeftParen   {1}     f90
# To complete "elseif" with "ELSE IF", turn this item on||To complete
# "elseif" as a single word, turn this item off
newPref flag elseifIsSingleWord     {1}     f90
# To complete "endif|do" with "END IF|DO", turn this item on||To complete
# "elseif" with and "endif" as single words, turn this item off
newPref flag endifEnddoAreSingleWords {1}   f90
# To always add a space after an electric completion (before any
# parenthetical arguments) of a command, turn this item on||To never add a
# space after an electric completion of a command, turn this item off
newPref flag spaceAfterIf           {1}     f90 \
  {f90::Completion::rebuildElectrics}
# To always add a space after an electric completion (before any
# parenthetical arguments) of a command, turn this item on||To never add a
# space after an electric completion of a command, turn this item off
newPref flag spacesAfterCommand	    {1}     f90 \
  {f90::Completion::rebuildElectrics}
# To always add a space after an electric completion (before any
# parenthetical arguments) of a function, turn this item on||To never add a
# space after an electric completion of a function, turn this item off
newPref flag spacesAfterFunction    {0}     f90 \
  {f90::Completion::rebuildElectrics}

# The style for command completions.  Completion 'hints' can be in any of
# these forms, but all will be translated to this style.
newPref var  completeCommandsUsing  {0}     f90 \
  {f90::Completion::rebuildElectrics} \
  [list "lower case" "Capitalized Names" "UPPER CASE"] index

# Add a new preferences pane.
prefs::dialogs::setPaneLists "f90" "Electrics" [list \
  "completeCommandsUsing" \
  "electricDblLeftParen" \
  "elseifIsSingleWord" \
  "endifEnddoAreSingleWords" \
  "spaceAfterIf" \
  "spacesAfterCommand" \
  "spacesAfterFunction" \
  ]

# Electric Double Left Parenthesis.
Bind '(' f90::electricDoubleLeftParen f90

namespace eval f90 {}

proc f90::electricDoubleLeftParen {} {
    return [Fort::electricDoubleLeftParen "f90"]
}

namespace eval f90::Completion {}

proc f90::Completion::rebuildElectrics {args} {
    return [Fort::Completion::rebuildElectrics "f90"]
}

# Call this now.
f90::Completion::rebuildElectrics

proc f90::Completion::specialElectric {} {
    return [Fort::Completion::specialElectric "f90"]
}

# ===========================================================================
# 
# .