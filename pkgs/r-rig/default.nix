# rig, the R installation manager (https://github.com/r-lib/rig), from the
# official prebuilt release. nixpkgs has no package for it; its `rig` is an
# unrelated random identity generator, hence the name `r-rig`.
#
# rig installs and switches R versions at runtime (`rig add release`); nix only
# installs rig itself. In user mode (`rig system user-mode`), R goes into
# ~/.local and needs no admin rights.
#
# To update: bump `version` and copy each asset's "digest" (sha256) from
# https://api.github.com/repos/r-lib/rig/releases/latest.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  version = "0.10.0";

  # Release asset and its sha256 for each platform.
  sources = {
    aarch64-darwin = {
      asset = "rig-macos-arm64-${version}.tar.gz";
      sha256 = "a9cca738585eb132818a6750f9edcfc647ca87af781309d3296827a1a851cc4b";
    };
    x86_64-darwin = {
      asset = "rig-macos-x86_64-${version}.tar.gz";
      sha256 = "6906f42e3fab8161b7187291dc69c48726ac48f91a37d9b49bfbb4f8bf94e47b";
    };
    x86_64-linux = {
      asset = "rig-linux-x86_64-${version}.tar.gz";
      sha256 = "a3ac2dd9c675247c8d5de1c8d650090df9c99e0e28e449e0546e3a54c80107cd";
    };
    aarch64-linux = {
      asset = "rig-linux-aarch64-${version}.tar.gz";
      sha256 = "46cd85e5dcbe3748c0a13e19c67333ccc9c52b07e0642a07c00cb8e7d9e6824c";
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  source = sources.${system} or (throw "r-rig: no prebuilt release for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "r-rig";
  inherit version;

  src = fetchurl {
    url = "https://github.com/r-lib/rig/releases/download/v${version}/${source.asset}";
    inherit (source) sha256;
  };

  # The archive unpacks into an install prefix (bin/rig, share/ completions)
  # with no top-level directory.
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  # Keep the upstream binary unchanged: stripping would break the macOS code
  # signature.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -R bin $out/
    if [ -d share ]; then
      cp -R share $out/
    fi
    runHook postInstall
  '';

  meta = {
    description = "R installation manager";
    homepage = "https://github.com/r-lib/rig";
    license = lib.licenses.mit;
    mainProgram = "rig";
    platforms = builtins.attrNames sources;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
