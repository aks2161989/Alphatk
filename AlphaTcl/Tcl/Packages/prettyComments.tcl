## -*-Tcl-*- (install)
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "prettyComments.tcl"
 #                                    created: 7/10/97 {2:50:59 pm} 
 #                                last update: 05/08/2004 {05:10:55 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta, Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # Copyright (c) 1997-2003  Vince Darley.
 # 
 # See the file "license.terms" for information on usage and redistribution
 # of this file, and for a DISCLAIMER OF ALL WARRANTIES.
 # 
 # Distributable under Tcl-style (free) license.
 # ###################################################################
 ##

# extension declaration
alpha::feature prettyComments 0.1 global {
} {
} {
} maintainer {
    {It could be you!}
} uninstall {
    this-file
} description {
    Currently unimplemented, this package could provide additional support
    for the package: comments
} help {
    Currently unimplemented, this package could provide additional support
    for the package: comments .  In modes which use a single comment
    character, AlphaTcl currently uses a style of paragraph comment like
    this:
    
	##
	 # Here is a
	 # comment
	 ##

    which may not appeal to everyone.  We should remove this from
    the core, and move that functionality into this package so it
    can be made optional.  The default (for any mode for which
    this feature is off) would then be:
    
	# Here is a
	# comment

    which is probably a better default.
    
    Of course none of this is yet implemented!
} 
