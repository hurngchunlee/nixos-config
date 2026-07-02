{
  description = "Hong's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
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

  in {

    nixosConfigurations = {
      dccnlpt001 = mkHost ./hosts/dccnlpt001.nix;
      vm001 = mkHost ./hosts/vm001.nix;
    };
  };

}
