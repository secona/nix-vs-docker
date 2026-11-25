{
  description = "Functional programming demo: deployment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        app = pkgs.writeShellScriptBin "fp-deployment" ''
          exec ${pkgs.python3}/bin/python ${./server.py} "$@"
        '';
      in {
        default = app;
      };
  };
}
