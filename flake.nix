{
  description = "foot — fast, lightweight Wayland terminal emulator (local dev build)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      # Build foot from this checkout, reusing nixpkgs' foot package for all
      # of the dependency/build wiring (wayland-protocols >= 1.41, fcft, pixman,
      # etc.) so we only ever override the source.
      footFor = system:
        (pkgsFor system).foot.overrideAttrs (old: {
          pname = "foot";
          version = "1.27.0-dev";
          src = self;
        });
    in
    {
      packages = forAllSystems (system: rec {
        foot = footFor system;
        default = foot;
      });

      # `nix develop` drops you into a shell with meson/ninja/pkg-config/
      # wayland-scanner/scdoc and every build/runtime dependency on PATH, so
      # you can run `meson setup build && ninja -C build` against the working
      # tree directly.
      devShells = forAllSystems (system:
        let pkgs = pkgsFor system; in {
          default = pkgs.mkShell {
            inputsFrom = [ (footFor system) ];
            packages = with pkgs; [ meson ninja pkg-config wayland-scanner scdoc ];
          };
        });
    };
}
