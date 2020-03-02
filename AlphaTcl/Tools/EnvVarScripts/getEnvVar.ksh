#!/bin/ksh

# Report the value of an environment variable 
# as defined in the startup sequence of /bin/ksh

# source /etc/profile
if [ -r ~/.profile ] 
then
  source ~/.profile
fi

eval echo \$$1
