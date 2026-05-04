#!/bin/bash
set -e

echo "=== Installing Tuist ==="
curl -Ls https://install.tuist.io | bash
export PATH="$HOME/.local/bin:$PATH"

echo "=== Tuist version ==="
tuist version

echo "=== Installing dependencies ==="
tuist install

echo "=== Generating project ==="
tuist generate --no-open

echo "=== Done ==="
