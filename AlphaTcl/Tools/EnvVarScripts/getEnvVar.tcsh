#!/bin/tcsh

# Report the value of an environment variable 
# as defined in the startup sequence of /bin/tcsh

source /etc/csh.cshrc
source /etc/csh.login
if ( -r ~/.tcshrc ) then
  source ~/.tcshrc
else if ( -r ~/.cshrc ) then
  source ~/.cshrc
endif
if ( -r ~/.login ) then
  source ~/.login
endif

eval echo \$$1
