#!/usr/bin/sh

mkdir chroot
debootstrap --no-merged-usr --arch=i386 ondokuz chroot https://19.depo.pardus.org.tr/pardus
for i in dev dev/pts proc sys; do mount -o bind /$i chroot/$i; done
chroot chroot apt-get install gnupg -y

chroot chroot apt-get install grub-pc-bin grub-efi -y
chroot chroot apt-get install live-config live-boot -y

# xorg & desktop pkgs
chroot chroot apt-get install xserver-xorg network-manager-gnome -y

chroot chroot apt-get install xfce4 pardus-xfce-settings sudo thunar-archive-plugin -y
echo "deb http://depo.pardus.org.tr/pardus ondokuz main contrib non-free" > chroot/etc/apt/sources.list
echo "deb http://depo.pardus.org.tr/guvenlik ondokuz main contrib non-free" >> chroot/etc/apt/sources.list
chroot chroot apt-get update -y
chroot chroot apt-get install -y firmware-amd-graphics firmware-atheros \
    firmware-b43-installer firmware-b43legacy-installer \
    firmware-bnx2 firmware-bnx2x firmware-brcm80211  \
    firmware-cavium firmware-intel-sound firmware-intelwimax \
    firmware-ipw2x00 firmware-ivtv firmware-iwlwifi \
    firmware-libertas firmware-linux firmware-linux-free \
    firmware-linux-nonfree firmware-misc-nonfree firmware-myricom \
    firmware-netxen firmware-qlogic firmware-realtek firmware-samsung \
    firmware-siano firmware-ti-connectivity firmware-zd1211

chroot chroot apt-get clean
rm -f chroot/root/.bash_history
rm -rf chroot/var/lib/apt/lists/*
find chroot/var/log/ -type f | xargs rm -f

mkdir pardus
umount -lf -R chroot/* 2>/dev/null
mksquashfs chroot filesystem.squashfs -comp gzip -wildcards
mkdir -p pardus/live
mv filesystem.squashfs pardus/live/filesystem.squashfs

cp -pf chroot/boot/initrd.img-* pardus/live/initrd.img
cp -pf chroot/boot/vmlinuz-* pardus/live/vmlinuz

mkdir -p pardus/boot/grub/
echo 'menuentry "Start Pardus GNU/Linux XFCE 32-bit (Unofficial)" --class pardus {' > pardus/boot/grub/grub.cfg
echo '    linux /live/vmlinuz boot=live live-config live-media-path=/live quiet splash --' >> pardus/boot/grub/grub.cfg
echo '    initrd /live/initrd.img' >> pardus/boot/grub/grub.cfg
echo '}' >> pardus/boot/grub/grub.cfg

grub-mkrescue pardus -o pardus-gnulinux-$(date +%s).iso
