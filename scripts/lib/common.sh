#!/usr/bin/env bash

info() {
    echo
    echo "==> $1"
}

success() {
    echo "✓ $1"
}

error() {
    echo "✗ $1" >&2
    exit 1
}

warn() {
    echo "! $1"
}
