#!/usr/bin/env bash
set -e

install_libjpeg_turbo() {
    local libjpeg_deb=libjpeg-turbo.deb

    wget 'https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/a9434a300dbf85e65d0e9c212610a487fd10a308/output/bionic/libjpeg-turbo_2.1.2_amd64.deb' -O "$libjpeg_deb"
    apt-get install -y "./$libjpeg_deb"
    rm "$libjpeg_deb"
}

echo "Install KasmVNC server"
cd /tmp

BUILD_ARCH=$(uname -p)

if [ "${DISTRO}" == "kali" ]  ;
then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/a9434a300dbf85e65d0e9c212610a487fd10a308/kasmvncserver_kali-rolling_0.9.3_master_a9434a_amd64.deb"
elif [ "${DISTRO}" == "centos" ] ; then
    BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/a9434a300dbf85e65d0e9c212610a487fd10a308/output/centos_core/kasmvncserver-0.9.1~beta-1.el7.x86_64.rpm"
else
    if [[ "${BUILD_ARCH}" =~ ^aarch64$ ]] ; then
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/a9434a300dbf85e65d0e9c212610a487fd10a308/kasmvncserver_bionic_0.9.3_master_a9434a_arm64.deb"
    else
        BUILD_URL="https://kasmweb-build-artifacts.s3.amazonaws.com/kasmvnc/a9434a300dbf85e65d0e9c212610a487fd10a308/kasmvncserver_bionic_0.9.3_master_a9434a_libjpeg-turbo-latest_amd64.deb"
    fi
fi


if [ "${DISTRO}" == "centos" ] ; then
    wget "${BUILD_URL}" -O kasmvncserver.rpm

    yum localinstall -y kasmvncserver.rpm
    rm kasmvncserver.rpm
else
    if [[ "$DISTRO" = "ubuntu" ]] && [[ ! "$BUILD_ARCH" =~ ^aarch64$ ]] ; then
        install_libjpeg_turbo
    fi

    wget "${BUILD_URL}" -O kasmvncserver.deb

    apt-get update
    apt-get install -y gettext ssl-cert
    dpkg -i /tmp/kasmvncserver.deb
    apt-get -yf install
    rm -f /tmp/kasmvncserver.deb
fi
#mkdir $KASM_VNC_PATH/certs
mkdir -p $KASM_VNC_PATH/www/Downloads
chown -R 0:0 $KASM_VNC_PATH
chmod -R og-w $KASM_VNC_PATH
#chown -R 1000:0 $KASM_VNC_PATH/certs
chown -R 1000:0 $KASM_VNC_PATH/www/Downloads
ln -s $KASM_VNC_PATH/www/index.html $KASM_VNC_PATH/www/vnc.html
