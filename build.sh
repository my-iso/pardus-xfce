#!/usr/bin/sh
set -ex
mkdir chroot || true
export DEBIAN_FRONTEND=noninteractive
ln -s sid /usr/share/debootstrap/scripts/yirmiuc-deb || true
debootstrap  --no-check-gpg --arch=amd64 yirmiuc-deb chroot https://depo.pardus.org.tr/pardus
for i in dev dev/pts proc sys; do mount -o bind /$i chroot/$i; done

cat > chroot/etc/apt/sources.list << EOF
deb http://depo.pardus.org.tr/pardus yirmiuc main contrib non-free non-free-firmware
deb http://depo.pardus.org.tr/pardus yirmiuc-deb main contrib non-free non-free-firmware
#deb http://depo.pardus.org.tr/guvenlik yirmiuc main contrib non-free non-free-firmware
EOF


chroot chroot apt-get update --allow-insecure-repositories
chroot chroot apt-get install pardus-archive-keyring --allow-unauthenticated -y

chroot chroot apt-get update -y

chroot chroot apt-get install gnupg grub-pc-bin grub-efi-ia32-bin grub-efi -y
chroot chroot apt-get install live-config live-boot plymouth plymouth-themes -y

echo -e "#!/bin/sh\nexit 101" > chroot/usr/sbin/policy-rc.d
chmod +x chroot/usr/sbin/policy-rc.d

chroot chroot apt-get install linux-image-amd64 -y
chroot chroot apt-get install -y firmware-amd-graphics firmware-linux-free \
    firmware-linux firmware-linux-nonfree firmware-misc-nonfree firmware-realtek \
    
# xorg & desktop pkgs
chroot chroot apt-get install xserver-xorg xinit lightdm gedit gnome-terminal network-manager-gnome synaptic p7zip-full gvfs-backends xdg-user-dirs -y
chroot chroot apt-get install pardus-lightdm-greeter pardus-installer pardus-software pardus-about pardus-locales pardus-ayyildiz-grub-theme -y
chroot chroot apt-get install cinnamon -y


#### Remove bloat files after dpkg invoke (optional)
cat > chroot/etc/apt/apt.conf.d/02antibloat << EOF
DPkg::Post-Invoke {"rm -rf /usr/share/locale || true";};
DPkg::Post-Invoke {"rm -rf /usr/share/man || true";};
DPkg::Post-Invoke {"rm -rf /usr/share/help || true";};
DPkg::Post-Invoke {"rm -rf /usr/share/doc || true";};
DPkg::Post-Invoke {"rm -rf /usr/share/info || true";};
EOF

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
echo 'terminal_output console' > pardus/boot/grub/grub.cfg
echo 'menuentry "Start Pardus GNU/Linux Cinnamon (Unofficial)" --class pardus {' >> pardus/boot/grub/grub.cfg
echo '    linux /live/vmlinuz boot=live components --' >> pardus/boot/grub/grub.cfg
echo '    initrd /live/initrd.img' >> pardus/boot/grub/grub.cfg
echo '}' >> pardus/boot/grub/grub.cfg

grub-mkrescue pardus -o pardus-gnulinux-$(date +%s).iso
