{
  description = "Emacs pre-configured for coq";

  inputs = {
    nixpkgs.url = "nixpkgs/nixpkgs-unstable";

    emacs-flake = {
      url = "github:HamelinDavid/emacs-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    systems = {
      url = "github:nix-systems/default";
      flake = false;
    };
  };

  outputs = {nixpkgs, systems, emacs-flake, self, ...}@inputs: with nixpkgs.lib; let
    eachSystem = genAttrs (import systems); 
  in rec {
    lib.emacsModules.emacs-coq = {
      imports = [
        ./top.nix
      ];
    };
    packages = eachSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in with pkgs; rec {
      emacs-coq = pkgs.callPackage ({modules ? [], ...}: 
        emacs-flake.outputs.packages.${system}.emacs-with-modules.override {
          modules = [ lib.emacsModules.emacs-coq ] ++ modules;
        }
      ) {};
      default = emacs-coq;
    });
  };
}
