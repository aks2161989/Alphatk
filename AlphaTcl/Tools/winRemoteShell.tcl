# Required to get a remote connection going
# to a Tcl interpreter on windows.
# 
# Copyright (C) 1999-2000, Vince Darley.  
# All rights reserved.

# (1) Load dde package for interapp communication
package require dde

# (2) Find a servername which isn't yet in use
# We use names of the form 'Tcl_N'
set i 1
set name "Tcl_$i"
while {[lsearch -exact [dde services TclEval ""] "TclEval $name"] != -1} {
    incr i
    set name "Tcl_$i"
}
unset i

# (3) We don't really want the '.' window to have
# the name of this script, so we give it it's servername
# instead.
wm title . $name

# (4) Declare ourselves as a TclEval server with
# the given name
dde servername $name
update

# (5) Now wait until the 'system' has become aware
# of us: for some reason this isn't immediate, and
# the 'dde services TclEval ""' command seems to help
# things along.
while {[lsearch -exact [dde services TclEval ""] "TclEval $name"] == -1} {
    dde services TclEval ""
    update
}

# (6) Cleanup
unset name
cd [file dirname [info nameof]]
