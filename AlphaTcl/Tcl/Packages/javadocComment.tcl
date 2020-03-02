## -*-Tcl-*- (install)
 # ###################################################################
 # 
 #  FILE: "javadocComment.tcl"
 #                                    created: 03/18/1999 {15:15:20 PM} 
 #                                last update: 05/08/2004 {05:12:07 PM} 
 #  Author: Vince Darley
 #  E-mail: vince@biosgroup.com
 #    mail: Bios Group
 #          317 Paseo de Peralta, Santa Fe, NM 87501
 #     www: http://www.biosgroup.com/
 #  
 # Copyright (c) 1999-2004 Vince Darley
 # 
 # Distributable under Tcl-style (free) license.
 # ###################################################################
 ##

# extension declaration
alpha::feature javadocComment 0.1 "Java" {
} {
    menu::insert javaMenu items end "/'<BjavadocComment"
} {
    menu::removeFrom javaMenu items end "/'<BjavadocComment"
} uninstall {
    this-file
} maintainer {
    {Vince Darley} <vince@biosgroup.com> <http://www.biosgroup.com/>
} description {
    This features creates a new "Java > Javadoc Comment" menu item for quick
    entry of javadoc info in Java comments
} help {
    This features creates a new "Java > Javadoc Comment" menu item for quick
    entry of javadoc info in Java comments.
    
    Preferences: Mode-Features-Java
    
    Selecting this menu item will insert a comment that looks like this:
    
	/**
	 * @tooltip 
	 * @default ¥
	 * @modifiable 1
	 */
	¥
    
    The comment will be inserted at the current cursor position.
}

proc Java::javadocComment {} {
    elec::Insertion "/**\r * @tooltip ¥comment body¥\r * @default ¥default¥\r * @modifiable 1\r */\r¥¥"
}
