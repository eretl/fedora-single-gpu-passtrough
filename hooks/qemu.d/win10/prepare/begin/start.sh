#!/bin/bash
# Helpful to read output when debugging
set -x
 
# Load the config file with our environmental variables
source "/etc/libvirt/hooks/kvm.conf"
 
# Stop your display manager. If youre on kde it ll be sddm.service. Gnome users should use killall gdm-x-session instead
systemctl stop display-manager.service
pulse_pid=$(pgrep -u youruser pulseaudio)
pipewire_pid=$(pgrep -u youruser pipewire)
kill $pulse_pid
kill $pipewire_pid
 
# Unbind VTconsoles
echo 0 > /sys/class/vtconsole/vtcon0/bind

# Unbind EFI-Framebuffer
echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
 
# Avoid a race condition by waiting a couple of seconds. This can be calibrated to be shorter or longer if required for your system
sleep 10
 
# Unload all Nvidia drivers
modprobe -r nvidia_drm
modprobe -r nvidia_modeset
modprobe -r drm_kms_helper
modprobe -r nvidia
modprobe -r i2c_nvidia_gpu
modprobe -r drm
modprobe -r nvidia_uvm

 
# Unbind the GPU from display driver
virsh nodedev-detach $VIRSH_GPU_VIDEO
virsh nodedev-detach $VIRSH_GPU_AUDIO
 
# Load VFIO kernel module
modprobe vfio
modprobe vfio_pci
modprobe vfio_iommu_type1
