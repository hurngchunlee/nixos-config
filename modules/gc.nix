{ ... }:
{
  nix = {
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-order-than 14d";   
    };

    settings.auto-optimise-store = true;
  };

  boot.loader.systemd-boot.configurationLimit = 3;
}
