qemu-system-i386 -m 256 -fda kolibri_test1.img -boot a -vga vmware -net nic,model=rtl8139 -net user -soundhw ac97 -usb -usbdevice tablet -drive file=fat:rw:.
