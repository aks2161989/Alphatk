## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 # 
 # FILE: "Calculator-Example.tcl"
 #                                          created: 10/17/2000 {02:18:43 PM}
 #                                      last update: 03/06/2006 {06:03:22 PM}
 # Description: 
 #  
 # Script for the "Calculator Example" in the Examples package.
 # Press "Command-L" to evaluate this file to test.
 # 
 # Author: Craig Barton Upright
 # E-mail: <cupright@alumni.princeton.edu>
 #    www: <http://www.purl.org/net/cbu>
 #  
 # ==========================================================================
 ##

Calc::calculatorWindow
Calc::changeMode "3"
Calc::clearWindow 0 0 0
Calc::currentInput "1"
Calc::selectInput
Calc::specialKey "Push-Stack" 1
Calc::selectInput
Calc::currentInput "1"
Calc::selectInput
Calc::specialKey "Push-Stack" 1
Calc::selectInput
Calc::performOperation "binary" + 1
Calc::selectInput
Calc::currentInput "4.2"
Calc::selectInput
Calc::specialKey "Push-Stack" 1
Calc::selectInput
Calc::performOperation "binary" * 1
Calc::selectInput

