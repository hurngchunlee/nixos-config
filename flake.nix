{
  description = "Hong's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
  };

  outputs = { self, nixpkgs, ... }:

  let
    system = "x86_64-linux";

    mkHost = hostFile:
      nixpkgs.lib.nixosSystem {
        inherit system;

        modules = [
          hostFile
        ];
      };

  in {

    nixosConfigurations = {
      dccnlpt001 = mkHost ./hosts/dccnlpt001.nix;
    };
  };

}
