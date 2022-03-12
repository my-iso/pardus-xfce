#!/usr/bin/sh
set -ex
mkdir chroot || true
export DEBIAN_FRONTEND=noninteractive
ln -s sid /usr/share/debootstrap/scripts/yirmibir || true
debootstrap  --no-check-gpg --no-merged-usr --arch=i386 yirmibir chroot https://depo.pardus.org.tr/pardus
for i in dev dev/pts proc sys; do mount -o bind /$i chroot/$i; done
chroot chroot apt-get update -y
chroot chroot apt-get install gnupg -y

chroot chroot apt-get install grub-pc-bin grub-efi-ia32 -y
chroot chroot apt-get install live-config live-boot linux-image-686-pae -y

# xorg & desktop pkgs
chroot chroot apt-get install xserver-xorg xinit lightdm lightdm-gtk-greeter network-manager-gnome pulseaudio -y
chroot chroot apt-get install xfce4 pardus-xfce-settings sudo thunar-archive-plugin xfce4-whiskermenu-plugin firefox-esr xfce4-terminal mousepad -y
chroot chroot apt-get install pardus-gtk-theme pardus-icon-theme pardus-dolunay-grub-theme -y

wget -O chroot/tmp/17g.deb https://github.com/PuffOS/17g-installer/releases/download/current/17g-installer_1.0_all.deb
chroot chroot dpkg -i /tmp/17g.deb || true
chroot chroot apt install -f -y

#### Remove bloat files after dpkg invoke (optional)
cat > chroot/etc/apt/apt.conf.d/02antibloat << EOF
DPkg::Post-Invoke {"rm -rf /usr/share/locale || true";};
DPkg::Post-Invoke {"rm -rf /usr/share/man || true";};
DPkg::Post-Invoke {"rm -rf /usr/share/help || true";};
DPkg::Post-Invoke {"rm -rf /usr/share/doc || true";};
DPkg::Post-Invoke {"rm -rf /usr/share/info || true";};
EOF

### Block boot if cpu is 64bit
cat > chroot/sbin/init-check << EOF
#!/bin/bash
clear
if grep -e "[, ]lm[, ]" /proc/cpuinfo >/dev/null ; then
    echo "Your CPU is 64bit."
    echo "Boot blocked."
    exec sleep inf
fi
exec /sbin/init $@
EOF
chmod +x chroot/sbin/init-check

echo "deb http://depo.pardus.org.tr/pardus ondokuz main contrib non-free" > chroot/etc/apt/sources.list
echo "deb http://depo.pardus.org.tr/guvenlik ondokuz main contrib non-free" >> chroot/etc/apt/sources.list
echo "deb http://depo.pardus.org.tr/pardus yirmibir main contrib non-free" > chroot/etc/apt/sources.list
echo "deb http://depo.pardus.org.tr/guvenlik yirmibir main contrib non-free" >> chroot/etc/apt/sources.list
chroot chroot apt-get update -y
chroot chroot apt-get full-upgrade -y
chroot chroot apt-get install -y firmware-amd-graphics firmware-atheros \
    firmware-b43-installer firmware-b43legacy-installer \
    firmware-bnx2 firmware-bnx2x firmware-brcm80211 firmware-linux-free \
    firmware-cavium firmware-intel-sound firmware-intelwimax \
    firmware-iwlwifi  firmware-libertas firmware-linux \
    firmware-linux-nonfree firmware-misc-nonfree firmware-myricom \
    firmware-netxen firmware-qlogic firmware-realtek firmware-samsung \
    firmware-siano firmware-ti-connectivity firmware-zd1211

chroot chroot apt-get clean
rm -f chroot/root/.bash_history
rm -rf chroot/var/lib/apt/lists/*
find chroot/var/log/ -type f | xargs rm -f

mkdir pardus || true
while umount -lf -R chroot/* 2>/dev/null ; do
 : "Umount action"
done
mksquashfs chroot filesystem.squashfs -comp gzip -wildcards
find chroot/var/log/ -type f | xargs rm -f
mkdir -p pardus/live
mv filesystem.squashfs pardus/live/filesystem.squashfs

cp -pf chroot/boot/initrd.img-* pardus/live/initrd.img
cp -pf chroot/boot/vmlinuz-* pardus/live/vmlinuz

mkdir -p pardus/boot/grub/
echo 'menuentry "Start Pardus GNU/Linux XFCE 32-bit (Unofficial)" --class pardus {' > pardus/boot/grub/grub.cfg
echo '    linux /live/vmlinuz boot=live components timezone=Europe/Istanbul locales=tr_TR.UTF-8,en_US.UTF-8 keyboard-layouts=tr username=pardus hostname=pardus user-fullname=Pardus noswap init=sbin/init-check quiet --' >> pardus/boot/grub/grub.cfg
echo '    initrd /live/initrd.img' >> pardus/boot/grub/grub.cfg
echo '}' >> pardus/boot/grub/grub.cfg

grub-mkrescue pardus -o pardus-gnulinux-$(date +%s).iso
