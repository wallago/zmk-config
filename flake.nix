{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    project-banner.url = "github:wallago/project-banner?dir=nix";

    # Zephyr sdk and toolchain
    zephyr-nix = {
      url = "github:urob/zephyr-nix";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      project-banner,
      zephyr-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        zephyr = zephyr-nix.packages.${system};
      in
      {
        devShells = {
          default = pkgs.mkShell {
            buildInputs =
              with pkgs;
              [
                cmake
                ninja
                dtc
                python313Packages.setuptools
                python313Packages.pyelftools
                python313Packages.protobuf
                protobuf
              ]
              ++ [
                zephyr.sdk
                zephyr.pythonEnv
              ];
            shellHook = ''
              export CMAKE_PREFIX_PATH=$PWD/zephyr/share/zephyr-package/cmake
              export ZEPHYR_TOOLCHAIN_VARIANT=gnuarmemb
              export GNUARMEMB_TOOLCHAIN_PATH=${pkgs.gcc-arm-embedded-13}
              ${project-banner.packages.${system}.default}/bin/project-banner \
                --owner "wallago" \
                --logo " 󰖌 " \
                --product "keyboard" \
                --part "chocofi" \
                --code "WL25-KB-CHOCOFI" 
            '';
          };
        };
      }
    );
}
