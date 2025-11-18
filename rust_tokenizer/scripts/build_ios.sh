#!/bin/bash
set -e

echo "======================================================="
echo "🍎 Building Rust iOS XCFramework (SAFE MODE)"
echo "======================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$CRATE_DIR/ios"
LIB_NAME="librust_tokenizer.a"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

TARGETS=(
  "aarch64-apple-ios"
  "aarch64-apple-ios-sim"
  "x86_64-apple-ios"
)

# Ensure targets installed
rustup target add aarch64-apple-ios >/dev/null
rustup target add aarch64-apple-ios-sim >/dev/null
rustup target add x86_64-apple-ios >/dev/null

echo "🚀 Building for iOS device…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target aarch64-apple-ios

echo "🚀 Building for iOS simulator (ARM64)…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target aarch64-apple-ios-sim

echo "🚀 Building for iOS simulator (x86_64)…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target x86_64-apple-ios

# Create universal simulator static lib
echo "🔨 Creating universal simulator library…"
lipo -create \
  "$CRATE_DIR/target/aarch64-apple-ios-sim/release/$LIB_NAME" \
  "$CRATE_DIR/target/x86_64-apple-ios/release/$LIB_NAME" \
  -output "$OUT_DIR/librust_tokenizer_sim.a"

echo "🏗 Creating XCFramework…"
xcodebuild -create-xcframework \
  -library "$CRATE_DIR/target/aarch64-apple-ios/release/$LIB_NAME" \
  -library "$OUT_DIR/librust_tokenizer_sim.a" \
  -output "$OUT_DIR/TokenizerFFI.xcframework"

echo "======================================================="
echo "🎉 iOS XCFramework ready!"
echo "   → $OUT_DIR/TokenizerFFI.xcframework"
echo "======================================================="
