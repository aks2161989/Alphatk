## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "Compare-word-by-word-Example.tcl"
 #                                          created: 08/28/2005 {04:10:28 PM}
 #                                      last update: 03/06/2006 {06:08:13 PM} 
 # Description: 
 # 
 # Script for the "Compare word-by-word example" in the Examples package.
 #
 # ==========================================================================
 ##

edit -r -c [help::pathToExample "Diff word-by-word.txt"]
edit -r -c [help::pathToExample "Diffing word-by-word.txt"]
compare::windowsWordByWord
