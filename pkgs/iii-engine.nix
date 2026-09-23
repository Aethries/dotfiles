{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.11.2";
  src = fetchurl {
    url = "https://github.com/iii-hq/iii/releases/download/iii/v${version}/iii-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-nIPEd4i070vutl3ZvzfpT5k3cM09uHRGTDzhzckjUs0=";
  };
in
stdenvNoCC.mkDerivation {
  pname = "iii-engine";
  inherit version src;

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -d "$out/bin"
    tar -xzf "$src" -C "$out/bin"
    chmod 0755 "$out/bin/iii"
    runHook postInstall
  '';

  meta = with lib; {
    description = "Pinned iii engine runtime used by agentmemory.dev";
    homepage = "https://github.com/iii-hq/iii";
    license = licenses.mit;
    mainProgram = "iii";
    platforms = [ "x86_64-linux" ];
  };
}
