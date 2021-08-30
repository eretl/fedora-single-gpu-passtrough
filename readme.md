# Fedora 34 Single GPU Passtrough [Ryzen, NVIDIA]

## Tested on
### Hardware
**CPU:** Ryzen 5 2600X  
**Motherboard:**  AsRock B450M PRO4 [Bios ver. 5.20]  
**RAM:** 4x8GB  
**GPU:** Gainward GTX 1060 3 GB  
**SSD:** Samsung SSD 860 EVO 1TB

### Software
**OS:** Fedora 34  
**Kernel:** 5.13.12-200.fc34.x86_64  
**Desktop Manager:** Gnome 40.4.0 (X11)  

## System preparation
### Bios
* Enable SVM
* Enable IOMMU
* Enable SR-IOV Support
* Enable Above 4G Decoding
* Disable Secure Boot

### System
* Install Fedora 34
* Update to the latest version
* Install nvidia drivers

#### Configure iommu support
* Add to end of `GRUB_CMDLINE_LINUX` of parameter in `/etc/default/grub` iommu support
`iommu=1 amd_iommu=on`
* Update grub `sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg`
* Reboot

#### Install virtualization tools
`sudo dnf install @virtualization`

#### Add yourself to virtualization groups
`usermod -a -G input username`  
`usermod -a -G kvm username`  
`usermod -a -G libvirt username`  

#### Enable and start virtualization services
`systemctl enable libvirtd`  
`systemctl start libvirtd`  
`systemctl enable virtlogd.socket`  
`systemctl start virtlogd.socket`  

#### Autostart and start default virtual network
`virsh net-autostart default`  
`virsh net-start default`  

## Create virtual machine
* Download latest [Windows ISO](https://www.microsoft.com/en-us/software-download/windows10ISO)
* Open virt-manager and create new virtual machine
* Select install from local media (ISO or CDROM)
* Select Windows 10 ISO
* Check if virt-manager detected ISO as Windows 10, if not set it to Windows 10 manually
* Set RAM to atleast 8GB (Keep at minimum around 2GB free for host)
* Set CPUs to your cpu count - 2
* Create disk image (I would recommend atleast >=100GB)
* Check Customize configuration before install
* Network should be 'default': NAT
* Click Finish
  
### Configuration before installation
* In overview change Chipset to *Q35* and firmware to *UEFI x86_64:/usr/share/edk2-ovmf/x64/OVMF_CODE.fd*  
* In CPUs check *Manually set CPU topology*  
    For 2600X use:
	* Change Sockets to 1
	* Cores to 5
    * Threads to 2  
    For other CPUs set it so you have atleast 2 Logical host CPUs not allocated to VM
* In Boot Options enable booting from CDROM

### Install Windows
* Go trough Windows Install after you reach desktop shutdown VM

## Hooks
* Create folder for hooks `sudo mkdir /etc/libvirt/hooks`   
* Download qemu file `sudo wget 'https://raw.githubusercontent.com/PassthroughPOST/VFIO-Tools/master/libvirt_hooks/qemu' -O /etc/libvirt/hooks/qemu`  
* Allow execution of qemu file `sudo chmod +x /etc/libvirt/hooks/qemu`  
* Create folder structure like below (Copy start.sh, revert.sh and kvm.conf from this repository)  
`tree /etc/libvirt/hooks/`  
```
├── kvm.conf
├── qemu
└── qemu.d
    └── win10
        ├── prepare
        │   └── begin
        │       └── start.sh
        └── release
            └── end
                └── revert.sh
```  

### Edit kvm.conf file
* Change value of VIRSH_GPU_VIDEO and VIRSH_GPU_AUDIO to your Nvidia GPU address. Keep same formatting as in kvm.conf in this repository
	* To get list of IOMMU groups and addresses  
```
for g in `find /sys/kernel/iommu_groups/* -maxdepth 0 -type d | sort -V`; do     echo "IOMMU Group ${g##*/}:";     for d in $g/devices/*; do         echo -e "\t$(lspci -nns ${d##*/})";     done; done;
```
 * If you have anything else related to your GPU in the same IOMMU Group create new variable in `kvm.conf` with its address and add it to `start.sh` and `revert.sh`

## Patch your GPU rom
* Follow instructions in [NVIDIA vBIOS VFIO Patcher repository](https://github.com/Matoking/NVIDIA-vBIOS-VFIO-Patcher)
* Create vgabios folder in `/usr/share`
* Copy patched file to `/usr/share/vgabios`
* chmod 666 the file  

## Add GPU to VM and start
* Edit VM configuration
	* Add Hardware
        Add all Nvidia related things to VM (Should be same as in `kvm.conf`)
		* Host PCI Device
* Enable XML editing in `Edit -> Preferences -> General -> Enable XML editing` in main virt-manager window
* Go trough all PCI devices related to Nvidia in VM settings, change to XML edit
	* Add between `</source>` and `<address .../>` this line `<rom file="/usr/share/vgabios/Patched_file_Name"/>`
* Remove anything related to spice and Video
* Add Host USB Device for keyboard, mouse and optionally external USB sound card
* Now is good time to setup SSH connection to the host machine. It's not required, but it can help you troubleshoot any problems. (Your screen can get stuck on black screen at that point you could still remote in the host and do troubleshooting or reboot it)
* Start the VM
	* Screen will show UEFI logo or go black for around 30s, after that it should boot to Windows
	* Install Nvidia drivers
    * Install [VirtIO drivers](https://github.com/virtio-win/virtio-win-pkg-scripts/blob/master/README.md)




