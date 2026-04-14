{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    project-banner.url = "github:wallago/project-banner?dir=nix";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      project-banner,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              python313Packages.west
              python313Packages.pyelftools
              python313Packages.setuptools
              python313Packages.protobuf
              cmake
              ninja
              protobuf
            ];
            shellHook = ''
              export ZEPHYR_BASE=$PWD/zephyr
              export CMAKE_PREFIX_PATH=$PWD/zephyr/share/zephyr-package/cmake
              export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
              export GNUARMEMB_TOOLCHAIN_PATH=${pkgs.gcc-arm-embedded}
              ${project-banner.packages.${system}.default}/bin/project-banner \
              --owner "wallago" \
              --logo " 󰖌 " \
              --product "keyboard" \
              --part "chocofi" \
              --code "WL25-KB-CHOCOFI" \
              --tips "west init -l config" \
              --tips "west update" \
              --tips "KB Left: west build -d build/left -b nice_nano@2 -s zmk/app -- -DSHIELD=chocofi_left" \
              --tips "KB Right: west build -d build/right -b nice_nano@2 -s zmk/app -- -DSHIELD=chocofi_right"
            '';
          };
        };
      }
    );
}
