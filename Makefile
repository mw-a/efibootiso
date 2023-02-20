
.PHONY: all clean distclean


all: efiboot.iso


boot/linux:
	@rm -f "$(@)"
	@mkdir -p boot
	wget -N \
	   -O "$(@)" \
	   http://ftp.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/debian-installer/amd64/linux \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


boot/initrd.gz:
	@rm -f "$(@)"
	@mkdir -p boot
	wget -N \
	   -O "$(@)" \
	   http://ftp.debian.org/debian/dists/bullseye/main/installer-amd64/current/images/netboot/debian-installer/amd64/initrd.gz \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


efiboot.img: EFI/BOOT/bootx64.efi
	@rm -f "$(@)"
	dd \
	   if=/dev/zero \
	   of="$(@)" \
	   bs=1M \
	   count=5 \
	   || { rm -f "$(@)"; exit 1; }
	mkfs.fat \
	   -F 12 \
	   -n 'EFIBOOTISO' \
	   "$(@)" \
	   || { rm -f "$(@)"; exit 1; }
	mmd \
	   -i "$(@)" \
	   ::EFI \
	   || { rm -f "$(@)"; exit 1; }
	mmd \
	   -i "$(@)" \
	   ::EFI/BOOT \
	   || { rm -f "$(@)"; exit 1; }
	mcopy \
	   -i "$(@)" \
	   EFI/BOOT/bootx64.efi \
	   ::EFI/BOOT/BOOTX64.EFI \
	   || { rm -f "$(@)"; exit 1; }
	mcopy \
	   -i "$(@)" \
	   EFI/BOOT/grubx64.efi \
	   ::EFI/BOOT/grubx64.efi \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


syslinux/isolinux.bin.mod: /usr/share/syslinux/isolinux.bin
	@mkdir -p syslinux
	cp /usr/share/syslinux/isolinux.bin "$(@)"
	@touch "$(@)"


efiboot.iso: efiboot.img syslinux/isolinux.bin.mod boot/initrd.gz boot/linux
	mkisofs \
	   -o "$(@)" \
	   -R -J -v -d -N \
	   -x '.git' \
	   -x efiboot.iso \
	   -hide-rr-moved \
	   -no-emul-boot \
	   -boot-load-size 4 \
	   -boot-info-table \
	   -b syslinux/isolinux.bin.mod \
	   -c syslinux/isolinux.boot \
	   -eltorito-alt-boot \
	   -no-emul-boot \
	   -eltorito-platform efi \
	   -eltorito-boot efiboot.img \
	   -V "EFIBOOTISO" \
	   -A "EFI Boot ISO Example"  \
	   ./ \
	   || { rm -f "$(@)"; exit 1; }
	@touch "$(@)"


clean:
	rm -f efiboot.iso
	rm -Rf syslinux EFI


distclean: clean
	rm -Rf boot


