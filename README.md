# petalinux-systemc-docker

Copy systemc-2.3.3.tar.gz file to this folder.
Copy petalinux-v2020.2-final-installer.run file to this folder.

Then run:

`docker build -t petalinux-systemc:2020.2 .`

After installation, launch a container with (including X forwarding):

`docker run -ti -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/home/xilinx/.Xauthority petalinux-systemc:2020.2 /bin/bash`
