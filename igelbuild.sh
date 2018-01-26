#!/bin/sh

#set -x

export VENDOR_CERT_FILE=../igel-efi-pub-key.der

export NO_MOK_MANAGER="true"
export NO_FALLBACK="true"
export EFIBOOTDIR='$(ESPROOTDIR)efi/boot/'
export EFIDIR='igel'
export TARGETDIR='$(ESPROOTDIR)efi/$(EFIDIR)/'
export BOOTEFINAME='boot$(ARCH_SUFFIX).efi'
export BOOTCSVNAME='boot$(ARCH_SUFFIX).csv'
export DEFAULT_LOADER='igel$(ARCH_SUFFIX).efi'

EFI32_PATH=/usr/lib32
EFI64_PATH=/usr/lib

LOG_FILE="shim_igelbuild_$(date +%Y%m%d_%H%m%S).log"

if [ "$1" = "distclean" ] ; then
	set -x
	rm -rf build-ia32 build-x64 inst-ia32 inst-x64
	exit $?
fi

if [ "$1" = "clean" ] ; then
	set -x
	rm -rf build-ia32 build-x64
	exit $?
fi

if [ "$1" = "cp" -o "$1" = "scp" ] ; then
	IGELMAKER="$2"
	SHIMPATH="modules/xenial/igel/shim-efi-bin"
	if [ "$1" = "cp" -a ! -d "$IGELMAKER" ] ; then
		echo "IGELMAKER path does not exist!!!"
		exit 1
	fi
	echo "$1" inst-x64/boot/efi/efi/boot/bootx64.efi "$IGELMAKER/$SHIMPATH/arch/amd64/data/root/efi/boot/"
	"$1" inst-x64/boot/efi/efi/boot/bootx64.efi "$IGELMAKER/$SHIMPATH/arch/amd64/data/root/efi/boot/"
	echo "$1" inst-ia32/boot/efi/efi/boot/bootia32.efi "$IGELMAKER/$SHIMPATH/arch/amd64/data/root/efi/boot/"
	"$1" inst-ia32/boot/efi/efi/boot/bootia32.efi "$IGELMAKER/$SHIMPATH/arch/amd64/data/root/efi/boot/"
	if [ "$1" = "cp" -a "$IGELMAKER/$SHIMPATH/arch/amd64/src/shim_igelbuild_"*".log" = "" ] ; then
		svn rm --force "$IGELMAKER/$SHIMPATH/arch/amd64/src/shim_igelbuild_"*".log"
	fi
	echo "$1" shim_igelbuild_*.log "$IGELMAKER/$SHIMPATH/arch/amd64/src/"
	"$1" shim_igelbuild_*.log "$IGELMAKER/$SHIMPATH/arch/amd64/src/"
	if [ "$1" = "cp" ] ; then
		svn add "$IGELMAKER/$SHIMPATH/arch/amd64/src/shim_igelbuild_"*".log"
	fi
	exit $?
fi

if [ "$1" != "build" ] ; then
	echo "Usage: $0 build|cp|scp|clean|distclean"
	exit 1
fi

mkdir -p build-ia32 build-x64 inst-ia32 inst-x64

for crypt in $(find Cryptlib -type d) ; do
mkdir -p build-ia32/"$crypt" build-x64/"$crypt"
done

(
echo "=============================================="
echo "Toolchain:"
echo "=============================================="
dpkg -s gnu-efi gcc gcc-multilib

echo
echo "=============================================="
echo "Build-Log:"
echo "=============================================="

cd build-ia32
setarch linux32 make TOPDIR=.. ARCH=ia32 -f ../Makefile EFI_PATH="$EFI32_PATH"
setarch linux32 make TOPDIR=.. ARCH=ia32 DESTDIR=../inst-ia32 EFI_PATH="$EFI32_PATH" -f ../Makefile install

cd ../build-x64
make TOPDIR=.. -f ../Makefile EFI_PATH="$EFI64_PATH"
make TOPDIR=.. DESTDIR=../inst-x64 EFI_PATH="$EFI64_PATH" -f ../Makefile install
) 2>&1 | tee "$LOG_FILE"

echo
echo "================================================================================="
echo "NOTE: Build log can be found in \"$LOG_FILE\""
echo "================================================================================="
echo
