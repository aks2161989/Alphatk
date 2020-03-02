
package provide parser 1.4
package require critcl

namespace eval parser {

    critcl::cheaders -IC:/Progra~1/DevStudio/VC/INCLUDE
    critcl::cheaders -ID_WIN32=1
    critcl::csources tclParser.c

    critcl::ccode {
      #include <tclInt.h>
    }

    critcl::ccommand parse {dummy ip objc objv} {
	return ParseObjCmd(dummy, ip, objc, objv);
    }
}
