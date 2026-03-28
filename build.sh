#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

NDK_ROOT="${ANDROID_NDK_ROOT:-${NDK_ROOT:-${ANDROID_NDK:-}}}"
if [[ -z "${NDK_ROOT}" ]]; then
  echo "ANDROID_NDK_ROOT/NDK_ROOT/ANDROID_NDK is required" >&2
  exit 1
fi

ABI="${STACKPLZ_PRELOAD_ABI:-arm64-v8a}"
API_LEVEL="${STACKPLZ_PRELOAD_API_LEVEL:-29}"
BUILD_DIR="${UNWINDDAEMON_BUILD_DIR:-$ROOT_DIR/build/android-${ABI}-api${API_LEVEL}}"
JOBS="${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 8)}"

cmake -S "$ROOT_DIR" -B "$BUILD_DIR" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK_ROOT/build/cmake/android.toolchain.cmake" \
  -DANDROID=1 \
  -DANDROID_ABI="$ABI" \
  -DANDROID_NDK="$NDK_ROOT" \
  -DANDROID_PLATFORM="android-${API_LEVEL}" \
  -DCMAKE_BUILD_TYPE=Release \
  -DSTACKPLZ_BUILD_ALL=ON \
  -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY="$BUILD_DIR/lib" \
  -DCMAKE_LIBRARY_OUTPUT_DIRECTORY="$BUILD_DIR/lib" \
  -DCMAKE_RUNTIME_OUTPUT_DIRECTORY="$BUILD_DIR/bin"

cmake --build "$BUILD_DIR" --target stackplz_all -j"$JOBS"

LIB_DIR="$BUILD_DIR/lib"
OUT_ARCHIVE="$LIB_DIR/libstackplz_all.a"
if [[ ! -f "$OUT_ARCHIVE" ]]; then
  echo "missing merged archive: $OUT_ARCHIVE" >&2
  exit 1
fi
echo "built: $OUT_ARCHIVE"
