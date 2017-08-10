TARGETS = console-setup mountkernfs.sh alsa-utils resolvconf screen-cleanup pppd-dns hostname.sh x11-common udev mountdevsubfs.sh procps udev-finish hwclock.sh lvm2 networking urandom checkroot.sh checkroot-bootclean.sh bootmisc.sh mountall-bootclean.sh mountall.sh checkfs.sh mountnfs-bootclean.sh mountnfs.sh kmod
INTERACTIVE = console-setup udev checkroot.sh checkfs.sh
udev: mountkernfs.sh
mountdevsubfs.sh: mountkernfs.sh udev
procps: mountkernfs.sh udev
udev-finish: udev
hwclock.sh: mountdevsubfs.sh
lvm2: mountdevsubfs.sh udev
networking: mountkernfs.sh urandom resolvconf procps
urandom: hwclock.sh
checkroot.sh: hwclock.sh mountdevsubfs.sh hostname.sh
checkroot-bootclean.sh: checkroot.sh
bootmisc.sh: checkroot-bootclean.sh mountall-bootclean.sh udev mountnfs-bootclean.sh
mountall-bootclean.sh: mountall.sh
mountall.sh: checkfs.sh checkroot-bootclean.sh lvm2
checkfs.sh: checkroot.sh lvm2
mountnfs-bootclean.sh: mountnfs.sh
mountnfs.sh: networking
kmod: checkroot.sh
