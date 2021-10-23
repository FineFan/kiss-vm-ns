#!/bin/bash
# this script is used to install gm(GraphicsMagick/ImageMagick) gocr and vncdotool

[[ $(id -u) != 0 ]] && {
	echo -e "{WARN} $0 need root permission, please try:\n  sudo $0 ${@}" | GREP_COLORS='ms=1;31' grep --color=always . >&2
	exit 126
}

. /etc/os-release
OS=$NAME

case ${OS,,} in
red?hat|centos*|rocky*)
	OSV=$(rpm -E %rhel)
	if ! egrep -q '^!?epel' < <(yum repolist 2>/dev/null); then
		[[ "$OSV" != "%rhel" ]] &&
			yum $yumOpt install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-${OSV}.noarch.rpm 2>/dev/null
	fi
	;;
esac

#install gm(GraphicsMagick/ImageMagick)
! command -v gm && ! command -v convert && {
	echo -e "\n{ggv-install} install GraphicsMagick/ImageMagick ..."
	case ${OS,,} in
	fedora*|red?hat*|centos*|rocky*)
		yum $yumOpt install -y GraphicsMagick; command -v gm || yum $yumOpt install -y ImageMagick
		;;
	debian*|ubuntu*)
		apt install -o APT::Install-Suggests=0 -o APT::Install-Recommends=0 -y graphicsmagick; command -v gm || apt install -o APT::Install-Suggests=0 -o APT::Install-Recommends=0 -y imagemagick
		;;
	opensuse*|sles*)
		zypper in --no-recommends -y GraphicsMagick; command -v gm || zypper in --no-recommends -y ImageMagick
		;;
	*)
		: #fixme add more platform
		;;
	esac

	#if still install fail, try install from brew(only for RHEL intranet)
	if ! command -v gm >/dev/null && ! command -v convert >/dev/null; then
		export PATH=/usr/local/bin:$PATH
		if command -v brewinstall.sh; then
			brewinstall.sh latest-GraphicsMagick
			yum install -y lcms2 freetype libXext libSM libtool-ltdl

			rpm_list="libwmf-lite-0.2.12-5.el9.x86_64.rpm"
			for rpmf in $rpm_list; do
				brew download-build --rpm $rpmf
			done
			rpm -ivh --force --nodeps
		fi
	fi
}

#install gocr
echo
! command -v gocr && {
	echo -e "\n{ggv-install} install gocr ..."

	case ${OS,,} in
	fedora*|red?hat*|centos*|rocky*)
		yum $yumOpt install -y gocr;;
	debian*|ubuntu*)
		apt install -o APT::Install-Suggests=0 -o APT::Install-Recommends=0 -y gocr;;
	opensuse*|sles*)
		zypper in --no-recommends -y gocr;;
	*)
		:;; #fixme add more platform
	esac

	command -v gocr || {
		echo -e "\n{ggv-install} install gocr from src ..."
		case ${OS,,} in
		fedora*|red?hat*|centos*|rocky*)
			yum $yumOpt install -y autoconf gcc make netpbm-progs;;
		debian*|ubuntu*)
			apt install -o APT::Install-Suggests=0 -o APT::Install-Recommends=0 -y autoconf gcc make netpbm;;
		opensuse*|sles*)
			zypper in --no-recommends -y autoconf gcc make netpbm;;
		*)
			:;; #fixme add more platform
		esac

		while true; do
			rm -rf gocr
			_url=https://github.com/tcler/gocr
			while ! git clone --depth=1 $_url; do [[ -d gocr ]] && break || sleep 5; done
			(
			cd gocr
			./configure --prefix=/usr && make && make install
			)
			command -v gocr && break

			sleep 5
			echo -e " {ggv-install} installing gocr fail, try again ..."
		done
	}
}

#install vncdotool
echo
! command -v vncdo && {
	echo -e "\n{ggv-install} install vncdotool ..."
	case ${OS,,} in
	fedora*|red?hat*|centos*|rocky*)
		yum $yumOpt --setopt=strict=0 install -y python-devel python-pip platform-python-devel python3-pip;;
	debian*|ubuntu*)
		apt install -o APT::Install-Suggests=0 -o APT::Install-Recommends=0 -y python-pip python3-pip;;
	opensuse*|sles*)
		zypper in --no-recommends -y python-pip python3-pip;;
	*)
		:;; #fixme add more platform
	esac

	PIP=$(command -v pip3)
	command -v pip3 || PIP=$(command -v pip)
	$PIP --default-timeout=720 install --upgrade pip
	$PIP --default-timeout=720 install --upgrade setuptools
	$PIP --default-timeout=720 install vncdotool service_identity
}
