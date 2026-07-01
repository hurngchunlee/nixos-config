{ pkgs, lib, ... }:
{
  programs.sway.enable = true;

  xdg.portal.extraPortals = lib.mkAfter [
    pkgs.xdg-desktop-portal-wlr
  ];

  # pipewire
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;     # replaces PulseAudio
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;      # optional but useful
  };

  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    swaybg
    swayidle
    swaylock
    waybar
    wofi
    grim
    slurp
    wl-clipboard
    dunst
  ];
}
