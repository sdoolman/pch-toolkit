#!/usr/bin/env bash
# ==============================================================================
# Popcorn Hour (MIPSEL) Modular Multi-Tool Build Script
# Usage:
#   ./toolchain/build.sh all               # Build all tools & package release
#   ./toolchain/build.sh remote            # Build only pch-remote (Web Remote Daemon)
#   ./toolchain/build.sh stremio           # Build only pch-stremio (Media Server)
#   ./toolchain/build.sh micropython       # Build only MicroPython 3 runtime
# ==============================================================================

set -e

TOOL="${1:-all}"
OUT_DIR="$(pwd)/dist/bin"
mkdir -p "$OUT_DIR"

# Auto-detect available cross-compilers in PATH or /opt
for p in /opt/mips32el--musl--stable* /opt/mipsel-linux-muslsf-cross /opt/cross/mipsel-linux-muslsf-cross; do
    if [ -d "$p/bin" ]; then
        export PATH="$p/bin:$PATH"
    fi
done

if command -v mipsel-linux-gcc >/dev/null 2>&1; then
    export CC=mipsel-linux-gcc
    export STRIP=mipsel-linux-strip
elif command -v mipsel-linux-muslsf-gcc >/dev/null 2>&1; then
    export CC=mipsel-linux-muslsf-gcc
    export STRIP=mipsel-linux-muslsf-strip
elif command -v mipsel-buildroot-linux-musl-gcc >/dev/null 2>&1; then
    export CC=mipsel-buildroot-linux-musl-gcc
    export STRIP=mipsel-buildroot-linux-musl-strip
else
    echo "[!] Error: No MIPSEL cross-compiler found in PATH"
    exit 1
fi

echo -e "\033[1;36m==> PCH Toolchain Compiler: $($CC --version | head -n 1)\033[0m"
echo -e "\033[1;33m==> Selected Target: ${TOOL}\033[0m"

setup_rust_musl() {
    source "$HOME/.cargo/env" 2>/dev/null || true
    RUSTLIB="$(rustc --print sysroot)/lib/rustlib/mipsel-unknown-linux-musl/lib"
    mkdir -p "$RUSTLIB/self-contained"
    
    GCC_DIR=$(dirname "$($CC -print-libgcc-file-name)")
    MUSL_LIB=$(dirname "$($CC -print-file-name=libc.a)")
    
    cp -f "$MUSL_LIB"/crt*.o "$RUSTLIB/self-contained/" 2>/dev/null || true
    cp -f "$GCC_DIR"/crt*.o "$RUSTLIB/self-contained/" 2>/dev/null || true
    cp -f "$MUSL_LIB"/libc.a "$RUSTLIB/self-contained/" 2>/dev/null || true
    cp -f "$GCC_DIR"/libgcc_eh.a "$RUSTLIB/self-contained/libunwind.a" 2>/dev/null || true
    
    # Configure linker in .cargo/config.toml
    mkdir -p .cargo
    cat << EOF > .cargo/config.toml
[unstable]
build-std = ["std", "panic_abort"]

[target.mipsel-unknown-linux-musl]
linker = "$(which $CC)"
rustflags = [
    "-C", "target-feature=+crt-static",
    "-C", "link-arg=-static",
    "-C", "link-arg=-no-pie"
]
EOF
}

build_remote() {
    echo -e "\n\033[1;32m[*] Building Standalone Rust pch-remote...\033[0m"
    setup_rust_musl
    cargo +nightly build -p pch-remote --target mipsel-unknown-linux-musl --release
    $STRIP -s target/mipsel-unknown-linux-musl/release/pch-remote
    cp -f target/mipsel-unknown-linux-musl/release/pch-remote "$OUT_DIR/pch_remote"
    echo -e "\033[1;32m[✓] pch_remote built successfully: $OUT_DIR/pch_remote\033[0m"
}

build_stremio() {
    echo -e "\n\033[1;32m[*] Building Standalone Rust pch-stremio...\033[0m"
    setup_rust_musl
    cargo +nightly build -p pch-stremio --target mipsel-unknown-linux-musl --release
    $STRIP -s target/mipsel-unknown-linux-musl/release/pch-stremio
    cp -f target/mipsel-unknown-linux-musl/release/pch-stremio "$OUT_DIR/pch_stremio"
    echo -e "\033[1;32m[✓] pch_stremio built successfully: $OUT_DIR/pch_stremio\033[0m"
}

build_micropython() {
    echo -e "\n\033[1;32m[*] Building MicroPython 3 runtime...\033[0m"
    BUILD_DIR="/tmp/mpy_build"
    rm -rf "$BUILD_DIR"
    git clone --depth 1 https://github.com/micropython/micropython.git "$BUILD_DIR"
    make -C "$BUILD_DIR/mpy-cross"
    
    sed -i "s/MICROPY_CONFIG_ROM_LEVEL_MINIMUM/MICROPY_CONFIG_ROM_LEVEL_CORE_FEATURES/" "$BUILD_DIR/ports/unix/variants/minimal/mpconfigvariant.h"
    cat << 'EOF' >> "$BUILD_DIR/ports/unix/variants/minimal/mpconfigvariant.h"
#define MICROPY_PY_BUILTINS_BYTEARRAY (1)
#define MICROPY_PY_SOCKET (1)
#define MICROPY_PY_JSON (1)
#define MICROPY_PY_RE (1)
#define MICROPY_PY_TIME (1)
#define MICROPY_PY_SELECT (1)
#define MICROPY_PY_COLLECTIONS (1)
#define MICROPY_PY_STRUCT (1)
#define MICROPY_PY_MATH (1)
#define MICROPY_PY_IO (1)
#define MICROPY_PY_SYS (1)
#define MICROPY_PY_ERRNO (1)
EOF

    cd "$BUILD_DIR/ports/unix"
    make VARIANT=minimal clean
    make VARIANT=minimal -j$(nproc) CC=$CC STRIP=$STRIP LDFLAGS_EXTRA="-static -no-pie"
    cp -f build-minimal/micropython "$OUT_DIR/python"
    cd -
    echo -e "\033[1;32m[✓] micropython built successfully: $OUT_DIR/python\033[0m"
}

case "$TOOL" in
    remote)
        build_remote
        ;;
    stremio)
        build_stremio
        ;;
    micropython)
        build_micropython
        ;;
    all)
        build_remote
        build_stremio
        build_micropython
        echo -e "\n\033[1;32m[✓] All tools compiled into $OUT_DIR\033[0m"
        ls -lh "$OUT_DIR"
        ;;
    *)
        echo "Unknown tool: $TOOL"
        echo "Available tools: remote, stremio, micropython, all"
        exit 1
        ;;
esac
