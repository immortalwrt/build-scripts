#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

function set_fonts_colors(){
	# Font colors
	default_fontcolor="\033[0m"
	red_fontcolor="\033[31m"
	green_fontcolor="\033[32m"
	warning_fontcolor="\033[33m"
	info_fontcolor="\033[36m"
	# Fonts
	error_font="${red_fontcolor}[Error]${default_fontcolor} "
	ok_font="${green_fontcolor}[OK]${default_fontcolor} "
	warning_font="${warning_fontcolor}[Warning]${default_fontcolor} "
	info_font="${info_fontcolor}[Info]${default_fontcolor} "
}

function check_system(){
	( grep -o "Ubuntu 18.04" "/etc/issue" >/dev/null 2>&1; ) || { echo -e "${error_font}Your OS is not supported." && exit 1; }
	[ "$(uname -m)" != "x86_64" ] && { echo -e "${error_font}Your Arch is not supported." && exit 1; }
}

function check_user(){
	[ "$(whoami)" != "root" ] && { echo -e "${error_font}You must run as root." && exit 1; }
}

function check_network(){
	( curl -s myip.ipip.net|grep -o "中国" >/dev/null 2>&1; ) || { echo -e "${error_font}The script is for Chinese only." && exit 1; }
	( curl --connect-timeout 10 baidu.com >/dev/null 2>&1; ) || { echo -e "${warning_font}Your network is not suitable for compiling OpenWrt!"; }
	( curl --connect-timeout 10 google.com >/dev/null 2>&1; ) || { echo -e "${warning_font}Your network is not suitable for compiling OpenWrt!"; }
}

function install_base_tools(){
	echo -e "${info_font}Installing base tools..."
	apt update -y
	apt install -y curl
	echo -e "${ok_font}Done."
}

function update_apt_source(){
	echo -e "${info_font}Updating apt source lists..."
	mkdir -p "/etc/apt/sources.list.d"
	mv "/etc/apt/sources.list" "/etc/apt/sources.list.bak"
	cat <<-EOF >"/etc/apt/sources.list"
# See http://help.ubuntu.com/community/UpgradeNotes for how to upgrade to
# newer versions of the distribution.
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic main restricted
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic main restricted
## Major bug fix updates produced after the final release of the
## distribution.
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-updates main restricted
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-updates main restricted
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team. Also, please note that software in universe WILL NOT receive any
## review or updates from the Ubuntu security team.
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic universe
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic universe
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-updates universe
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-updates universe
## N.B. software from this repository is ENTIRELY UNSUPPORTED by the Ubuntu
## team, and may not be under a free licence. Please satisfy yourself as to
## your rights to use the software. Also, please note that software in
## multiverse WILL NOT receive any review or updates from the Ubuntu
## security team.
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-updates multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-updates multiverse
## N.B. software from this repository may not have been tested as
## extensively as that contained in the main release, although it includes
## newer versions of some applications which may provide useful features.
## Also, please note that software in backports WILL NOT receive any review
## or updates from the Ubuntu security team.
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-backports main restricted universe multiverse
## Uncomment the following two lines to add software from Canonical's
## 'partner' repository.
## This software is not part of Ubuntu, but is offered by Canonical and the
## respective vendors as a service to Ubuntu users.
# deb http://archive.canonical.com/ubuntu bionic partner
# deb-src http://archive.canonical.com/ubuntu bionic partner
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-security main restricted
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-security main restricted
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-security universe
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-security universe
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-security multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic-security multiverse
	EOF

	cat <<-EOF >"/etc/apt/sources.list.d/nodesource.list"
deb https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb_12.x bionic main
deb-src https://mirrors.tuna.tsinghua.edu.cn/nodesource/deb_12.x bionic main
	EOF
	curl -sL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -

	cat <<-EOF >"/etc/apt/sources.list.d/yarn.list"
deb https://dl.yarnpkg.com/debian/ stable main
	EOF
	curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -

	cat <<-EOF >"/etc/apt/sources.list.d/gcc-toolchain.list"
deb https://launchpad.proxy.ustclug.org/ubuntu-toolchain-r/test/ubuntu bionic main
deb-src https://launchpad.proxy.ustclug.org/ubuntu-toolchain-r/test/ubuntu bionic main
	EOF
	curl -sL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1e9377a2ba9ef27f'| apt-key add -

	cat <<-EOF >"/etc/apt/sources.list.d/longsleep-ubuntu-golang-backports-bionic.list"
deb https://launchpad.proxy.ustclug.org/longsleep/golang-backports/ubuntu bionic main
deb-src https://launchpad.proxy.ustclug.org/longsleep/golang-backports/ubuntu bionic main
	EOF
	curl -sL 'https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x52b59b1571a79dbc054901c0f6bc817356a3d45e'| apt-key add -

	apt update -y
	echo -e "${ok_font}Done."
}
function install_compilation_dependencies(){
	echo -e "Installing compilation dependencies..."
	apt upgrade -y
	apt install -y build-essential asciidoc binutils bzip2 gawk gettext git libncurses5-dev libz-dev patch unzip zlib1g-dev lib32gcc1 libc6-dev-i386 subversion flex uglifyjs git-core p7zip p7zip-full msmtp libssl-dev texinfo libreadline-dev libglib2.0-dev xmlto qemu-utils upx libelf-dev autoconf automake libtool autopoint ccache curl wget vim nano python python3 python-pip python3-pip python-ply python3-ply haveged lrzsz device-tree-compiler scons
	apt install -y gcc-8 gcc++-8 gcc-8-multilib g++-8-multilib
	ln -sf /usr/bin/gcc-8 /usr/bin/gcc
	ln -sf /usr/bin/g++-8 /usr/bin/g++
	ln -sf /usr/bin/gcc-ar-8 /usr/bin/gcc-ar
	ln -sf /usr/bin/gcc-nm-8 /usr/bin/gcc-nm
	ln -sf /usr/bin/gcc-ranlib-8 /usr/bin/gcc-ranlib
	apt install nodejs yarn -y
	npm config set registry "https://registry.npm.taobao.org/"
	yarn config set registry "https://registry.npm.taobao.org/"
	apt install golang-1.13-go
	ln -sf /usr/lib/go-1.13/bin/go /usr/bin/go
	ln -sf /usr/lib/go-1.13/bin/gofmt /usr/bin/gofmt
	apt clean -y
	echo -e "Done."
}
function main(){
	set_fonts_colors
	check_system
	check_user
	check_network
	install_base_tools
	update_apt_source
	install_compilation_dependencies
	echo -e "${ok_font}The dependencies of compiling OpenWrt are installed, thanks for using."
}

main