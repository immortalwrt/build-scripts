#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function set_fonts_colors(){
	default_fontcolor="\033[0m"
	red_fontcolor="\033[31m"
	green_fontcolor="\033[32m"
	warning_fontcolor="\033[33m"
	info_fontcolor="\033[36m"

	error_font="${red_fontcolor}[Error]${default_fontcolor} "
	ok_font="${green_fontcolor}[OK]${default_fontcolor} "
	warning_font="${warning_fontcolor}[Warning]${default_fontcolor} "
	info_font="${info_fontcolor}[Info]${default_fontcolor} "
}

function check_system(){
	echo -e "${info_font}Checking system info..."

	if grep -qo "Ubuntu 18.04" "/etc/issue"; then
		ubuntu_release="bionic"
	elif grep -qo "Ubuntu 20.04" "/etc/issue"; then
		ubuntu_release="focal"
	else
		echo -e "${error_font}Only Ubuntu 18.04 and 20.24 are supported."
		exit 1
	fi
	[ "$(uname -m)" != "x86_64" ] && { echo -e "${error_font}Only x86_64 is supported." && exit 1; }

	echo -e "${ok_font}Done."
}

function check_user(){
	echo -e "${info_font}Checking user info..."

	[ "$(whoami)" != "root" ] && { echo -e "${error_font}You must run as root." && exit 1; }

	echo -e "${ok_font}Done."
}

function check_network(){
	echo -e "${info_font}Checking network..."

	curl -s "myip.ipip.net" | grep -qo "中国" && country_cn="Y"
	curl --connect-timeout 10 "baidu.com" > "/dev/null" 2>&1 || { echo -e "${warning_font}Your network is not suitable for compiling OpenWrt!"; }
	curl --connect-timeout 10 "google.com" > "/dev/null" 2>&1 || { echo -e "${warning_font}Your network is not suitable for compiling OpenWrt!"; }

	echo -e "${ok_font}Done."
}

function update_apt_source(){
	echo -e "${info_font}Updating apt source lists..."

	mkdir -p "/etc/apt/sources.list.d"
	[ -n "${country_cn}" ] && {
		mv "/etc/apt/sources.list" "/etc/apt/sources.list.bak"
		cat <<-EOF >"/etc/apt/sources.list"
			deb http://mirrors.tencent.com/ubuntu/ ${ubuntu_release} main restricted universe multiverse
			deb http://mirrors.tencent.com/ubuntu/ ${ubuntu_release}-security main restricted universe multiverse
			deb http://mirrors.tencent.com/ubuntu/ ${ubuntu_release}-updates main restricted universe multiverse
			deb http://mirrors.tencent.com/ubuntu/ ${ubuntu_release}-backports main restricted universe multiverse
			# deb http://mirrors.tencent.com/ubuntu/ ${ubuntu_release}-proposed main restricted universe multiverse
			deb-src http://mirrors.tencent.com/ubuntu/ ${ubuntu_release} main restricted universe multiverse
			deb-src http://mirrors.tencent.com/ubuntu/ ${ubuntu_release}-security main restricted universe multiverse
			deb-src http://mirrors.tencent.com/ubuntu/ ${ubuntu_release}-updates main restricted universe multiverse
			deb-src http://mirrors.tencent.com/ubuntu/ ${ubuntu_release}-backports main restricted universe multiverse
			# deb-src http://mirrors.tencent.com/ubuntu/ ${ubuntu_release}-proposed main restricted universe multiverse
		EOF
	}

	cat <<-EOF >"/etc/apt/sources.list.d/nodesource.list"
		deb https://deb.nodesource.com/node_14.x ${ubuntu_release} main
		deb-src https://deb.nodesource.com/node_14.x ${ubuntu_release} main
	EOF
	curl -sL "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" | apt-key add -

	cat <<-EOF >"/etc/apt/sources.list.d/yarn.list"
		deb https://dl.yarnpkg.com/debian/ stable main
	EOF
	curl -sL "https://dl.yarnpkg.com/debian/pubkey.gpg" | apt-key add -

	cat <<-EOF >"/etc/apt/sources.list.d/gcc-toolchain.list"
		deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${ubuntu_release} main
		deb-src http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu ${ubuntu_release} main
	EOF
	curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1e9377a2ba9ef27f" | apt-key add -

	cat <<-EOF >"/etc/apt/sources.list.d/longsleep-ubuntu-golang-backports-${ubuntu_release}.list"
		deb http://ppa.launchpad.net/longsleep/golang-backports/ubuntu ${ubuntu_release} main
		deb-src http://ppa.launchpad.net/longsleep/golang-backports/ubuntu ${ubuntu_release} main
	EOF
	curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x52b59b1571a79dbc054901c0f6bc817356a3d45e" | apt-key add -

	[ -n "${country_cn}" ] && sed -i "s#http://ppa.launchpad.net#https://launchpad.proxy.ustclug.org#g" "/etc/apt/sources.list.d"/*

	apt update -y

	echo -e "${ok_font}Done."
}
function install_compilation_dependencies(){
	echo -e "Installing compilation dependencies..."

	apt full-upgrade -y
	[ "${ubuntu_release}" = "focal" ] && extra_packages="python2.7" || extra_packages="python python-pip python-ply"
	apt install -y ack build-essential asciidoc binutils bzip2 cmake gawk gettext git libncurses5-dev libz-dev patch unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core p7zip p7zip-full msmtp libssl-dev texinfo libreadline-dev libglib2.0-dev xmlto qemu-utils libelf-dev autoconf automake libtool autopoint ccache curl wget vim nano ${extra_packages} python3 python3-pip python3-ply haveged lrzsz device-tree-compiler scons squashfs-tools antlr3 gperf ecj fastjar re2c intltool xxd help2man pkgconf libgmp3-dev libmpc-dev libmpfr-dev libncurses5-dev libltdl-dev python-docutils cpio bison rsync mkisofs ninja-build

	apt install -y gcc-8 g++-8 gcc-8-multilib g++-8-multilib
	ln -sf "/usr/bin/gcc-8" "/usr/bin/gcc"
	ln -sf "/usr/bin/g++-8" "/usr/bin/g++"
	ln -sf "/usr/bin/gcc-ar-8" "/usr/bin/gcc-ar"
	ln -sf "/usr/bin/gcc-nm-8" "/usr/bin/gcc-nm"
	ln -sf "/usr/bin/gcc-ranlib-8" "/usr/bin/gcc-ranlib"

	apt install -y nodejs yarn
	[ -n "${country_cn}" ] && {
		npm config set registry "https://registry.npm.taobao.org/" --global
		yarn config set registry "https://registry.npm.taobao.org/" --global
	}

	apt install -y golang-1.16-go
	ln -sf "/usr/lib/go-1.16/bin/go" "/usr/bin/go"
	ln -sf "/usr/lib/go-1.16/bin/gofmt" "/usr/bin/gofmt"

	apt clean -y

	upx_version="3.95"
	curl -sL "https://github.com/upx/upx/releases/download/v${upx_version}/upx-${upx_version}-amd64_linux.tar.xz" -o "/tmp/upx-${upx_version}-amd64_linux.tar.xz"
	tar -xf "/tmp/upx-${upx_version}-amd64_linux.tar.xz" -C "/tmp/"
	rm -f "/usr/bin/upx" "/usr/bin/upx-ucl"
	mv "/tmp/upx-${upx_version}-amd64_linux/upx" "/usr/bin/upx-ucl"
	chmod 0755 "/usr/bin/upx-ucl"
	ln -sf "/usr/bin/upx-ucl" "/usr/bin/upx"
	rm -rf "/tmp/upx-${upx_version}-amd64_linux.tar.xz" "/tmp/upx-${upx_version}-amd64_linux"

	curl -sL "https://build-scripts.project-openwrt.eu.org/init_build_environment/modify-firmware" -o "/usr/bin/modify-firmware"
	chmod 0755 "/usr/bin/modify-firmware"
	curl -sL "https://build-scripts.project-openwrt.eu.org/init_build_environment/po2lmo" -o "/usr/bin/po2lmo"
	chmod 0755 "/usr/bin/po2lmo"
	curl -sL "https://build-scripts.project-openwrt.eu.org/init_build_environment/padjffs2" -o "/usr/bin/padjffs2"
	chmod 0755 "/usr/bin/padjffs2"
	curl -sL "https://build-scripts.project-openwrt.eu.org/init_build_environment/fip_create" -o "/usr/bin/fip_create"
	chmod 0755 "/usr/bin/fip_create"

	echo -e "Done."
}
function main(){
	set_fonts_colors
	check_system
	check_user
	check_network
	update_apt_source
	install_compilation_dependencies
	echo -e "${ok_font}The dependencies of compiling OpenWrt are all installed, thanks for using."
}

main
