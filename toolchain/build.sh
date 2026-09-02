#!/usr/bin/env bash
# ==============================================================================
# Popcorn Hour (MIPSEL) All-Essentials Suite Build Script
# Targets:
#   - pch-remote      (Rust Web Remote Daemon)
#   - pch-stremio     (Rust Direct-Play Media Server)
#   - busybox         (Modern coreutils: wget, tar, top, ps, nc, etc.)
#   - dropbear        (Modern SSH server & key generator)
#   - curl            (HTTP client)
#   - nano            (Terminal text editor)
#   - python          (MicroPython 3 runtime)
# ==============================================================================

set -e

TOOL="${1:-all}"
OUT_DIR="$(pwd)/dist/bin"
mkdir -p "$OUT_DIR"
BUILD_TEMP="/tmp/pch_build_suite"
mkdir -p "$BUILD_TEMP"

# Auto-detect available cross-compilers
for p in /opt/mips32el--musl--stable* /opt/mipsel-linux-muslsf-cross /opt/cross/mipsel-linux-muslsf-cross; do
    if [ -d "$p/bin" ]; then
        export PATH="$p/bin:$PATH"
    fi
done

if command -v mipsel-linux-gcc >/dev/null 2>&1; then
    export CC=mipsel-linux-gcc
    export STRIP=mipsel-linux-strip
    export CROSS_PREFIX=mipsel-linux-
elif command -v mipsel-linux-muslsf-gcc >/dev/null 2>&1; then
    export CC=mipsel-linux-muslsf-gcc
    export STRIP=mipsel-linux-muslsf-strip
    export CROSS_PREFIX=mipsel-linux-muslsf-
fi

echo -e "\033[1;36m==> Compiler: $($CC --version | head -n 1)\033[0m"
echo -e "\033[1;33m==> Target Tool: ${TOOL}\033[0m"

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
    echo -e "\n\033[1;32m[*] Building Rust pch-remote...\033[0m"
    setup_rust_musl
    cargo +nightly build -p pch-remote --target mipsel-unknown-linux-musl --release
    $STRIP -s target/mipsel-unknown-linux-musl/release/pch-remote
    cp -f target/mipsel-unknown-linux-musl/release/pch-remote "$OUT_DIR/pch_remote"
    echo -e "\033[1;32m[✓] pch_remote ready: $OUT_DIR/pch_remote\033[0m"
}

build_stremio() {
    echo -e "\n\033[1;32m[*] Building Rust pch-stremio...\033[0m"
    setup_rust_musl
    cargo +nightly build -p pch-stremio --target mipsel-unknown-linux-musl --release
    $STRIP -s target/mipsel-unknown-linux-musl/release/pch-stremio
    cp -f target/mipsel-unknown-linux-musl/release/pch-stremio "$OUT_DIR/pch_stremio"
    echo -e "\033[1;32m[✓] pch_stremio ready: $OUT_DIR/pch_stremio\033[0m"
}

build_busybox() {
    echo -e "\n\033[1;32m[*] Building BusyBox...\033[0m"
    cd "$BUILD_TEMP"
    rm -rf busybox-1.36.1
    if [ ! -f busybox-1.36.1.tar.bz2 ]; then
        curl -sSL "https://busybox.net/downloads/busybox-1.36.1.tar.bz2" -o busybox-1.36.1.tar.bz2
    fi
    tar -xjf busybox-1.36.1.tar.bz2
    cd busybox-1.36.1
    make defconfig
    sed -i 's/# CONFIG_STATIC is not set/CONFIG_STATIC=y/' .config
    make -j$(nproc) CROSS_COMPILE="$CROSS_PREFIX" CFLAGS="-Os -static -no-pie" LDFLAGS="-static -no-pie"
    $STRIP -s busybox
    cp -f busybox "$OUT_DIR/busybox"
    cd -
    echo -e "\033[1;32m[✓] busybox ready: $OUT_DIR/busybox\033[0m"
}

build_dropbear() {
    echo -e "\n\033[1;32m[*] Building Dropbear SSH...\033[0m"
    cd "$BUILD_TEMP"
    rm -rf dropbear-2024.85
    if [ ! -f dropbear-2024.85.tar.bz2 ]; then
        curl -sSL "https://matt.ucc.asn.au/dropbear/releases/dropbear-2024.85.tar.bz2" -o dropbear-2024.85.tar.bz2
    fi
    tar -xjf dropbear-2024.85.tar.bz2
    cd dropbear-2024.85
    ./configure --host="${CROSS_PREFIX%-}" --disable-zlib --enable-static CC="$CC" CFLAGS="-Os -static -no-pie" LDFLAGS="-static -no-pie"
    make -j$(nproc) PROGRAMS="dropbear dropbearkey dbclient scp"
    $STRIP -s dropbear dropbearkey
    mkdir -p "$OUT_DIR/../dropbear/sbin" "$OUT_DIR/../dropbear/bin"
    cp -f dropbear "$OUT_DIR/dropbear"
    cp -f dropbearkey "$OUT_DIR/dropbearkey"
    cd -
    echo -e "\033[1;32m[✓] dropbear ready: $OUT_DIR/dropbear\033[0m"
}

build_curl() {
    echo -e "\n\033[1;32m[*] Building Curl...\033[0m"
    cd "$BUILD_TEMP"
    rm -rf curl-8.7.1
    if [ ! -f curl-8.7.1.tar.bz2 ]; then
        curl -sSL "https://curl.se/download/curl-8.7.1.tar.bz2" -o curl-8.7.1.tar.bz2
    fi
    tar -xjf curl-8.7.1.tar.bz2
    cd curl-8.7.1
    ./configure --host="${CROSS_PREFIX%-}" --disable-shared --enable-static --disable-ldap --without-ssl --without-libpsl --without-zlib --disable-threaded-resolver --disable-pthreads CC="$CC" CFLAGS="-Os -static -no-pie" LDFLAGS="-static -no-pie"
    make -j$(nproc)
    $STRIP -s src/curl
    cp -f src/curl "$OUT_DIR/curl"
    cd -
    echo -e "\033[1;32m[✓] curl ready: $OUT_DIR/curl\033[0m"
}

build_nano() {
    echo -e "\n\033[1;32m[*] Building Ncurses & Nano editor...\033[0m"
    cd "$BUILD_TEMP"
    if [ ! -f ncurses-6.4.tar.gz ]; then
        curl -sSL "https://invisible-island.net/archives/ncurses/ncurses-6.4.tar.gz" -o ncurses-6.4.tar.gz
    fi
    rm -rf ncurses-6.4
    tar -xzf ncurses-6.4.tar.gz
    cd ncurses-6.4
    ./configure --host="${CROSS_PREFIX%-}" --prefix=/tmp/ncurses_inst --without-shared --without-debug --without-ada --without-tests --without-progs --without-manpages CC="$CC" CFLAGS="-Os -static -no-pie"
    make -j$(nproc)
    make install.includes install.libs
    
    cd "$BUILD_TEMP"
    if [ ! -f nano-7.2.tar.xz ]; then
        curl -sSL "https://www.nano-editor.org/dist/v7/nano-7.2.tar.xz" -o nano-7.2.tar.xz
    fi
    rm -rf nano-7.2
    tar -xf nano-7.2.tar.xz
    cd nano-7.2
    ./configure --host="${CROSS_PREFIX%-}" --enable-tiny --disable-nls --disable-speller --disable-color CC="$CC" CPPFLAGS="-I/tmp/ncurses_inst/include -I/tmp/ncurses_inst/include/ncurses" CFLAGS="-Os -static -no-pie" LDFLAGS="-L/tmp/ncurses_inst/lib -static -no-pie"
    make -C lib -j$(nproc)
    make -C src -j$(nproc)
    $STRIP -s src/nano
    cp -f src/nano "$OUT_DIR/nano"
    cd -
    echo -e "\033[1;32m[✓] nano ready: $OUT_DIR/nano\033[0m"
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
    echo -e "\033[1;32m[✓] micropython ready: $OUT_DIR/python\033[0m"
}

case "$TOOL" in
    remote)
        build_remote
        ;;
    stremio)
        build_stremio
        ;;
    busybox)
        build_busybox
        ;;
    dropbear)
        build_dropbear
        ;;
    curl)
        build_curl
        ;;
    nano)
        build_nano
        ;;
    micropython)
        build_micropython
        ;;
    all)
        build_remote
        build_stremio
        build_busybox
        build_dropbear
        build_curl
        build_nano
        build_micropython
        echo -e "\n\033[1;32m=========================================="
        echo -e "🎉 All Essentials Suite Compiled Successfully!"
        echo -e "==========================================\033[0m"
        ls -lh "$OUT_DIR"
        ;;
    *)
        echo "Unknown tool: $TOOL"
        echo "Available tools: all, remote, stremio, busybox, dropbear, curl, nano, micropython"
        exit 1
        ;;
esac
