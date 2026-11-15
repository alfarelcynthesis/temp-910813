let
  config = import ./nilla.nix;
  inherit (config.lib) attrs;
  inherit (config) systems;
in
{
  outputs = _inputs: {
    packages = attrs.generate systems (
      system: builtins.mapAttrs (_name: package: package.result.${system}) config.packages
    );

    devShells = attrs.generate systems (
      system: builtins.mapAttrs (_name: shell: shell.result.${system}) config.shells
    );
  };
}
