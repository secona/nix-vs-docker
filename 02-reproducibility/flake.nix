{
  description = "Functional programming demo: repro";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }: {
    packages.x86_64-linux =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        mkMessage = message: pkgs.runCommand "fp-message" {
          nativeBuildInputs = [ pkgs.coreutils ];
          inherit message;
        } ''
          mkdir -p "$out"
          printf '%s\n' "$message" > "$out/message.txt"
        '';
      in {
        default = mkMessage "first";
        changed = mkMessage "second";
      };
  };
}
