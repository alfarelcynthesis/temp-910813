{ config, lib }:
let
  inherit (lib) options types;
in
{
  options = {
    systems = options.create {
      type = types.list.of types.string;
      description = ''
        Systems supported by this project.
        This option exists for customisability.
      '';
      default.value = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    };

    pins = options.create {
      type = types.attrs.of types.any;
      default.value = import ./npins;
      writable = false;
      description = ''
        Pins, to reduce the number of imports necessary and relative paths.
      '';
    };
  };
  config.inputs =
    let
      inherit (config) pins;
    in
    {
      # Used in this project and nilla inputs.
      nixpkgs = {
        src = pins.nixpkgs;
        settings = { inherit (config) systems; };
      };
      # Used in flake inputs.
      nixpkgs-flake = {
        src = pins.nixpkgs;
        loader = "flake";
      };
      crane.src = pins.crane;
      # Could also use rust-overlay,
      # but I prefer to avoid overlays where possible.
      fenix = {
        src = pins.fenix;
        settings.inputs.nixpkgs = config.inputs.nixpkgs-flake.result;
      };
    };
}
