#!/opt/bin/ksh
#
# Edit paths as appropriate.  If you have improvements to
# this file which would help others, please send them to
# vince.darley@kagi.com
# 
#  Usage:  
#         alphatk 
#  or
#         alphatk filename
#
if [[ "$1" == "" ]]
then
	/opt/bin/wish /opt/Alphatk/alphatk.tcl &
elif [[ -f $1 ]]
then
	/opt/bin/wish /opt/Alphatk/runalpha.tcl $1 & 
else 
	touch $1;
	/opt/bin/wish /opt/Alphatk/runalpha.tcl $1 &
fi
