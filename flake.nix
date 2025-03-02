{
  description = ":)";

  outputs = inputs@{self, nixpkgs, nixpkgs-unstable, home-manager, flake-utils, ...}: 
    let
      lib' = import ./lib {inherit self; lib = nixpkgs.lib;};
      lib = nixpkgs.lib.extend (
        final: prev: self.lib // home-manager.lib
      );
      overlays = (system: import ./pkgs/overlays {
        inherit inputs lib self;
      });
      mkPkgs = (system: pkgs: overlays: import inputs.nixpkgs {
        inherit system overlays;
        config = {
          allowUnfree = true;
          allowBroken = true;
          permittedInsecurePackages = [
          ];
        };
      });
      pkgs' = (system: mkPkgs system inputs.nixpkgs (
        (self.overlays.${system}.default) ++ [
          (final: prev: {
            unstable = mkPkgs system inputs.nixpkgs-unstable (self.overlays.${system}.default);
          })
        ]
      ));
    in
    {
    nixosConfigurations = let nixosSystem = {system ? "x86_64-linux", name}: (
        inputs.nixpkgs.lib.nixosSystem rec {
          inherit system;
          pkgs = pkgs' system;
          inherit lib;
          modules = [
            ./home
            ./hosts/${name}
            ./modules
            {
            networking.hostName = lib.mkDefault name;
            }
          ];
          specialArgs = {inherit inputs self;};
          }
        ); in {
      aakropotkin = nixosSystem { name = "aakropotkin"; };
    };

    lib = lib';

    } // 
    flake-utils.lib.eachDefaultSystem (system: 
      let 
        pkgs = pkgs' system;
      in {
      overlays.default = overlays system;
      
      packages = let
        package = name: {${name} = import ./pkgs/derivations/${name} {inherit pkgs; lib = self.lib;};};
        in lib.attrListMerge (builtins.map package (lib.getSubDirNames ./pkgs/derivations));
    });  

  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

    flake-utils={
      url = "github:numtide/flake-utils";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}