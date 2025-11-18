#!/bin/bash
set -e

echo "======================================================="
echo "🤖 Building Rust Android .so libraries (SAFE MODE)"
echo "======================================================="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$CRATE_DIR/.." && pwd)"
JNI_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"

LIB_NAME="librust_tokenizer.so"

echo "🟦 Rust crate dir: $CRATE_DIR"
echo "🟦 Flutter root:   $PROJECT_ROOT"
echo "🟦 JNI output:     $JNI_DIR"

# SAFETY CHECK
if [[ "$JNI_DIR" != *"/android/app/src/main/jniLibs" ]]; then
  echo "🚨 ABORT — JNI_DIR is unsafe:"
  echo "     $JNI_DIR"
  exit 1
fi

# Detect NDK
NDK_BASE="$HOME/Library/Android/sdk/ndk"
if [[ ! -d "$NDK_BASE" ]]; then
  echo "🚨 ERROR: No NDK directory found at $NDK_BASE"
  exit 1
fi

NDK_DIR=$(ls -d "$NDK_BASE"/* | sort -V | tail -n 1)
echo "🟢 Using NDK: $NDK_DIR"

TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/darwin-x86_64/bin"
export PATH="$TOOLCHAIN:$PATH"

# Compilers
export CC_aarch64_linux_android="aarch64-linux-android21-clang"
export CC_x86_64_linux_android="x86_64-linux-android21-clang"
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="aarch64-linux-android21-clang"
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="x86_64-linux-android21-clang"

# Rust targets
rustup target add aarch64-linux-android >/dev/null
rustup target add x86_64-linux-android >/dev/null

# Clean JNI libs
rm -rf "$JNI_DIR"
mkdir -p "$JNI_DIR/arm64-v8a"
mkdir -p "$JNI_DIR/x86_64"

echo "🚀 Building ARM64…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target aarch64-linux-android

echo "🚀 Building x86_64…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target x86_64-linux-android

echo "📦 Copying .so outputs…"
cp "$CRATE_DIR/target/aarch64-linux-android/release/$LIB_NAME" "$JNI_DIR/arm64-v8a/"
cp "$CRATE_DIR/target/x86_64-linux-android/release/$LIB_NAME" "$JNI_DIR/x86_64/"

echo "======================================================="
echo "🎉 Android build complete!"
echo "   → $JNI_DIR"
echo "======================================================="
