# petalinux-systemc-docker

Forked from https://github.com/z4yx/petalinux-docker, and with additional input from https://github.com/Sparkles-Qemu/qemu_vp_builder

To build the image, copy systemc-2.3.3.tar.gz and petalinux-v2020.2-final-installer.run files to this folder. Then run:

`docker build -t petalinux-systemc:2020.2 .`

After installation, launch a container with (including X forwarding):

`docker run -ti -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/home/xilinx/.Xauthority petalinux-systemc:2020.2`

# Building a PetaLinux project

First, either bind mount a board support package (BSP):

`docker run -ti -v <bsp_root>/xilinx-zcu102-v2020.2-final.bsp:/home/xilinx/xilinx-zcu102-v2020.2-final.bsp qemu-systemc:2020.2`

or copy the BSP into the (existing) container:

`docker cp <bsp_root>/xilinx-zcu102-v2020.2-final.bsp <container>:/home/xilinx/`

Then, inside the container, setup permissions, and create and build a new PetaLinux project:

      sudo chown xilinx.xilinx xilinx-zcu102-v2020.2-final.bsp
      petalinux-create -t project -n PetaLinux -s xilinx-zcu102-v2020.2-final.bsp
      cd PetaLinux
      petalinux-config
      petalinux-build

# Running a normal QEMU simulation

You can either boot the pre-built image that came with the BSP in the PetaLinux QEMU:

      petalinux-boot --qemu --prebuilt 3

or run the (potentially customized) image that was created in the previous PetaLinux build step:

      petalinux-boot --qemu --kernel

# Running a co-simulation

First, create a temporary directory used to exchange information between QEMU and SystemC simulators:

      mkdir ../tmp

Launch a QEMU instance insider the container using a custom co-simulation device tree and pointing it to the temporary directory with:

      petalinux-boot --qemu --kernel --qemu-args "-hw-dtb ../qemu-devicetrees/LATEST/MULTI_ARCH/zcu102-arm.cosim.dtb -machine-path ../tmp -sync-quantum <quantum>"

The simulation `<quantum>` is optional and should normally be 1000000.

Then switch to another host terminal, and launch a second shell in your container:

`docker exec -it <container> /bin/bash`

and run the SystemC side of the co-simulation using the same `<quantum>` as given on the QEMU side:

    cd systemctlm-cosim-demo
    ./zynqmp_demo unix:../tmp/qemu-rport-_amba@0_cosim@0 <quantum>

