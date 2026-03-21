#!/bin/bash
set -euo pipefail

# Build the WASM binary
swift package --disable-sandbox --scratch-path .build/skia-wasm --swift-sdk swift-6.2.4-RELEASE_wasm js --product App -c release

# Create the distribution directory
rm -rf dist
mkdir -p dist

# Copy PackageToJS output and web host files
cp -r .build/skia-wasm/plugins/PackageToJS/outputs/Package dist/package
cp WebHost/index.html dist/
cp WebHost/displayListPlayer.mjs dist/

echo "Build complete! Serve the dist/ directory with a local server:"
echo "  npx serve dist"
echo "  python3 -m http.server -d dist"
