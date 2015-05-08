#!/bin/sh
# all thanks to:
# https://serverfault.com/questions/6714/how-to-make-windows-7-usb-flash-install-media-from-linux#answer-167060

set -e

TARGET_DEV=$1
ISO_FILE=$2
REQ_TOOLS="7z lilo mkfs.ntfs dd"

show_usage() {
  echo usage: `basename $0` DEVICE ISO
  exit 1

}

# check for required programs
for bin in $REQ_TOOLS; do
  # which will fail and cause an exit due to -e
  if ! which $bin>/dev/null; then
    echo "could not find required binary '$bin'"
    exit 1
  fi;
done;

if [ -z "${TARGET_DEV}" ]; then
  show_usage
fi;

if [ -z "${ISO_FILE}" ]; then
  show_usage
fi;

if [ ! -r "${ISO_FILE}" ]; then
  echo "ISO file is not readable: ${ISO_FILE}"
  exit 1
fi;

if [ ! -b "${TARGET_DEV}" ]; then
  echo "TARGET_DEV is not a block device: ${TARGET_DEV}"
  exit 1
fi;

echo "* erasing mbr"
dd if=/dev/zero of=${TARGET_DEV} bs=512 count=1

# create single active (bootable) primary partition with type 0x07
echo "* creating new partition"
echo 'n\np\n1\n\n\nt\n7\na\n1\nw\n' | fdisk /dev/sdi

# initialize filesystem
echo "* creating NTFS filesystem on ${TARGET_PART}"
TARGET_PART=${TARGET_DEV}1
mkfs.ntfs -f "${TARGET_PART}"

# add mbr using lilo (other methods available, see source)
lilo -M ${TARGET_DEV} mbr

# now mount stuff
MOUNT_POINT=`mktemp -d`

echo "* mounting ${TARGET_PART} on ${MOUNT_POINT}"
mount ${TARGET_PART} ${MOUNT_POINT}
cd ${MOUNT_POINT}

echo "* extracting iso ${ISO_FILE}"
7z x ${ISO_FILE}
sync

echo "* unmounting and removing ${MOUNT_POINT}"
umount ${MOUNT_POINT}
rmdir ${MOUNT_POINT}

echo "done."