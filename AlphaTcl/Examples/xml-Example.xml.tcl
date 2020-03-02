## -*-Tcl-*-
 # ==========================================================================
 # Examples - a Help package for Alpha
 #
 # FILE: "xml-Example.xml.tcl"
 #                                          created: 03/09/2003 {09:48:02 PM}
 #                                      last update: 03/06/2006 {06:50:39 PM}
 # Description: 
 # 
 # Script for the "xml Example" in the Examples package.
 #
 # Author: Bernard Desgraupes
 # E-mail: <bdesgraupes@easyconnect.fr>
 #    www: <http://webperso.easyconnect.fr/bdesgraupes/alpha.html>
 # 
 # ==========================================================================
 ##

if {([help::pathToExample xml-Example.xml] ne "")} {
    new -n "* xml Mode Example *" -m xml -text \
      [file::readAll [help::pathToExample xml-Example.xml]] -shell 1
    # The '<?xml...>' line must be first
    goto [nextLineStart [minPos]]
    insertText [help::openExampleFileHelper xml]
} else {
    alertnote "Sorry, the xml example is not available."
}
