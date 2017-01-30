#!/bin/bash

source /vagrant/vars

sed -i "s|http://us.|http://$APT_MIRROR.|g" /etc/apt/sources.list

ex +"%s@DPkg@//DPkg" -cwq /etc/apt/apt.conf.d/70debconf
dpkg-reconfigure debconf -f noninteractive -p critical

apt-get update >/dev/null

if [ ! -f /vagrant/live.iso ] ; then
  apt-get install -y debootstrap docker.io genisoimage
  mkdir /temp
  rsync -a /vagrant/livessh/ /temp/
  locale-gen "en_US.UTF-8"
  dpkg-reconfigure -fnoninteractive locales
  export LC_ALL="en_US.UTF-8"
  (cd /temp/bin/ && ./build-debootstrap-image.sh)
  (cd /temp/bin/ && ./build-customized-environment.sh)
  (cd /temp/bin/ && ./build-livecd-image.sh)
  cp /temp/livessh-ubuntu16.04.iso /vagrant/live.iso
fi

rsync /vagrant/live.iso /live.iso
mkdir -p /mnt/iso
mount | grep /mnt/iso || mount /live.iso /mnt/iso

apt-get -y install pxelinux

apt-get -y install xinetd tftpd tftp
cat << EOF > /etc/xinetd.d/tftp
service tftp
{
    protocol        = udp
    port            = 69
    socket_type     = dgram
    wait            = yes
    user            = nobody
    server          = /usr/sbin/in.tftpd
    server_args     = /tftpboot
    disable         = no
}
EOF

mkdir -p /tftpboot
cp /usr/lib/PXELINUX/pxelinux.0 /tftpboot/
cp /usr/lib/syslinux/modules/bios/ldlinux.c32 /tftpboot/
mkdir -p /tftpboot/pxelinux.cfg

cat << EOF > /tftpboot/pxelinux.cfg/default
LABEL linux
DEFAULT vmlinuz initrd=initrd.lz boot=casper netboot=nfs nfsroot=$PXE_IP:/mnt/iso ip=dhcp toram
EOF

rsync /mnt/iso/$KERNEL_PATH /tftpboot/vmlinuz
rsync /mnt/iso/$INITRD_PATH.$INITRD_ARCHIVE_TYPE /tftpboot/initrd.$INITRD_ARCHIVE_TYPE

chown -R nobody /tftpboot
chmod -R 777 /tftpboot

apt-get -y install nfs-kernel-server
cat << EOF > /etc/exports
/mnt/iso       $ISO_EXPORT_HOST(rw,sync,no_root_squash)
EOF

/etc/init.d/nfs-kernel-server restart
/etc/init.d/xinetd restart
