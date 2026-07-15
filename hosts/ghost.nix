{
  imports = [
    ../hardware/generated/ghost.nix
    ../hardware/custom/gnome-boxes.nix

    ../modules/boot.nix
    ../modules/common.nix
    ../modules/gnome.nix
    ../modules/sway.nix
    ../modules/users.nix
    ../modules/networking.nix
  ];

  networking.hostName = "vm001";

  system.stateVersion = "26.05";
}
