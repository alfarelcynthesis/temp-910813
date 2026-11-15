{ config }:
{
  config.packages.treefmt = {
    inherit (config) systems;
    package =
      { pkgs }:
      (import (config.pins.treefmt-nix { inherit pkgs; })).mkWrapper pkgs {
        projectRootFile = "nilla.nix";

        # https://github.com/numtide/treefmt-nix/tree/main/programs
        programs = {
          rustfmt.enable = true;

          nixfmt.enable = true;
          deadnix = {
            enable = true;
            # ignore variables with _ at start
            no-underscore = true;
          };
          statix.enable = true;

          rumdl-format.enable = true;
          taplo.enable = true;

          keep-sorted.enable = true;
        };

        # lockfiles
        enableDefaultExcludes = true;
        settings = {
          global.excludes = [ "*.gitignore" ];
          formatter = {
            # generated files
            deadnix.excludes = [ "nix/npins/default.nix" ];
            statix.excludes = [ "nix/npins/default.nix" ];
          };
        };
      };
  };
}
