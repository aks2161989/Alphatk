## -*-Tcl-*-
 # ###################################################################
 #  Vince's Additions - an extension package for Alpha
 # 
 #  FILE: "userTemplates.tcl"
 #                                    created: 2/8/97 {1:07:29 pm} 
 #                                last update: 02/16/2000 {19:00:00 PM} 
 #  Author: Vince Darley
 #  E-mail: <vince@santafe.edu>
 #    mail: 317 Paseo de Peralta
 #          Santa Fe, NM 87501, USA
 #     www: <http://www.santafe.edu/~vince/>
 #  
 # ###################################################################
 ##


proc t_default { class parent } {
	return "\r¥file body¥\r"
}

proc t_latex {class parent subtype } {
	# Possible 'subtypes' are: article book letter report slides
	set t "%&LaTeX\r\r\\documentclass\[¥type-size¥\]\{$subtype\}\r"
	if {$subtype != "letter" } {
		append t "\\usepackage\{¥package names¥\}\r"
		append t "\\begin\{document\}\r\r¥Body of document¥\r\r"
		append t "\\bibliography\{¥bib names¥\}\r"
		append t "\\bibliographystyle\{¥bibstyle¥\}\r"
		append t "\\end\{document\}\r"
		return $t
	}
	# letter:
	append t "\r\\address\{%\r\t¥your name¥\t\\\\\t\r"
	append t "\t¥your address¥\t\\\\\r"
	append t "\t¥more address¥\t\\\\\r"
	append t "\t¥city-state-zip¥\r\}\r"
	append t "\r\\date\{¥date¥\}  % optional\r"
	append t "\\signature\{¥signature¥\}\r"
	append t "\r\\begin\{document\}\r"
	append t "\r\\begin\{letter\}\{%\r"
	append t "\t¥addressee's name¥ \\\\\t\r"
	append t "\t¥addressee's address¥\t\\\\\t\r"
	append t "\t¥more addressee's address¥\t\\\\\r"
	append t "\t¥addressee's city-state-zip¥\r"
	append t "\}\r\r\\opening\{Dear ¥addressee¥,\}\r"
	append t "\r¥letter body¥\r\r\\closing\{Sincerely,\}\r"
	append t "\r\\encl\{¥¥\}\r\\cc\{¥¥\}\r"
	append t "\r\\end\{letter\}\r\r"
	append t "\\end\{document\}\r"
	return $t
}

proc t_html {class parent} {
	append t "<HTML>\r\r<HEAD>\r\r<TITLE>¥title¥</TITLE>\r"
	append t "\r\r</HEAD>\r\r<BODY>\r"
	append t "\r¥body¥\r\r</BODY>\r"
	append t "\r</HTML>"
	return $t
}

proc t_cpp_header { class parent } {
	set Text "\r\#ifndef _[file::projectName]_${class}_\r"
	append Text "\#define _[file::projectName]_${class}_\r\r\r"
	append Text "#include \"${parent}.h\"\r\r"
	append Text "class ${class}: public ${parent} \{\r"
	append Text "  public:\r"
	append Text "\t${class}(void);\r"
	append Text "\t~${class}(void);\r"
	append Text "  protected:\r\r"
	append Text "  private:\r"
	append Text "\};\r"
	append Text "\r\#endif\r"
	return $Text
	set docBody
}

proc t_cpp_source { class parent } {
	set Text "\r\#include \"${class}.h\"\r\r"
}
