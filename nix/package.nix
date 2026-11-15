{ config, lib }:
{
  # single-crate version, see below for workspace version
  config.packages =
    let
      manifest = config.inputs.nixpkgs.result.lib.trivial.importTOML ../Cargo.toml;
      inherit (manifest) package;
    in
    [
      {
        outputName = "default";
        cranelibFunc = "buildPackage";
      }
      {
        outputName = package.name;
        cranelibFunc = "buildPackage";
      }
      {
        outputName = "lint";
        cranelibFunc = "cargoClippy";
        args = _: { cargoClippyExtraArgs = "--all-targets -- --deny warnings"; };
      }
      {
        outputName = "docs";
        cranelibFunc = "cargoDoc";
      }
      {
        outputName = "deny";
        cranelibFunc = "cargoDeny";
      }
    ]
    |> builtins.map (
      {
        outputName,
        cranelibFunc,
        args ? _: { },
      }:
      {
        ${outputName} = {
          inherit (config) systems;
          package =
            {
              lib,
              stdenvNoCC,
              pkgs,
            }@callPackageArgs:
            let
              cranelib = (config.inputs.crane.result.mkLib pkgs).overrideToolchain (
                # Could also get from something like rust-overlay, which would then use the pkgs argument here.
                _: config.inputs.fenix.result.packages.${stdenvNoCC.hostPlatform.system}.complete.toolchain
              );

              common = {
                pname = package.name;
                inherit (package) version;

                cargoLock = ../Cargo.lock;
                src = cranelib.cleanCargoSource ../.;

                strictDeps = true;

                meta = {
                  inherit (package) description;
                  license = lib.licenses.bsd3;
                  mainProgram = package.name;
                  maintainers = [ lib.maintainers.alfarel ];
                  platforms = lib.platforms.all;
                };
              };

              # build deps separately
              cargoArtifacts = cranelib.buildDepsOnly common;
              full = common // {
                inherit cargoArtifacts;
              };
            in
            cranelib.${cranelibFunc} (full // (args callPackageArgs));
        };
      }
    )
    |> builtins.foldl' lib.attrs.merge { };

  # FIXME: add from flwr
}
