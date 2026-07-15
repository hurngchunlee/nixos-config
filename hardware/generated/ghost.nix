{ modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ ];

  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [ ];

  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "xfs";
  };

  swapDevices = [ ];

  networking.useDHCP = false;
}
