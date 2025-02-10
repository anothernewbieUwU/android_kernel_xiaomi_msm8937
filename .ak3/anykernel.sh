# AnyKernel3 Ramdisk Mod Script
# osm0sis @ xda-developers

## AnyKernel setup
# begin properties
properties() { '
kernel.string=KeqingWangy Mi8937 by @Tuk4ngB4ks0
do.devicecheck=1
do.modules=0
do.systemless=1
do.cleanup=1
do.cleanuponabort=0
device.name1=mi8937
device.name2=land
device.name3=landtoni
device.name4=riva
device.name5=rolex
device.name6=rova
device.name7=santoni
device.name8=ugg
device.name9=ugglite
device.name10=ulysse
device.name11=prada
supported.versions=8.1.0-13.0
supported.patchlevels=
'; } # end properties

PARTITION=REPLACE_PARTITION

# shell variables
block=/dev/block/bootdevice/by-name/$PARTITION;
is_slot_device=0;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;


## AnyKernel methods (DO NOT CHANGE)
# import patching functions/variables - see for reference
. tools/ak3-core.sh;

# Backup the partition
if dd if=${block} of=/sdcard/previous-${PARTITION}.img; then
  ui_print ""
  ui_print "Your previous ${PARTITION} image has been saved to: /sdcard/previous-${PARTITION}.img"
  ui_print ""
fi

## AnyKernel file attributes
# set permissions/ownership for included ramdisk files
set_perm_recursive 0 0 755 644 $ramdisk/*;
set_perm_recursive 0 0 750 750 $ramdisk/init* $ramdisk/sbin;

# If lk2nd is installed, Read boot from 1MB offset
if [ "$(dd if=${block} skip=64 bs=1 count=5 2>/dev/null)" == "lk2nd" ]; then
  ui_print "Detected lk2nd installation! Skipping the first 1MB."
  customdd="bs=1M skip=1"
  lk2nd=1
fi

## AnyKernel boot install
dump_boot;

# begin ramdisk changes

# init.rc
backup_file init.rc;
replace_string init.rc "cpuctl cpu,timer_slack" "mount cgroup none /dev/cpuctl cpu" "mount cgroup none /dev/cpuctl cpu,timer_slack";

# init.tuna.rc
backup_file init.tuna.rc;
insert_line init.tuna.rc "nodiratime barrier=0" after "mount_all /fstab.tuna" "\tmount ext4 /dev/block/platform/omap/omap_hsmmc.0/by-name/userdata /data remount nosuid nodev noatime nodiratime barrier=0";
append_file init.tuna.rc "bootscript" init.tuna;

# fstab.tuna
backup_file fstab.tuna;
patch_fstab fstab.tuna /system ext4 options "noatime,barrier=1" "noatime,nodiratime,barrier=0";
patch_fstab fstab.tuna /cache ext4 options "barrier=1" "barrier=0,nomblk_io_submit";
patch_fstab fstab.tuna /data ext4 options "data=ordered" "nomblk_io_submit,data=writeback";
append_file fstab.tuna "usbdisk" fstab;

# end ramdisk changes

# Disable PRLMK kill_heaviest_gid on tiare
if ! [ -z "$(cat /proc/cmdline|grep S88508)" ]; then
	patch_cmdline prlmk.kill_heaviest_gid prlmk.kill_heaviest_gid=0
fi

# If lk2nd is installed, Write boot to 1MB offset
if [ "$lk2nd" == "1" ]; then
  customdd="bs=1M seek=1"
  toybox blkdiscard -o 1048576 $block
else
  toybox blkdiscard $block
fi

write_boot;
## end boot install


# shell variables
#block=vendor_boot;
#is_slot_device=1;
#ramdisk_compression=auto;
#patch_vbmeta_flag=auto;

# reset for vendor_boot patching
#reset_ak;


## AnyKernel vendor_boot install
#split_boot; # skip unpack/repack ramdisk since we don't need vendor_ramdisk access

#flash_boot;
## end vendor_boot install

