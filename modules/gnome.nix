{ pkgs, lib, ... }:

{

  services.xserver.enable = true;

  services.xserver.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  services.xserver.desktopManager.gnome.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = lib.mkAfter [
    pkgs.xdg-desktop-portal-gnome
  ];
}
