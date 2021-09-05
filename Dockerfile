FROM ubuntu:18.04

MAINTAINER gerstl <gerstl@ece.utexas.edu>

ARG INSTALL_ROOT=/opt
ARG SYSTEMC_VERSION=2.3.3
ARG SYSTEMC_ARCHIVE=systemc-2.3.3.tar.gz
ARG PETA_VERSION=2020.2
ARG PETA_RUN_FILE=petalinux-v${PETA_VERSION}-final-installer.run
ARG PETA_PLATFORM=

# build with "docker build --build-arg PETA_VERSION=2020.2 -t petalinux:2020.2 ."

# install dependences:

RUN apt-get update &&  DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
  build-essential \
  sudo \
  tofrodos \
  iproute2 \
  gawk \
  net-tools \
  expect \
  libncurses5-dev \
  tftpd \
  update-inetd \
  libssl-dev \
  flex \
  bison \
  libselinux1 \
  gnupg \
  wget \
  socat \
  gcc-multilib \
  libsdl1.2-dev \
  libglib2.0-dev \
  lib32z1-dev \
  libgtk2.0-0 \
  screen \
  pax \
  diffstat \
  xvfb \
  xterm \
  texinfo \
  gzip \
  unzip \
  cpio \
  chrpath \
  autoconf \
  lsb-release \
  libtool \
  libtool-bin \
  locales \
  kmod \
  git \
  rsync \
  bc \
  u-boot-tools \
  python \
  xxd \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN dpkg --add-architecture i386 &&  apt-get update &&  \
      DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
      zlib1g:i386 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8 && update-locale

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# make a xilinx user
RUN adduser --disabled-password --gecos '' xilinx && \
  usermod -aG sudo xilinx && \
  echo "xilinx ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# run the SystemC install
COPY ${SYSTEMC_ARCHIVE} /home/xilinx/
RUN cd /home/xilinx && \
  tar xzf ${SYSTEMC_ARCHIVE} && \
  mkdir systemc-${SYSTEMC_VERSION}/objdir && \
  cd systemc-${SYSTEMC_VERSION}/objdir && \
  ../configure --prefix=${INSTALL_ROOT}/systemc-${SYSTEMC_VERSION} && \
  make && \
  make install && \
  cd /home/xilinx && \
  rm -f ${SYSTEMC_ARCHIVE} && \
  rm -rf systemc-${SYSTEMC_VERSION}

# run the petalinux install
COPY sed.sh accept-eula.sh ${PETA_RUN_FILE} /home/xilinx/
RUN chmod a+rx /home/xilinx/${PETA_RUN_FILE} && \
  chmod a+rx /home/xilinx/accept-eula.sh && \
  chmod a+rx /home/xilinx/sed.sh && \
  mv /home/xilinx/sed.sh /home/xilinx/sed && \
  mkdir -p ${INSTALL_ROOT}/xilinx && \
  chown xilinx.xilinx ${INSTALL_ROOT}/xilinx && \
  cd /tmp && \
  sudo -u xilinx -i /home/xilinx/accept-eula.sh /home/xilinx/${PETA_RUN_FILE} ${INSTALL_ROOT}/xilinx/petalinux "${PETA_PLATFORM}" && \
  rm -f /home/xilinx/${PETA_RUN_FILE} /home/xilinx/accept-eula.sh /home/xilinx/sed /home/xilinx/petalinux_installation_log

USER xilinx
ENV HOME /home/xilinx
ENV LANG en_US.UTF-8
WORKDIR /home/xilinx

# add Petalinux tools and SystemC to path
RUN echo "" >> /home/xilinx/.bashrc && \
    echo "export LD_LIBRARY_PATH=${INSTALL_ROOT}/systemc-${SYSTEMC_VERSION}/lib-linux64" >> /home/xilinx/.bashrc && \
    echo "source ${INSTALL_ROOT}/xilinx/petalinux/settings.sh" >> /home/xilinx/.bashrc

# clone the Xilinx SystemC co-simulation demo
RUN cd /home/xilinx && \
  git clone --depth 1 https://github.com/Xilinx/systemctlm-cosim-demo.git && \
  cd systemctlm-cosim-demo && \
  git submodule update --init libsystemctlm-soc && \
  sed -i -e 's|/usr/local/systemc-2.3.2|'${INSTALL_ROOT}'/systemc-'${SYSTEMC_VERSION}'|g' Makefile && \
  make && \
  make TARGETS= clean

# clone the device trees for co-simulation
RUN cd /home/xilinx && \
  git clone -b xilinx-v${PETA_VERSION} --depth 1 https://github.com/Xilinx/qemu-devicetrees && \
  cd qemu-devicetrees && \
  make
