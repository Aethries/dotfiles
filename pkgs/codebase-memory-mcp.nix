{
  lib,
  stdenv,
  fetchurl,
}:

let
  version = "0.11.0";
  sources = {
    x86_64-linux = fetchurl {
      url = "https://github.com/DeusData/codebase-memory-mcp/releases/download/v${version}/codebase-memory-mcp-linux-amd64-portable.tar.gz";
      hash = "sha256-H56Ck+srxcBc+ien6PwDPabXKf+tUlzPzao/1gYwZoM=";
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/DeusData/codebase-memory-mcp/releases/download/v${version}/codebase-memory-mcp-linux-arm64-portable.tar.gz";
      hash = "sha256-1i7rIk1e4+ujBwk47GLPEDPxCwQewcSy+2f3rvOQzHs=";
    };
  };
in
stdenv.mkDerivation {
  pname = "codebase-memory-mcp";
  inherit version;

  src =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported architecture for codebase-memory-mcp: ${stdenv.hostPlatform.system}");

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -m755 -D codebase-memory-mcp $out/bin/codebase-memory-mcp
    ln -s codebase-memory-mcp $out/bin/codegraph
    runHook postInstall
  '';

  meta = with lib; {
    description = "Persistent AST codebase memory and relationship index for AI coding agents";
    homepage = "https://github.com/DeusData/codebase-memory-mcp";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "codebase-memory-mcp";
  };
}
