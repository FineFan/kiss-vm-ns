#!/bin/bash
# ref: https://www.thegeekdiary.com/how-to-make-centos-rhel-7-fips-140-2-compliant

## rhel-8 or later
if which fips-mode-setup; then
	fips-mode-setup --enable
	fips-mode-setup --check
## rhel-7
else
	openssl version

	cat /proc/sys/crypto/fips_enabled

	# blkid > /var/tmp/blkid_bkp_`date`
	# df -h > /var/tmp/df_bkp_`date`

	which prelink &>/dev/null && {
		sed -i 's/PRELINKING=.*/PRELINKING=yes/g' /etc/sysconfig/prelink
		prelink -a
	}

	cat /proc/cpuinfo | grep aes
	lsmod | grep aes && yum install -y dracut-fips-aesni



	yum install dracut-fips -y
	cp -p /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).backup
	dracut -f
	sed 's/GRUB_CMDLINE_LINUX="/&fips=1 /' /etc/default/grub
	grub2-mkconfig -o /boot/grub2/grub.cfg
	grub2-mkconfig -o /boot/efi/EFI/redhat/grub.cfg
fi
