
{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  hardware.enableRedistributableFirmware = true;
  hardware.bluetooth.enable = true;

  services.fwupd.enable = true;
  services.fstrim.enable = true;

  ## disable NVIDIA discrete GPU
  services.xserver.videoDrivers = [ "modesetting" ];
  hardware.nvidia.modesetting.enable = false;
  hardware.nvidia.powerManagement.enable = false;
  hardware.graphics.enable = true;
}
