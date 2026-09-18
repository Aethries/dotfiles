{
  lib,
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  nodejs_22,
}:

let
  version = "3.8.50";
  sourceArchive = fetchurl {
    url = "https://github.com/diegosouzapw/OmniRoute/releases/download/v${version}/OmniRoute-v${version}.source.tar.gz";
    hash = "sha256-4eTpx0G4mNf4YXh7a5Qv8MxsyAO4uacqWmyLv4SoC8c=";
  };
in
buildNpmPackage (finalAttrs: {
  pname = "omniroute";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/omniroute/-/omniroute-${version}.tgz";
    hash = "sha256-c4xYrx+q6MV+tkOpOdEZH41+CD2Sle9haH0r/wSHjCk=";
  };
  sourceRoot = "package";

  # The published package contains the built server but intentionally omits its
  # lockfile. Copy the lockfile from the matching signed source release so Nix
  # can build the exact dependency closure without running an installer script.
  postPatch = ''
    tar -xOf ${sourceArchive} OmniRoute-v${version}/package-lock.json > package-lock.json
  '';

  npmDepsHash = "sha256-rwZ4oabYFc3z0sTWF+TJy+N0ltWYraX4Q8V24Xs7+n8=";
  # The published server does not require optional desktop credential/native
  # addons. Do not compile them in the immutable package build.
  npmFlags = [
    "--legacy-peer-deps"
    "--ignore-scripts"
  ];
  nodejs = nodejs_22;
  nativeBuildInputs = [ makeWrapper ];
  dontNpmBuild = true;

  installPhase = ''
    runHook preInstall
    npm prune --omit=dev --ignore-scripts --legacy-peer-deps
    mkdir -p "$out/lib/node_modules/omniroute"
    cp -a . "$out/lib/node_modules/omniroute/"
    makeWrapper ${nodejs_22}/bin/node "$out/bin/omniroute" \
      --add-flags "$out/lib/node_modules/omniroute/bin/omniroute.mjs"
    makeWrapper ${nodejs_22}/bin/node "$out/bin/omniroute-reset-password" \
      --add-flags "$out/lib/node_modules/omniroute/bin/reset-password.mjs"
    runHook postInstall
  '';

  meta = {
    description = "Pinned local OpenAI-compatible AI gateway";
    homepage = "https://github.com/diegosouzapw/OmniRoute";
    license = lib.licenses.mit;
    mainProgram = "omniroute";
    platforms = lib.platforms.linux;
  };
})
