#!/bin/bash
# Helpful to read output when debugging
set -x
 
# Load the config file with our environmental variables
source "/etc/libvirt/hooks/kvm.conf"
 
# Unload all the vfio modules
modprobe -r vfio_pci
modprobe -r vfio_iommu_type1
modprobe -r vfio
 
# Reattach the gpu
virsh nodedev-reattach $VIRSH_GPU_VIDEO
virsh nodedev-reattach $VIRSH_GPU_AUDIO
 
# Rebind VT consoles
echo 1 > /sys/class/vtconsole/vtcon0/bind

nvidia-xconfig --query-gpu-info > /dev/null 2>&1

# Re-Bind EFI-Framebuffer
echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind

#Load nvidia driver
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe drm_kms_helper
modprobe nvidia
modprobe i2c_nvidia_gpu
modprobe drm

#Start you display manager
systemctl start display-manager.service
