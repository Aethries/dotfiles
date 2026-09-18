{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:

let
  isAarch64 = stdenv.hostPlatform.system == "aarch64-linux";
in
stdenv.mkDerivation (finalAttrs: {
  pname = "codegraph";
  version = "0.20.1";

  src = fetchurl {
    url =
      if isAarch64 then
        "https://github.com/codegraph-ai/CodeGraph/releases/download/v${finalAttrs.version}/codegraph-server-linux-arm64"
      else
        "https://github.com/codegraph-ai/CodeGraph/releases/download/v${finalAttrs.version}/codegraph-server-linux-x64";
    hash =
      if isAarch64 then
        "sha256-5UnyN495EWgLiP9KhqZueDx5EdZrHW7Al0PXr/9Twc8="
      else
        "sha256-MrJkIvpf/goTCVW39993H3IrLUJ9Z/U/EE2ZB737JKY=";
  };

  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/codegraph-server"
    ln -s codegraph-server "$out/bin/codegraph"
    runHook postInstall
  '';

  meta = {
    description = "Semantic code graph and MCP server";
    homepage = "https://github.com/codegraph-ai/CodeGraph";
    license = lib.licenses.mit;
    mainProgram = "codegraph-server";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
