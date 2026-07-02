{
  description = "Hong's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, lanzaboote, ... }:

  let
    system = "x86_64-linux";

    mkHost = hostFile:
      nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          lanzaboote.nixosModules.lanzaboote
          hostFile
        ];
      };

    hostFiles = builtins.readDir ./hosts;

    hostNames = builtins.attrNames (
      nixpkgs.lib.filterAttrs
        (name: type: type == "regular" && builtins.match ".*\\.nix" name != null)
        hostFiles
    );

  in {
    nixosConfigurations =
      builtins.listToAttrs (
        map (file: {
          name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
          value = mkHost (./hosts + "/${file}");
        }) hostNames
      );
  };
}
