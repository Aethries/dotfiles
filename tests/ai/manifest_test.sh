#!/usr/bin/env bash

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$REPO_ROOT/resources/ai/manifest.json"

jq empty "$MANIFEST"
jq -e '
  .schemaVersion == 1
  and .gateway == "omniroute"
  and .endpoint == "http://127.0.0.1:20128"
  and .apiEndpoint == "http://127.0.0.1:20128/v1"
  and .tools.omniroute.version == "3.8.50"
  and .tools.rtk.version == "0.48.0"
  and .tools.caveman.version == "2.7.0"
  and .tools.codegraph.version == "0.20.1"
  and .tools.bifrost.version == "2.2.0"
  and .tools.bifrost.enabled == false
  and .tools.omniroute.port == 20128
  and (.tools | to_entries | all(.value.version | test("^[0-9]+\\.[0-9]+\\.[0-9]+$")))
  and ([.tools[].version] | all(. != "latest" and . != "main" and . != "master" and . != "nightly" and . != "next"))
' "$MANIFEST" >/dev/null
jq empty "$REPO_ROOT/resources/ai/schema/manifest.schema.json"
jq empty "$REPO_ROOT/resources/ai/omniroute/config.template.json"
jq empty "$REPO_ROOT/resources/ai/bifrost/config.template.json"
printf 'AI manifest tests passed.\n'
