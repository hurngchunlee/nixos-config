{
  imports = [
    ../hardware/generated/precision-5560.nix
    ../hardware/custom/precision-5560-no-nvidia-gpu.nix

    ../modules/boot.nix
    ../modules/common.nix
    ../modules/gnome.nix
    ../modules/sway.nix
    ../modules/users.nix
    ../modules/networking.nix
    ../modules/power.nix
    ../modules/thermal.nix
  ];

  networking.hostName = "dccnlpt001";

  system.stateVersion = "26.05";
}
