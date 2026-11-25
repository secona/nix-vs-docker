{
  description = "Functional programming demo: isolation";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        mkServer = python: pkgs.writeShellScriptBin "fp-isolation" ''
          exec ${python}/bin/python ${./server.py} "$@"
        '';
      in {
        default = mkServer pkgs.python312;
        alternate = mkServer pkgs.python313;
        sandboxProbe = pkgs.runCommand "fp-isolation-sandbox-probe" {} ''
          for marker in /tmp/fp-isolation.????????; do
            if test -f "$marker"; then
              echo "Builder can see a host marker" >&2
              exit 1
            fi
          done
          echo "No demo marker visible to builder" > "$out"
        '';
      };
  };
}
