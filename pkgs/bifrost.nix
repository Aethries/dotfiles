{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "2.2.1";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://downloads.getmaxim.ai/bifrost/v${version}/linux/amd64/bifrost-http";
      hash = "sha256-StmGeCO6190z0PwbSmGInpwPpgpVm6c1UfYojEoX35I=";
    };
    aarch64-linux = fetchurl {
      url = "https://downloads.getmaxim.ai/bifrost/v${version}/linux/arm64/bifrost-http";
      hash = "sha256-cPqQAEQh+lLAPGi0ufEk8RxAGpdRlqi3h+oLgQOswzg=";
    };
  };
in
stdenv.mkDerivation {
  pname = "bifrost";
  inherit version;

  src =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported architecture for bifrost: ${stdenv.hostPlatform.system}");

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -m755 -D $src $out/bin/bifrost
    ln -s bifrost $out/bin/bifrost-http
    runHook postInstall
  '';

  meta = with lib; {
    description = "Ultra-fast, high-throughput Go-based LLM gateway and multi-provider relay";
    homepage = "https://github.com/maximhq/bifrost";
    license = licenses.asl20;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "bifrost";
  };
}
