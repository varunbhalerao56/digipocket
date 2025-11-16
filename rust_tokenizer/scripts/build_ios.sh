#!/bin/bash
set -e

# === Resolve paths ===
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$CRATE_DIR/.." && pwd)"
IOS_RUNNER="$PROJECT_ROOT/ios/Runner"
LIB_NAME="tokenizer_ffi"

echo "📱 Building iOS static XCFramework for Rust crate:"
echo "   → $CRATE_DIR"
echo "   Flutter project root:"
echo "   → $PROJECT_ROOT"
echo "------------------------------------------"

# === Ensure Rust targets installed ===
echo "🔧 Installing iOS Rust targets (if needed)…"
rustup target add aarch64-apple-ios >/dev/null
rustup target add aarch64-apple-ios-simulator >/dev/null
rustup target add x86_64-apple-ios >/dev/null

# === Clean old build output ===
echo "🧹 Cleaning previous builds…"
rm -rf "$CRATE_DIR/target"
rm -rf "$PROJECT_ROOT/tokenizer.xcframework"
rm -rf "$IOS_RUNNER/tokenizer.xcframework"

# === Build all required architectures ===
echo "🚀 Building for ARM64 Device…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target aarch64-apple-ios

echo "🚀 Building for ARM64 Simulator…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target aarch64-apple-ios-simulator

echo "🚀 Building for Intel Simulator…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target x86_64-apple-ios

# === Create the XCFramework ===
echo "📦 Creating XCFramework…"

xcodebuild -create-xcframework \
  -library "$CRATE_DIR/target/aarch64-apple-ios/release/lib${LIB_NAME}.a" \
  -library "$CRATE_DIR/target/aarch64-apple-ios-simulator/release/lib${LIB_NAME}.a" \
  -library "$CRATE_DIR/target/x86_64-apple-ios/release/lib${LIB_NAME}.a" \
  -output "$PROJECT_ROOT/tokenizer.xcframework"

# === Move to iOS project ===
echo "📁 Copying XCFramework to ios/Runner…"
mv "$PROJECT_ROOT/tokenizer.xcframework" "$IOS_RUNNER/"

echo "✅ DONE: iOS XCFramework is ready at:"
echo "   ios/Runner/tokenizer.xcframework"
