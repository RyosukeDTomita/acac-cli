{
  description = "Haskell dev environment AtCoder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        devShells.default = pkgs.mkShell {
          packages = [
            treefmtEval.config.build.wrapper
            pkgs.zsh
            (pkgs.haskell.packages.ghc9122.ghcWithPackages (ps: [
              ps.containers
              ps.bytestring
              ps.vector
              ps.aeson
              ps.http-conduit
              ps.hspec
            ]))
            pkgs.haskell.packages.ghc9122.haskell-language-server
          ];
        };
      }
    );
}
