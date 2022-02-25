#!/bin/sh

#This script downloads Debians's iso and makes it auto-install
#Requires:
#	- 'xorriso' installed
#	  sudo apt install xorriso
#	- preseed.cfg
#	  1) Look at example http://www.debian.org/releases/stretch/example-preseed.txt
#	  2) Read manual https://www.debian.org/releases/stable/i386/apb.html
#	  3) Install manually and then export preseed answers:
#	     sudo apt-get install debconf-utils
#	     debconf-get-selections --installer >> preseed.cfg

#####[ MD5 Fix func ]#####
fixSum() {
	FILE=$1
	PLACE=$2

	MD5_LINE_BEFORE=$( grep "$PLACE" md5sum.txt)
	MD5_BEFORE=$( echo "$MD5_LINE_BEFORE" | awk '{ print $1 }' )
	MD5_AFTER=$( md5sum "$FILE" | awk '{ print $1 }' )
	MD5_LINE_AFTER=$( echo "$MD5_LINE_BEFORE" | sed -e "s#$MD5_BEFORE#$MD5_AFTER#" )
	sed -i -e "s#$MD5_LINE_BEFORE#$MD5_LINE_AFTER#" md5sum.txt
}

#####[ Getting latest iso ]#####
BASE_URL=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd
ISO=$( wget -qO - $BASE_URL/SHA512SUMS | grep netinst | grep -v mac | head -n 1 | awk '{ print $2 }' )

if [ ! -f "$ISO" ]; then
	wget "$BASE_URL/$ISO" -O "$ISO"
fi

#####[ Working directory ]#####

WORKDIR=temp
rm -rf $WORKDIR
mkdir $WORKDIR

#####[ Building name of new iso ]#####

ISO_SRC=$( find . -name '*.iso' | grep -v preseed | head -n 1 )
ISO_PREFIX=$( echo "$ISO_SRC" | sed 's/.iso//' )
ISO_TARGET="$ISO_PREFIX-preseed.iso"

#####[ Extracting files from iso ]#####
xorriso -osirrox on -dev "$ISO_SRC" \
	-extract '/isolinux/isolinux.cfg' $WORKDIR/isolinux.cfg \
	-extract '/md5sum.txt' $WORKDIR/md5sum.txt \
	-extract '/install.amd/gtk/initrd.gz' $WORKDIR/initrd.gz

#####[ Adding preseed to initrd ]#####
cp preseed.cfg $WORKDIR/
(
	cd $WORKDIR &&
	gunzip initrd.gz
	chmod +w initrd
	echo "preseed.cfg" | cpio -o -H newc -A -F initrd
	gzip initrd

	#####[ Changing default boot menu timeout ]#####
	sed -i 's/timeout 0/timeout 1/' isolinux.cfg

	#####[ Fixing MD5 ]#####
	fixSum initrd.gz ./install.amd/gtk/initrd.gz
	fixSum isolinux.cfg ./isolinux/isolinux.cfg
)

#####[ Writing new iso ]#####
rm "$ISO_TARGET"
xorriso -indev "$ISO_SRC" \
	-map $WORKDIR/isolinux.cfg '/isolinux/isolinux.cfg' \
	-map $WORKDIR/md5sum.txt '/md5sum.txt' \
	-map $WORKDIR/initrd.gz '/install.amd/gtk/initrd.gz' \
	-boot_image isolinux dir=/isolinux \
	-outdev "$ISO_TARGET"

rm -rf $WORKDIR
