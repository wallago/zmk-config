{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
    project-banner.url = "github:wallago/project-banner?dir=nix";

    zephyr = {
      url = "github:zmkfirmware/zephyr";
      flake = false;
    };

    zephyr-nix = {
      url = "github:urob/zephyr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zephyr.follows = "zephyr";
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
        pkgs = import nixpkgs {
          inherit system;
        };
        zephyr = zephyr-nix.packages.${system};
        extraPython = pkgs.python314.withPackages (
          ps: with ps; [
            pyelftools
            protobuf
            setuptools
          ]
        );
      in
      {
        devShells = {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              # Build tools not in the SDK
              cmake
              ninja
              dtc
              protobuf
              keymap-drawer

              # ZMK Studio needs the protoc binary
              protobuf

              # Misc
              just
              git-cliff

              # Zephyr toolchain + Python env (west, pyelftools, etc.)
              zephyr.pythonEnv
              (zephyr.sdk.override { targets = [ "arm-zephyr-eabi" ]; })
            ];
            env = {
              PYTHONPATH = "${zephyr.pythonEnv}/${zephyr.pythonEnv.sitePackages}:${extraPython}/${extraPython.sitePackages}";
            };
            shellHook = ''
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
