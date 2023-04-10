#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
#
# Copyright (C) ImmortalWrt.org

DEFAULT_COLOR="\033[0m"
BLUE_COLOR="\033[36m"
GREEN_COLOR="\033[32m"
RED_COLOR="\033[31m"
YELLOW_COLOR="\033[33m"

function __error_msg() {
	echo -e "${RED_COLOR}[ERROR]${DEFAULT_COLOR} $*"
}

function __info_msg() {
	echo -e "${BLUE_COLOR}[INFO]${DEFAULT_COLOR} $*"
}

function __success_msg() {
	echo -e "${GREEN_COLOR}[SUCCESS]${DEFAULT_COLOR} $*"
}

function __warning_msg() {
	echo -e "${YELLOW_COLOR}[WARNING]${DEFAULT_COLOR} $*"
}

function check_system(){
	__info_msg "Checking system info..."

	UBUNTU_CODENAME="$(source /etc/os-release; echo "$UBUNTU_CODENAME")"
	case "$UBUNTU_CODENAME" in
	"bionic"|"focal"|"jammy")
		# Nothing to do
		;;
	*)
		__error_msg "Unsupported OS, use Ubuntu 20.04 instead."
		exit 1
		;;
	esac

	[ "$(uname -m)" != "x86_64" ] && { __error_msg "Unsupported architecture, use AMD64 instead." && exit 1; }

	[ "$(whoami)" != "root" ] && { __error_msg "You must run me as root." && exit 1; }
}

function check_network(){
	__info_msg "Checking network..."

	curl -s "myip.ipip.net" | grep -qo "中国" && CHN_NET=1
	curl --connect-timeout 10 "baidu.com" > "/dev/null" 2>&1 || { __warning_msg "Your network is not suitable for compiling OpenWrt!"; }
	curl --connect-timeout 10 "google.com" > "/dev/null" 2>&1 || { __warning_msg "Your network is not suitable for compiling OpenWrt!"; }
}

function update_apt_source(){
	__info_msg "Updating apt source lists..."
	set -x

	apt update -y
	apt install -y apt-transport-https gnupg2
	[ -n "$CHN_NET" ] && {
		mv "/etc/apt/sources.list" "/etc/apt/sources.list.bak"
		cat <<-EOF >"/etc/apt/sources.list"
			deb http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
			deb http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
			deb http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
			# deb http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME-proposed main restricted universe multiverse
			deb http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME-backports main restricted universe multiverse
			deb-src http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME main restricted universe multiverse
			deb-src http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME-security main restricted universe multiverse
			deb-src http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME-updates main restricted universe multiverse
			deb-src http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME-backports main restricted universe multiverse
			# deb-src http://mirrors.tencent.com/ubuntu/ $UBUNTU_CODENAME-proposed main restricted universe multiverse
		EOF
	}

	mkdir -p "/etc/apt/sources.list.d"

	cat <<-EOF >"/etc/apt/sources.list.d/nodesource.list"
		deb https://deb.nodesource.com/node_18.x $UBUNTU_CODENAME main
		deb-src https://deb.nodesource.com/node_18.x $UBUNTU_CODENAME main
	EOF
	curl -sL "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" -o "/etc/apt/trusted.gpg.d/nodesource.asc"

	cat <<-EOF >"/etc/apt/sources.list.d/yarn.list"
		deb https://dl.yarnpkg.com/debian/ stable main
	EOF
	curl -sL "https://dl.yarnpkg.com/debian/pubkey.gpg" -o "/etc/apt/trusted.gpg.d/yarn.asc"

	cat <<-EOF >"/etc/apt/sources.list.d/gcc-toolchain.list"
		deb http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu $UBUNTU_CODENAME main
		deb-src http://ppa.launchpad.net/ubuntu-toolchain-r/test/ubuntu $UBUNTU_CODENAME main
	EOF
	curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x1e9377a2ba9ef27f" -o "/etc/apt/trusted.gpg.d/gcc-toolchain.asc"

	cat <<-EOF >"/etc/apt/sources.list.d/llvm-toolchain.list"
		deb http://apt.llvm.org/$UBUNTU_CODENAME/ llvm-toolchain-$UBUNTU_CODENAME-15 main
		deb-src http://apt.llvm.org/$UBUNTU_CODENAME/ llvm-toolchain-$UBUNTU_CODENAME-15 main
	EOF
	curl -sL "https://apt.llvm.org/llvm-snapshot.gpg.key" -o "/etc/apt/trusted.gpg.d/llvm-toolchain.asc"

	cat <<-EOF >"/etc/apt/sources.list.d/longsleep-ubuntu-golang-backports-$UBUNTU_CODENAME.list"
		deb http://ppa.launchpad.net/longsleep/golang-backports/ubuntu $UBUNTU_CODENAME main
		deb-src http://ppa.launchpad.net/longsleep/golang-backports/ubuntu $UBUNTU_CODENAME main
	EOF
	curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x52b59b1571a79dbc054901c0f6bc817356a3d45e" -o "/etc/apt/trusted.gpg.d/longsleep-ubuntu-golang-backports-$UBUNTU_CODENAME.asc"

	[ -n "$CHN_NET" ] && sed -i "s,http://ppa.launchpad.net,https://launchpad.proxy.ustclug.org,g" "/etc/apt/sources.list.d"/*

	apt update -y

	set +x
}
function install_dependencies(){
	__info_msg "Installing dependencies..."
	set -x

	apt full-upgrade -y
	apt install -y ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
		bzip2 ccache cmake cpio curl device-tree-compiler ecj fakeroot fastjar flex gawk gettext git \
		gnutls-dev gperf haveged help2man intltool jq libc6-dev-i386 libelf-dev lib32gcc-s1 libglib2.0-dev \
		libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5 libncursesw5-dev \
		libreadline-dev libssl-dev libtool libyaml-dev libz-dev lrzsz mkisofs msmtp nano ninja-build \
		p7zip p7zip-full patch pkgconf python2 libpython3-dev python3 python3-pip python3-ply python3-docutils \
		python3-pyelftools qemu-utils quilt re2c rsync scons squashfs-tools subversion swig texinfo uglifyjs \
		unzip vim wget xmlto xxd zlib1g-dev

	apt install -y gcc-9 g++-9 gcc-9-multilib g++-9-multilib
	ln -svf "/usr/bin/gcc-9" "/usr/bin/gcc"
	ln -svf "/usr/bin/g++-9" "/usr/bin/g++"
	ln -svf "/usr/bin/gcc-ar-9" "/usr/bin/gcc-ar"
	ln -svf "/usr/bin/gcc-nm-9" "/usr/bin/gcc-nm"
	ln -svf "/usr/bin/gcc-ranlib-9" "/usr/bin/gcc-ranlib"
	ln -svf "/usr/bin/g++" "/usr/bin/c++"
	[ -e "/usr/include/asm" ] || ln -svf "/usr/include/$(gcc -dumpmachine)/asm" "/usr/include/asm"

	apt install -y clang-15 lld-15 libclang-15-dev
	ln -svf "/usr/bin/clang-15" "/usr/bin/clang"
	ln -svf "/usr/bin/clang++-15" "/usr/bin/clang++"
	ln -svf "/usr/bin/clang-cpp-15" "/usr/bin/clang-cpp"

	apt install -y llvm-15
	for i in "/usr/bin"/llvm-*-15; do
		ln -svf "$i" "${i%-15}"
	done

	apt install -y nodejs yarn
	[ -n "$CHN_NET" ] && {
		npm config set registry "https://mirrors.tencent.com/npm/" --global
		yarn config set registry "https://mirrors.tencent.com/npm/" --global
	}

	apt install -y golang-1.20-go
	rm -rf "/usr/bin/go" "/usr/bin/gofmt"
	ln -svf "/usr/lib/go-1.20/bin/go" "/usr/bin/go"
	ln -svf "/usr/lib/go-1.20/bin/gofmt" "/usr/bin/gofmt"

	apt clean -y

	if TMP_DIR="$(mktemp -d)"; then
		pushd "$TMP_DIR"
	else
		__error_msg "Failed to create a tmp directory."
		exit 1
	fi

	UPX_REV="4.0.1"
	curl -fLO "https://github.com/upx/upx/releases/download/v${UPX_REV}/upx-$UPX_REV-amd64_linux.tar.xz"
	tar -Jxf "upx-$UPX_REV-amd64_linux.tar.xz"
	rm -rf "/usr/bin/upx" "/usr/bin/upx-ucl"
	cp -fp "upx-$UPX_REV-amd64_linux/upx" "/usr/bin/upx-ucl"
	chmod 0755 "/usr/bin/upx-ucl"
	ln -svf "/usr/bin/upx-ucl" "/usr/bin/upx"

	svn co -r96154 "https://github.com/openwrt/openwrt/trunk/tools/padjffs2/src" "padjffs2"
	pushd "padjffs2"
	make
	rm -rf "/usr/bin/padjffs2"
	cp -fp "padjffs2" "/usr/bin/padjffs2"
	popd

	svn co -r19250 "https://github.com/openwrt/luci/trunk/modules/luci-base/src" "po2lmo"
	pushd "po2lmo"
	make po2lmo
	rm -rf "/usr/bin/po2lmo"
	cp -fp "po2lmo" "/usr/bin/po2lmo"
	popd

	curl -fL "https://build-scripts.immortalwrt.eu.org/modify-firmware.sh" -o "/usr/bin/modify-firmware"
	chmod 0755 "/usr/bin/modify-firmware"

	popd
	rm -rf "$TMP_DIR"

	set +x
	__success_msg "All dependencies have been installed."
}
function main(){
	check_system
	check_network
	update_apt_source
	install_dependencies
}

main
