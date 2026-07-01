{ pkgs, ... }:
{
  users.users.honlee = {

    isNormalUser = true;

    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "input"
    ];

    shell = pkgs.zsh;

    initialPassword = "ChangeMeImmediately";
  };
}
