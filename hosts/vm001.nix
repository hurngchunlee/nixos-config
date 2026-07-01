{
  imports = [
    ../hardware/generated/vm.nix

    ../modules/boot.nix
    ../modules/common.nix
    ../modules/gnome.nix
    ../modules/sway.nix
    ../modules/users.nix
    ../modules/networking.nix
  ];

  networking.hostName = "vm001";

  system.stateVersion = "25.05";
}
