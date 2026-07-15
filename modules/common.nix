{ pkgs, ... }:

{
  time.timeZone = "Europe/Amsterdam";

  i18n.defaultLocale = "en_US.UTF-8";

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [

    git
    vim
    firefox
    wget
    curl
    htop

    usbutils
    pciutils
    nvme-cli
    sbctl

  ];
}
