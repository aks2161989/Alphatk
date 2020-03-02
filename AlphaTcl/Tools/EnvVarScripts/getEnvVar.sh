#!/bin/sh

# Report the value of an environment variable 
# as defined in the startup sequence of /bin/sh

source /etc/profile
if [ -r ~/.profile ] 
then
  source ~/.profile
fi

eval echo \$$1
