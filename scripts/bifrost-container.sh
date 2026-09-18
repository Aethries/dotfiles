#!/usr/bin/env bash

set -euo pipefail

ACTION="${1:-}"
CONTAINER_NAME="dotfiles-bifrost"
IMAGE="docker.io/maximhq/bifrost:v2.2.0"
PORT="8080"
DATA_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/bifrost"
ENV_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/ai/bifrost.env"

case "$(uname -m)" in
    x86_64) DIGEST="sha256:5857d3a4061b16f47fdeeb060920f6cb0399bed1b320d408b94e41578ad667b0" ;;
    aarch64) DIGEST="sha256:d2c81d1dbfb11e0e0deea4a7bc6eea3b49503f05b76b4d18d7b34dcb9a24369b" ;;
    *) echo "Unsupported Bifrost architecture: $(uname -m)" >&2; exit 1 ;;
esac

case "$ACTION" in
    start)
        mkdir -p "$DATA_DIR"
        docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
        docker_args=(run --detach --name "$CONTAINER_NAME" --pull=missing \
            --publish "127.0.0.1:${PORT}:8080" \
            --volume "$DATA_DIR:/app/data")
        [ -f "$ENV_FILE" ] && docker_args+=(--env-file "$ENV_FILE")
        [ -f "${BIFROST_CONFIG_FILE:-$HOME/.config/bifrost/config.json}" ] && \
            docker_args+=(--volume "${BIFROST_CONFIG_FILE:-$HOME/.config/bifrost/config.json}:/app/data/config.json:ro")
        docker_args+=("${IMAGE}@${DIGEST}")
        docker "${docker_args[@]}" >/dev/null
        ;;
    stop)
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
        ;;
    status)
        docker inspect --format '{{.State.Status}}' "$CONTAINER_NAME"
        ;;
    *) echo "Usage: bifrost-container start|stop|status" >&2; exit 2 ;;
esac
