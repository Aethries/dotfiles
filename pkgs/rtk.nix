{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.49.0";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-cngjHf1+anMKSrf4R7GVvPAiicLVdiKw2rdaZBEQDI8=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/rtk-ai/rtk/releases/download/v${version}/rtk-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-yOpLZWCEHnMVfBNP1KMpORTG7eQueG7phc9JH95pG6c=";
    };
  };
in
stdenv.mkDerivation {
  pname = "rtk";
  inherit version;

  src =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported architecture for rtk: ${stdenv.hostPlatform.system}");

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -m755 -D rtk $out/bin/rtk
    runHook postInstall
  '';

  meta = with lib; {
    description = "Rust Token Killer (RTK) - CLI proxy reducing token consumption for AI coding agents";
    homepage = "https://github.com/rtk-ai/rtk";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "rtk";
  };
}
