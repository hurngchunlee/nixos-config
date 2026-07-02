{ pkgs, lib, ... }:

{

  services.displayManager.gdm = {
    enable = true;
  };

  services.desktopManager.gnome.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = lib.mkAfter [
    pkgs.xdg-desktop-portal-gnome
  ];
}
