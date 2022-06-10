#!/bin/sh

MKSQSHFS4='mksquashfs'
PADJFFS2='padjffs2'
UNSQSHFS='unsquashfs'

case "$1" in
'extract'|'e')
	offset1="$(grep -oba hsqs "$2" | grep -oP '[0-9]*(?=:hsqs)')"
	offset2="$(wc -c "$2" | grep -oP '[0-9]*(?= )')"
	size2="$((offset2 - offset1))"
	#echo $offset1 " " $offset2 " " $size2
	dd if="$2" of="kernel.bin" bs=1 ibs=1 count="$offset1"
	dd if="$2" of="secondchunk.bin" bs=1 ibs=1 count="$size2" skip="$offset1"
	fakeroot rm -rf "squashfs-root" 2>&1
	fakeroot $UNSQSHFS -d "squashfs-root" "secondchunk.bin"
	rm "secondchunk.bin"
	;;
'create'|'c')
	fakeroot $MKSQSHFS4 "./squashfs-root" "./newsecondchunk.bin"
	fakeroot chown "$USER" "./newsecondchunk.bin"
	cat "kernel.bin" "newsecondchunk.bin" > "$2"
	$PADJFFS2 "$2"
	rm "newsecondchunk.bin"
	;;
*)
	echo "Run \"$0 extract firmware.bin\" you will find file \"kernel.bin\" and folder \"squashfs-root\". Modify \"squashfs-root\" as you like.
After everything is done, run \"$0 create newfirmware.bin\" and you will get a modified firmware named \"newfirmware.bin\"."
	;;
esac
