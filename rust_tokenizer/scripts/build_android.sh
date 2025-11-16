#!/bin/bash
set -e

echo "======================================================="
echo "🤖 Building Rust Android .so libraries (SAFE MODE)"
echo "======================================================="

# -------------------------------------------------------
# Resolve directory locations safely
# -------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CRATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$CRATE_DIR/.." && pwd)"

JNI_DIR="$PROJECT_ROOT/android/app/src/main/jniLibs"

LIB_NAME="libtokenizer_ffi.so"

echo "🟦 Rust crate directory: $CRATE_DIR"
echo "🟦 Flutter project root: $PROJECT_ROOT"
echo "🟦 Target JNI output: $JNI_DIR"

# -------------------------------------------------------
# SAFETY CHECK 1: Ensure jniLibs path is correct
# -------------------------------------------------------
if [[ "$JNI_DIR" != *"/android/app/src/main/jniLibs" ]]; then
  echo "🚨 ABORT: JNI_DIR resolved incorrectly:"
  echo "         $JNI_DIR"
  echo "This script will NOT continue — path unsafe."
  exit 1
fi

# -------------------------------------------------------
# Auto-detect the NDK path
# -------------------------------------------------------
echo "🔍 Detecting Android NDK…"

POSSIBLE_NDKS=(
  "$HOME/Library/Android/sdk/ndk"
  "$HOME/Android/Sdk/ndk"
  "$HOME/Android/sdk/ndk"
)

NDK_DIR=""

for base in "${POSSIBLE_NDKS[@]}"; do
  if [[ -d "$base" ]]; then
    # Pick newest version
    NDK_DIR=$(ls -d "$base"/* | sort -V | tail -n 1)
    break
  fi
done

if [[ ! -d "$NDK_DIR" ]]; then
  echo "🚨 ERROR: Could not detect Android NDK."
  echo "Install via Android Studio → SDK Tools → NDK"
  exit 1
fi

echo "🟩 Detected NDK: $NDK_DIR"

# Toolchain path
TOOLCHAIN="$NDK_DIR/toolchains/llvm/prebuilt/darwin-x86_64/bin"

if [[ ! -d "$TOOLCHAIN" ]]; then
  echo "🚨 ERROR: Toolchain not found at:"
  echo "  $TOOLCHAIN"
  exit 1
fi

# -------------------------------------------------------
# Export toolchain environment
# -------------------------------------------------------
export PATH="$TOOLCHAIN:$PATH"

export CC_aarch64_linux_android="aarch64-linux-android21-clang"
export CC_armv7_linux_androideabi="armv7a-linux-androideabi16-clang"
export CC_x86_64_linux_android="x86_64-linux-android21-clang"
export CC_i686_linux_android="i686-linux-android16-clang"

export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="aarch64-linux-android21-clang"
export CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER="armv7a-linux-androideabi16-clang"
export CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER="x86_64-linux-android21-clang"
export CARGO_TARGET_I686_LINUX_ANDROID_LINKER="i686-linux-android16-clang"

# -------------------------------------------------------
# Ensure Rust targets are installed
# -------------------------------------------------------
echo "📦 Adding Rust Android targets (if missing)…"
rustup target add aarch64-linux-android >/dev/null
rustup target add armv7-linux-androideabi >/dev/null
rustup target add x86_64-linux-android >/dev/null
rustup target add i686-linux-android >/dev/null

# -------------------------------------------------------
# SAFETY CHECK 2: Remove ONLY jniLibs
# -------------------------------------------------------
echo "🗑 Removing old JNI libs safely…"

rm -rf "$JNI_DIR"
mkdir -p "$JNI_DIR/arm64-v8a"
mkdir -p "$JNI_DIR/armeabi-v7a"
mkdir -p "$JNI_DIR/x86_64"
mkdir -p "$JNI_DIR/x86"

# -------------------------------------------------------
# Build each ABI
# -------------------------------------------------------
echo "🚀 Building ARM64 (arm64-v8a)…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target aarch64-linux-android

echo "🚀 Building ARMv7 (armeabi-v7a)…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target armv7-linux-androideabi

echo "🚀 Building x86_64…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target x86_64-linux-android

echo "🚀 Building i686 (x86)…"
cargo build --manifest-path "$CRATE_DIR/Cargo.toml" --release --target i686-linux-android

# -------------------------------------------------------
# Copy outputs
# -------------------------------------------------------
cp "$CRATE_DIR/target/aarch64-linux-android/release/$LIB_NAME" "$JNI_DIR/arm64-v8a/"
cp "$CRATE_DIR/target/armv7-linux-androideabi/release/$LIB_NAME" "$JNI_DIR/armeabi-v7a/"
cp "$CRATE_DIR/target/x86_64-linux-android/release/$LIB_NAME" "$JNI_DIR/x86_64/"
cp "$CRATE_DIR/target/i686-linux-android/release/$LIB_NAME" "$JNI_DIR/x86/"

echo "======================================================="
echo "🎉 SUCCESS! Android libs are ready:"
echo "   → $JNI_DIR"
echo "======================================================="
