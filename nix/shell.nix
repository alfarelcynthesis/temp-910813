{ config }:
{
  config.shells.default = {
    inherit (config) systems;
    shell =
      {
        stdenvNoCC,
        pkgs,
        npins,
        mprocs,
        bacon,
        cargo-edit,
        cargo-deny,
        cargo-info,
        cargo-shear,
        cargo-seek,
        writeShellScriptBin,
      }:
      ((config.inputs.crane.result.mkLib pkgs).overrideToolchain (
        _: config.inputs.fenix.result.packages.${stdenvNoCC.hostPlatform.system}.complete.toolchain
      )).devShell
        {
          packages = [
            npins
            config.packages.treefmt.result.${stdenvNoCC.hostPlatform.system}

            mprocs # command watcher
            bacon # code watcher
            cargo-edit # cargo edit
            cargo-deny # cargo deny check
            cargo-info # search for crates and features
            cargo-shear # trim unused dependencies
            cargo-seek # instead of opening a web browser, search for crates using a cli

            (writeShellScriptBin "db-connect" ''
              pushd "$(git rev-parse --show-toplevel)/nix" >/dev/null
              sudo psql --username postgres 3005_a3
              popd >/dev/null
            '')

            (writeShellScriptBin "watch-src" ''mprocs "bacon clippy-all --offline --all-features" "bacon test --offline --all-features"'')
            (writeShellScriptBin "update" ''
              pushd "$(git rev-parse --show-toplevel)/nix" >/dev/null
              npins upgrade
              npins update --max-concurrent-downloads 10
              popd >/dev/null

              pushd "$(git rev-parse --show-toplevel)/" >/dev/null
              cargo update --verbose
              cargo upgrade -vv # from cargo edit

              git commit nix/npins Cargo.lock -m "{nix/npins, Cargo.lock}: update dependencies"
              popd >/dev/null

              tests

              direnv reload
            '')
            (writeShellScriptBin "clean-dependencies" ''
              pushd "$(git rev-parse --show-toplevel)/" >/dev/null
              cargo shear --fix

              git commit Cargo.lock **Cargo.toml -m "{Cargo.lock, **Cargo.toml}: remove unused dependencies"
              popd >/dev/null
            '')
            (writeShellScriptBin "updates" ''
              pushd "$(git rev-parse --show-toplevel)/nix" >/dev/null
              npins update --max-concurrent-downloads 10 --dry-run
              popd >/dev/null

              pushd "$(git rev-parse --show-toplevel)/" >/dev/null
              cargo update --dry-run --verbose
              cargo upgrade --dry-run -vv
              popd >/dev/null
            '')
            (writeShellScriptBin "tests" ''
              # use the workspace setup, if this is a workspace
              pushd "$(git rev-parse --show-toplevel)/" >/dev/null
              # order of importance
              cargo deny check
              cargo check
              cargo test
              cargo doc
              cargo clippy --all-targets -- --deny warnings
              popd >/dev/null
            '')
          ];
        };
  };
}
