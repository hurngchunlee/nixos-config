{ pkgs, ... }:

{

  environment.systemPackages = with pkgs; [
    acpi
  ];
  
  powerManagement.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;
  services.logind = {
    lidSwitch = "suspend";
  };
}
