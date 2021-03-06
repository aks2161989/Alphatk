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
	return "\r卯ile body功r"
}

proc t_latex {class parent subtype } {
	# Possible 'subtypes' are: article book letter report slides
	set t "%&LaTeX\r\r\\documentclass\[另ype-size功]\{$subtype\}\r"
	if {$subtype != "letter" } {
		append t "\\usepackage\{叼ackage names功}\r"
		append t "\\begin\{document\}\r\r且ody of document功r\r"
		append t "\\bibliography\{半ib names功}\r"
		append t "\\bibliographystyle\{半ibstyle功}\r"
		append t "\\end\{document\}\r"
		return $t
	}
	# letter:
	append t "\r\\address\{%\r\t句our name功t\\\\\t\r"
	append t "\t句our address功t\\\\\r"
	append t "\t叮ore address功t\\\\\r"
	append t "\t卉ity-state-zip功r\}\r"
	append t "\r\\date\{卡ate功}  % optional\r"
	append t "\\signature\{叫ignature功}\r"
	append t "\r\\begin\{document\}\r"
	append t "\r\\begin\{letter\}\{%\r"
	append t "\t仟ddressee's name� \\\\\t\r"
	append t "\t仟ddressee's address功t\\\\\t\r"
	append t "\t叮ore addressee's address功t\\\\\r"
	append t "\t仟ddressee's city-state-zip功r"
	append t "\}\r\r\\opening\{Dear 仟ddressee�,\}\r"
	append t "\r召etter body功r\r\\closing\{Sincerely,\}\r"
	append t "\r\\encl\{孕\}\r\\cc\{孕\}\r"
	append t "\r\\end\{letter\}\r\r"
	append t "\\end\{document\}\r"
	return $t
}

proc t_html {class parent} {
	append t "<HTML>\r\r<HEAD>\r\r<TITLE>另itle�</TITLE>\r"
	append t "\r\r</HEAD>\r\r<BODY>\r"
	append t "\r半ody功r\r</BODY>\r"
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
