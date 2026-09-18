{
  lib,
  stdenvNoCC,
  fetchurl,
  gnutar,
}:

let
  isAarch64 = stdenvNoCC.hostPlatform.system == "aarch64-linux";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "rtk";
  version = "0.48.0";

  src = fetchurl {
    url =
      if isAarch64 then
        "https://github.com/rtk-ai/rtk/releases/download/v${finalAttrs.version}/rtk-aarch64-unknown-linux-gnu.tar.gz"
      else
        "https://github.com/rtk-ai/rtk/releases/download/v${finalAttrs.version}/rtk-x86_64-unknown-linux-musl.tar.gz";
    hash =
      if isAarch64 then
        "sha256-XtZUhqlgd71runyH/cnQ5KGRjRlhm+PIc4CIg4mjDHw="
      else
        "sha256-5OZQ+hZ3wN4vaDmmBA17F/MS0y8WPEArda9w6eWvGpE=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ gnutar ];

  installPhase = ''
    runHook preInstall
    install -d "$out/bin"
    tar -xOf "$src" rtk > "$out/bin/rtk"
    chmod 755 "$out/bin/rtk"
    runHook postInstall
  '';

  meta = {
    description = "Rust Token Killer command output compressor";
    homepage = "https://github.com/rtk-ai/rtk";
    license = lib.licenses.mit;
    mainProgram = "rtk";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
