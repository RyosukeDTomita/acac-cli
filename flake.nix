{
  description = "Haskell dev environment AtCoder";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # GitHub Actions メンテ用ツール(ghalint 等)は新しい nixpkgs から取る。
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        unstablePkgs = import nixpkgs-unstable { inherit system; };
        hpkgs = pkgs.haskell.packages.ghc9122;
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
        # cabal パッケージのソースは Haskell 関連ファイルだけに限定する。
        # README/npm/docs/flake 等を変えてもビルドのハッシュが変わらず、
        # cachix のキャッシュ(静的ビルド)が効き続けるようにするため。
        acacSrc = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./acac.cabal
            ./src
            ./app
            ./test
          ];
        };
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        # `nix build` で acac の実行バイナリを生成する(開発・動作確認用、nix store に動的リンク)。
        packages.default = hpkgs.callCabal2nix "acac" acacSrc { };

        # `nix build .#static` で配布用の musl 静的バイナリを生成する(GitHub Releases へ載せる)。
        packages.static = pkgs.haskell.lib.justStaticExecutables (
          pkgs.pkgsStatic.haskell.packages.ghc9122.callCabal2nix "acac" acacSrc { }
        );

        devShells.default = pkgs.mkShell {
          packages = [
            treefmtEval.config.build.wrapper
            pkgs.zsh
            (hpkgs.ghcWithPackages (ps: [
              ps.containers
              ps.bytestring
              ps.vector
              ps.aeson
              ps.http-conduit
              ps.hspec
            ]))
            hpkgs.haskell-language-server
            pkgs.cabal-install
            # GitHub Actions のメンテ用ツール(配布物には含まれない)。
            unstablePkgs.pinact
            unstablePkgs.ghalint
            pkgs.cachix
            pkgs.nodejs_20
          ];
        };
      }
    );
}
