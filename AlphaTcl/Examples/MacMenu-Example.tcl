## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "MacMenu-Example.tcl"
 #                                          created: 03/28/2001 {09:22:20 pm}
 #                                      last update: 03/06/2006 {06:51:15 PM}
 # Description: 
 # 
 # Script for the "MacMenu Example" in the Examples package.
 #
 # Author: Bernard Desgraupes
 # E-mail: <bdesgraupes@easyconnect.fr>
 #    www: <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # 
 # ==========================================================================
 ##

if {([help::pathToExample "MacMenu-Example"] ne "")} {
    new -n "* Mac Menu Tutorial *" -m Setx -text \
      [file::readAll [help::pathToExample "MacMenu-Example"]] -shell 1
    goto [minPos]
    if {[llength [getNamedMarks]]} {
	Setx::markAsSetext
    }
} else {
    alertnote "Sorry, the MacMenu Tutorial is not available."
}

