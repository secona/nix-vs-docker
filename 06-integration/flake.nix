{
  description = "Functional programming demo: integration";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        app = pkgs.writeShellScriptBin "fp-integration" ''
          exec ${pkgs.python3}/bin/python ${./server.py} "$@"
        '';
        image = pkgs.dockerTools.buildLayeredImage {
          name = "fp-integration";
          tag = "v1";
          contents = [ app ];
          config = {
            Entrypoint = [ "${app}/bin/fp-integration" ];
            Env = [ "HOST=0.0.0.0" "PORT=8000" ];
          };
        };
      in {
        default = app;
        inherit image;
      };
  };
}
