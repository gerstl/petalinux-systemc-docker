#!/bin/sh

# Remove newlines if called by the silly Xilinx 2018.3 PetaLinux installer
if [ "$2" = "s/^.*minimal-\(.*\)-toolchain.*/\1/" ] ; then
  /bin/sed "$@" | tr '\n' ' '
else
  /bin/sed "$@"
fi
