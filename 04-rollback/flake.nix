{
  description = "Functional programming demo: rollback";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        mkApp = version: pkgs.writeShellScriptBin "fp-rollback" ''
          exec ${pkgs.python3}/bin/python ${./server.py} --app-version ${version} "$@"
        '';
      in {
        default = mkApp "v1";
        v2 = mkApp "v2";
      };
  };
}
